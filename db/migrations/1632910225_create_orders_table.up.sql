CREATE TABLE IF NOT EXISTS orders (
     id             bigserial PRIMARY KEY NOT NULL,
     productname    text NOT NULL,
     quantity       bigint NOT NULL
);

