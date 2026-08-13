-- Incremental apply: Command 04 canonical schema reconciliation
-- Safe to run on existing GutterRumble Supabase projects that already applied
-- an earlier backend/supabase_schema.sql revision.

-- ── Appearance: object default + CHECK ────────────────────────────────────────
-- Object shape: skin_idx, hair_idx, shirt_idx, pants_idx, shoe_idx, gang_idx, gang_color

UPDATE characters
SET appearance = '{}'::jsonb
WHERE appearance IS NULL OR jsonb_typeof(appearance) IS DISTINCT FROM 'object';

ALTER TABLE characters
	ALTER COLUMN appearance SET DEFAULT '{}'::jsonb;

ALTER TABLE characters
	DROP CONSTRAINT IF EXISTS characters_appearance_is_object;

ALTER TABLE characters
	ADD CONSTRAINT characters_appearance_is_object
	CHECK (jsonb_typeof(appearance) = 'object');

COMMENT ON COLUMN characters.appearance IS
	'JSONB object: skin_idx, hair_idx, shirt_idx, pants_idx, shoe_idx, gang_idx, gang_color';

-- ── matchmaking_queue ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS matchmaking_queue (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
	mode VARCHAR NOT NULL DEFAULT 'rumble_coop',
	region VARCHAR DEFAULT 'global',
	status VARCHAR NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'matched', 'cancelled', 'expired')),
	party_id UUID NULL,
	session_id UUID NULL,
	queued_at TIMESTAMPTZ DEFAULT NOW(),
	matched_match_id UUID REFERENCES matches(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_matchmaking_queue_status_queued_at
	ON matchmaking_queue(status, queued_at);
CREATE INDEX IF NOT EXISTS idx_matchmaking_queue_player_id
	ON matchmaking_queue(player_id);

ALTER TABLE matchmaking_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE matchmaking_queue FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS matchmaking_queue_select_own ON matchmaking_queue;
DROP POLICY IF EXISTS matchmaking_queue_insert_own ON matchmaking_queue;
DROP POLICY IF EXISTS matchmaking_queue_update_own ON matchmaking_queue;

CREATE POLICY matchmaking_queue_select_own ON matchmaking_queue
	FOR SELECT TO authenticated
	USING (player_id = auth.uid());

CREATE POLICY matchmaking_queue_insert_own ON matchmaking_queue
	FOR INSERT TO authenticated
	WITH CHECK (player_id = auth.uid());

CREATE POLICY matchmaking_queue_update_own ON matchmaking_queue
	FOR UPDATE TO authenticated
	USING (player_id = auth.uid())
	WITH CHECK (player_id = auth.uid());

-- ── award_rep_rate_limits ─────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS award_rep_rate_limits (
	user_id UUID PRIMARY KEY REFERENCES players(id) ON DELETE CASCADE,
	window_start TIMESTAMPTZ NOT NULL DEFAULT NOW(),
	request_count INT NOT NULL DEFAULT 0
);

ALTER TABLE award_rep_rate_limits ENABLE ROW LEVEL SECURITY;
ALTER TABLE award_rep_rate_limits FORCE ROW LEVEL SECURITY;

-- ── Collapse dual award_match_rep definitions → single RepPipeline signature ──

DROP FUNCTION IF EXISTS public.award_match_rep(UUID, UUID, UUID, INT, INT, JSONB);
DROP FUNCTION IF EXISTS public.award_match_rep(UUID, UUID, UUID, BOOLEAN, INT, JSONB);

CREATE OR REPLACE FUNCTION public.award_match_rep(
	p_match_id UUID,
	p_user_id UUID,
	p_character_id UUID,
	p_won BOOLEAN,
	p_rep_delta INT,
	p_summary JSONB DEFAULT '{}'::jsonb
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
	v_result_id UUID;
	v_stats JSONB;
	v_match_status VARCHAR;
	v_rate RECORD;
	v_max_per_window INT := 10;
	v_window_seconds INT := 60;
BEGIN
	IF current_setting('request.jwt.claim.role', true) IS DISTINCT FROM 'service_role' THEN
		RAISE EXCEPTION 'unauthorized: award_match_rep requires service_role';
	END IF;

	IF p_rep_delta < 0 OR p_rep_delta > 500 THEN
		RAISE EXCEPTION 'invalid rep_delta: %', p_rep_delta;
	END IF;

	SELECT status INTO v_match_status FROM matches WHERE id = p_match_id;
	IF v_match_status IS NULL THEN
		RAISE EXCEPTION 'match not found: %', p_match_id;
	END IF;
	IF v_match_status NOT IN ('completed', 'active') THEN
		RAISE EXCEPTION 'match % not awardable (status=%)', p_match_id, v_match_status;
	END IF;

	SELECT * INTO v_rate FROM award_rep_rate_limits WHERE user_id = p_user_id FOR UPDATE;
	IF NOT FOUND THEN
		INSERT INTO award_rep_rate_limits (user_id, window_start, request_count)
		VALUES (p_user_id, NOW(), 1);
	ELSE
		IF v_rate.window_start < NOW() - (v_window_seconds || ' seconds')::interval THEN
			UPDATE award_rep_rate_limits
			SET window_start = NOW(), request_count = 1
			WHERE user_id = p_user_id;
		ELSIF v_rate.request_count >= v_max_per_window THEN
			RAISE EXCEPTION 'rate limit exceeded for user %', p_user_id;
		ELSE
			UPDATE award_rep_rate_limits
			SET request_count = request_count + 1
			WHERE user_id = p_user_id;
		END IF;
	END IF;

	v_stats := COALESCE(p_summary, '{}'::jsonb);
	v_stats := jsonb_set(v_stats, '{won}', to_jsonb(p_won), true);

	INSERT INTO match_results (match_id, user_id, character_id, rep_delta, stats)
	VALUES (p_match_id, p_user_id, p_character_id, p_rep_delta, v_stats)
	ON CONFLICT (match_id, user_id) DO NOTHING
	RETURNING id INTO v_result_id;

	IF v_result_id IS NULL THEN
		SELECT id INTO v_result_id
		FROM match_results
		WHERE match_id = p_match_id AND user_id = p_user_id;
		RETURN v_result_id;
	END IF;

	IF p_character_id IS NOT NULL THEN
		UPDATE characters
		SET rep = rep + p_rep_delta
		WHERE id = p_character_id AND user_id = p_user_id;
	END IF;

	RETURN v_result_id;
END;
$$;

REVOKE ALL ON FUNCTION public.award_match_rep(UUID, UUID, UUID, BOOLEAN, INT, JSONB) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.award_match_rep(UUID, UUID, UUID, BOOLEAN, INT, JSONB) FROM anon;
REVOKE ALL ON FUNCTION public.award_match_rep(UUID, UUID, UUID, BOOLEAN, INT, JSONB) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.award_match_rep(UUID, UUID, UUID, BOOLEAN, INT, JSONB) TO service_role;
