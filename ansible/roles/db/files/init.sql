CREATE TABLE IF NOT EXISTS players (
    id          SERIAL PRIMARY KEY,
    full_name   VARCHAR(100) NOT NULL,
    email       VARCHAR(100) UNIQUE NOT NULL,
    rating      INT NOT NULL DEFAULT 1000,
    created_at  TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS matches (
    id          SERIAL PRIMARY KEY,
    player1_id  INT NOT NULL REFERENCES players(id),
    player2_id  INT NOT NULL REFERENCES players(id),
    score1      INT NOT NULL,
    score2      INT NOT NULL,
    played_at   TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS table_bookings (
    id          SERIAL PRIMARY KEY,
    player_id   INT NOT NULL REFERENCES players(id),
    starts_at   TIMESTAMP NOT NULL,
    ends_at     TIMESTAMP NOT NULL
);
