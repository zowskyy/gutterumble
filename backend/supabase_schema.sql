
CREATE TABLE players (
	id UUID PRIMARY KEY,
	email VARCHAR NOT NULL UNIQUE,
	created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE gangs (
	id UUID PRIMARY KEY,
	owner_id UUID NOT NULL REFERENCES players(id),
	name VARCHAR NOT NULL,
	description TEXT,
	color_primary VARCHAR,
	color_secondary VARCHAR,
	created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE characters (
	id UUID PRIMARY KEY,
	user_id UUID NOT NULL REFERENCES players(id),
	gang_id UUID REFERENCES gangs(id),
	name VARCHAR NOT NULL,
	health FLOAT DEFAULT 100,
	level INT DEFAULT 1,
	rep INT DEFAULT 0,
	appearance JSONB DEFAULT '[]',
	created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE matches (
	id UUID PRIMARY KEY,
	server_ip VARCHAR,
	server_port INT,
	gangs JSONB,
	status VARCHAR DEFAULT 'pending',
	created_at TIMESTAMP DEFAULT NOW(),
	ended_at TIMESTAMP
);

CREATE TABLE appearance_items (
	id UUID PRIMARY KEY,
	category VARCHAR NOT NULL,
	name VARCHAR NOT NULL,
	model_path VARCHAR,
	icon_path VARCHAR,
	rarity VARCHAR DEFAULT 'common',
	created_at TIMESTAMP DEFAULT NOW()
);
