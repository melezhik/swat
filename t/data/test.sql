PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE users(name string);
INSERT INTO "users" VALUES('alex');
INSERT INTO "users" VALUES('julia');
INSERT INTO "users" VALUES('yan');
INSERT INTO "users" VALUES('andrew');
INSERT INTO "users" VALUES('tim');
COMMIT;

