-- GUTTERUMBLE Supabase schema (Command 04 canonical)
-- Default-deny RLS on every client-exposed table; scope reads/writes to auth.uid().
-- Service-role edge functions bypass RLS for privileged writes (rep, match results).
-- Clients never call award_match_rep with anon — use edge function + user JWT.

-- ── Extensions ────────────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ── Core tables ───────────────────────────────────────────────────────────────

CREATE TABLE players (
	id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
	email VARCHAR NOT NULL UNIQUE,
	display_name VARCHAR,
	created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gangs (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	owner_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
	name VARCHAR NOT NULL,
	description TEXT,
	color_primary VARCHAR,
	color_secondary VARCHAR,
	created_at TIMESTAMPTZ DEFAULT NOW()
);

-- appearance JSONB object shape (CustomizationManager / SaveManager):
--   skin_idx, hair_idx, shirt_idx, pants_idx, shoe_idx, gang_idx, gang_color
CREATE TABLE characters (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	user_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
	gang_id UUID REFERENCES gangs(id) ON DELETE SET NULL,
	name VARCHAR NOT NULL,
	health FLOAT DEFAULT 100,
	level INT DEFAULT 1,
	rep INT DEFAULT 0 CHECK (rep >= 0),
	appearance JSONB DEFAULT '{}'::jsonb,
	created_at TIMESTAMPTZ DEFAULT NOW(),
	CONSTRAINT characters_appearance_is_object CHECK (jsonb_typeof(appearance) = 'object')
);

CREATE TABLE matches (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	server_ip VARCHAR,
	server_port INT,
	gangs JSONB,
	status VARCHAR DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'completed', 'cancelled')),
	created_at TIMESTAMPTZ DEFAULT NOW(),
	ended_at TIMESTAMPTZ
);

CREATE TABLE match_results (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
	user_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
	character_id UUID REFERENCES characters(id) ON DELETE SET NULL,
	placement INT CHECK (placement > 0),
	rep_delta INT DEFAULT 0,
	stats JSONB DEFAULT '{}'::jsonb,
	created_at TIMESTAMPTZ DEFAULT NOW(),
	UNIQUE (match_id, user_id)
);

