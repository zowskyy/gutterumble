-- Supabase Edge Function reference: award_match_rep
-- Deploy as a Deno edge function (service_role) — NOT callable from anon key.
-- See backend/edge_functions/README.md for rate-limit and session validation notes.

-- ── Rate-limit table (run once in SQL editor) ─────────────────────────────────

CREATE TABLE IF NOT EXISTS award_rep_rate_limits (
	user_id UUID PRIMARY KEY REFERENCES players(id) ON DELETE CASCADE,
	window_start TIMESTAMPTZ NOT NULL DEFAULT NOW(),
	request_count INT NOT NULL DEFAULT 0
);

ALTER TABLE award_rep_rate_limits ENABLE ROW LEVEL SECURITY;
-- No client policies — service role only.

-- ── Privileged rep award (SECURITY DEFINER, service_role callers only) ────────

CREATE OR REPLACE FUNCTION public.award_match_rep(
	p_match_id UUID,
	p_user_id UUID,
	p_character_id UUID,
	p_placement INT,
	p_rep_delta INT,
	p_stats JSONB DEFAULT '{}'::jsonb
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
	v_match_status VARCHAR;
	v_rate RECORD;
	v_max_per_window INT := 10;
	v_window_seconds INT := 60;
BEGIN
	-- Session / caller validation: only service_role may invoke.
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

	-- Per-user rate limit: max 10 awards per 60-second window.
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

	-- Upsert match result and apply rep atomically.
	INSERT INTO match_results (match_id, user_id, character_id, placement, rep_delta, stats)
	VALUES (p_match_id, p_user_id, p_character_id, p_placement, p_rep_delta, p_stats)
	ON CONFLICT (match_id, user_id) DO UPDATE
		SET placement = EXCLUDED.placement,
		    rep_delta = EXCLUDED.rep_delta,
		    stats = EXCLUDED.stats;

	UPDATE characters
	SET rep = rep + p_rep_delta
	WHERE id = p_character_id AND user_id = p_user_id;

	RETURN jsonb_build_object(
		'match_id', p_match_id,
		'user_id', p_user_id,
		'rep_delta', p_rep_delta,
		'placement', p_placement
	);
END;
$$;

REVOKE ALL ON FUNCTION public.award_match_rep(UUID, UUID, UUID, INT, INT, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.award_match_rep(UUID, UUID, UUID, INT, INT, JSONB) TO service_role;
