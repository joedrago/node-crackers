CREATE TABLE progress (
    user VARCHAR(64),
    dir VARCHAR(700),
    page INT,
    PRIMARY KEY(user, dir)
);