CREATE TABLE lobbies (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	host_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
	match_id UUID REFERENCES matches(id) ON DELETE SET NULL,
	status VARCHAR DEFAULT 'open' CHECK (status IN ('open', 'starting', 'closed')),
	max_players INT DEFAULT 8 CHECK (max_players BETWEEN 2 AND 16),
	settings JSONB DEFAULT '{}'::jsonb,
	created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE lobby_members (
	lobby_id UUID NOT NULL REFERENCES lobbies(id) ON DELETE CASCADE,
	user_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
	joined_at TIMESTAMPTZ DEFAULT NOW(),
	PRIMARY KEY (lobby_id, user_id)
);

-- Queue rows for matchmaking (not a phantom /matchmaking REST route).
CREATE TABLE matchmaking_queue (
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

CREATE TABLE appearance_items (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	category VARCHAR NOT NULL,
	name VARCHAR NOT NULL,
	model_path VARCHAR,
	icon_path VARCHAR,
	rarity VARCHAR DEFAULT 'common',
	created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE customization_inventory (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	user_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
	item_id UUID NOT NULL REFERENCES appearance_items(id) ON DELETE CASCADE,
	acquired_at TIMESTAMPTZ DEFAULT NOW(),
	source VARCHAR DEFAULT 'default',
	UNIQUE (user_id, item_id)
);

-- Rate limits for award_match_rep (service_role only; no client policies).
CREATE TABLE award_rep_rate_limits (
	user_id UUID PRIMARY KEY REFERENCES players(id) ON DELETE CASCADE,
	window_start TIMESTAMPTZ NOT NULL DEFAULT NOW(),
	request_count INT NOT NULL DEFAULT 0
);

-- ── Indexes ───────────────────────────────────────────────────────────────────

CREATE INDEX idx_characters_user_id ON characters(user_id);
CREATE INDEX idx_match_results_user_id ON match_results(user_id);
CREATE INDEX idx_match_results_match_id ON match_results(match_id);
CREATE INDEX idx_lobbies_host_id ON lobbies(host_id);
CREATE INDEX idx_lobby_members_user_id ON lobby_members(user_id);
CREATE INDEX idx_customization_inventory_user_id ON customization_inventory(user_id);
CREATE INDEX idx_matchmaking_queue_status_queued_at ON matchmaking_queue(status, queued_at);
CREATE INDEX idx_matchmaking_queue_player_id ON matchmaking_queue(player_id);

-- ── Enable RLS (default deny — no policy = no access) ─────────────────────────

ALTER TABLE players ENABLE ROW LEVEL SECURITY;
ALTER TABLE gangs ENABLE ROW LEVEL SECURITY;
ALTER TABLE characters ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE match_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE lobbies ENABLE ROW LEVEL SECURITY;
ALTER TABLE lobby_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE matchmaking_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE appearance_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE customization_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE award_rep_rate_limits ENABLE ROW LEVEL SECURITY;

ALTER TABLE players FORCE ROW LEVEL SECURITY;
ALTER TABLE gangs FORCE ROW LEVEL SECURITY;
ALTER TABLE characters FORCE ROW LEVEL SECURITY;
ALTER TABLE matches FORCE ROW LEVEL SECURITY;
ALTER TABLE match_results FORCE ROW LEVEL SECURITY;
ALTER TABLE lobbies FORCE ROW LEVEL SECURITY;
ALTER TABLE lobby_members FORCE ROW LEVEL SECURITY;
ALTER TABLE matchmaking_queue FORCE ROW LEVEL SECURITY;
ALTER TABLE appearance_items FORCE ROW LEVEL SECURITY;
ALTER TABLE customization_inventory FORCE ROW LEVEL SECURITY;
ALTER TABLE award_rep_rate_limits FORCE ROW LEVEL SECURITY;

-- ── players ───────────────────────────────────────────────────────────────────

CREATE POLICY players_select_own ON players
	FOR SELECT TO authenticated
	USING (id = auth.uid());

CREATE POLICY players_insert_own ON players
	FOR INSERT TO authenticated
	WITH CHECK (id = auth.uid());

CREATE POLICY players_update_own ON players
	FOR UPDATE TO authenticated
	USING (id = auth.uid())
	WITH CHECK (id = auth.uid());

-- ── characters ────────────────────────────────────────────────────────────────

CREATE POLICY characters_select_own ON characters
	FOR SELECT TO authenticated
	USING (user_id = auth.uid());

CREATE POLICY characters_insert_own ON characters
	FOR INSERT TO authenticated
	WITH CHECK (user_id = auth.uid());

CREATE POLICY characters_update_own ON characters
	FOR UPDATE TO authenticated
	USING (user_id = auth.uid())
	WITH CHECK (user_id = auth.uid());

CREATE POLICY characters_delete_own ON characters
	FOR DELETE TO authenticated
	USING (user_id = auth.uid());

-- Rep is server-authoritative: block client-side rep inflation.
CREATE POLICY characters_block_rep_client_update ON characters
	AS RESTRICTIVE
	FOR UPDATE TO authenticated
	USING (true)
	WITH CHECK (
		rep = (SELECT c.rep FROM characters c WHERE c.id = characters.id)
		OR current_setting('request.jwt.claim.role', true) = 'service_role'
	);

-- ── gangs ─────────────────────────────────────────────────────────────────────

CREATE POLICY gangs_select_member ON gangs
	FOR SELECT TO authenticated
	USING (
		owner_id = auth.uid()
		OR EXISTS (
			SELECT 1 FROM characters c
			WHERE c.gang_id = gangs.id AND c.user_id = auth.uid()
		)
	);

CREATE POLICY gangs_insert_owner ON gangs
	FOR INSERT TO authenticated
	WITH CHECK (owner_id = auth.uid());

CREATE POLICY gangs_update_owner ON gangs
	FOR UPDATE TO authenticated
	USING (owner_id = auth.uid())
	WITH CHECK (owner_id = auth.uid());

CREATE POLICY gangs_delete_owner ON gangs
	FOR DELETE TO authenticated
	USING (owner_id = auth.uid());

-- ── matches (read-only for participants; writes via service role) ─────────────

CREATE POLICY matches_select_participant ON matches
	FOR SELECT TO authenticated
	USING (
		EXISTS (
			SELECT 1 FROM match_results mr
			WHERE mr.match_id = matches.id AND mr.user_id = auth.uid()
		)
		OR EXISTS (
			SELECT 1 FROM lobbies l
			JOIN lobby_members lm ON lm.lobby_id = l.id
			WHERE l.match_id = matches.id AND lm.user_id = auth.uid()
		)
		OR EXISTS (
			SELECT 1 FROM lobbies l
			WHERE l.match_id = matches.id AND l.host_id = auth.uid()
		)
	);

-- ── match_results (read own; insert/update only via edge functions) ───────────

CREATE POLICY match_results_select_own ON match_results
	FOR SELECT TO authenticated
	USING (user_id = auth.uid());

-- ── lobbies ───────────────────────────────────────────────────────────────────

CREATE POLICY lobbies_select_member ON lobbies
	FOR SELECT TO authenticated
	USING (
		host_id = auth.uid()
		OR EXISTS (
			SELECT 1 FROM lobby_members lm
			WHERE lm.lobby_id = lobbies.id AND lm.user_id = auth.uid()
		)
	);

CREATE POLICY lobbies_insert_host ON lobbies
	FOR INSERT TO authenticated
	WITH CHECK (host_id = auth.uid());

CREATE POLICY lobbies_update_host ON lobbies
	FOR UPDATE TO authenticated
	USING (host_id = auth.uid())
	WITH CHECK (host_id = auth.uid());

CREATE POLICY lobbies_delete_host ON lobbies
	FOR DELETE TO authenticated
	USING (host_id = auth.uid());

-- ── lobby_members ─────────────────────────────────────────────────────────────

CREATE POLICY lobby_members_select_own ON lobby_members
	FOR SELECT TO authenticated
	USING (
		user_id = auth.uid()
		OR EXISTS (
			SELECT 1 FROM lobbies l
			WHERE l.id = lobby_members.lobby_id AND l.host_id = auth.uid()
		)
	);

CREATE POLICY lobby_members_insert_self ON lobby_members
	FOR INSERT TO authenticated
	WITH CHECK (user_id = auth.uid());

CREATE POLICY lobby_members_delete_self ON lobby_members
	FOR DELETE TO authenticated
	USING (user_id = auth.uid());

-- ── matchmaking_queue ─────────────────────────────────────────────────────────

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

-- ── appearance_items (public catalog read) ────────────────────────────────────

CREATE POLICY appearance_items_select_public ON appearance_items
	FOR SELECT TO authenticated, anon
	USING (true);

-- ── customization_inventory (read own; grants via service role only) ────────────

CREATE POLICY customization_inventory_select_own ON customization_inventory
	FOR SELECT TO authenticated
	USING (user_id = auth.uid());

-- ── Signup trigger: mirror auth.users → players ───────────────────────────────

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
	INSERT INTO public.players (id, email)
	VALUES (NEW.id, NEW.email)
	ON CONFLICT (id) DO NOTHING;
	RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
	AFTER INSERT ON auth.users
	FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ── Single canonical award_match_rep (RepPipeline signature) ──────────────────
-- Edge Deno wrapper POSTs here with service_role after validating user JWT.
-- Idempotent: ON CONFLICT (match_id, user_id) DO NOTHING — no double rep apply.

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

-- RLS stubs: block direct client writes to match_results (service role only).
CREATE POLICY match_results_deny_insert ON match_results
	AS RESTRICTIVE
	FOR INSERT TO authenticated, anon
	WITH CHECK (false);

CREATE POLICY match_results_deny_update ON match_results
	AS RESTRICTIVE
	FOR UPDATE TO authenticated, anon
	USING (false);

CREATE POLICY match_results_deny_delete ON match_results
	AS RESTRICTIVE
	FOR DELETE TO authenticated, anon
	USING (false);
