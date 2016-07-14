CREATE TABLE ratings (
    user VARCHAR(64),
    dir VARCHAR(700),
    rating INT,
    PRIMARY KEY(user, dir)
);
