CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255)
);

INSERT INTO users (name) VALUES ('Alice'), ('Bob');