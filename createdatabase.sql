
-- Database: NBP

-- DROP DATABASE "NBP";

CREATE DATABASE "NBP"
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Polish_Poland.1250'
    LC_CTYPE = 'Polish_Poland.1250'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

	
CREATE TABLE cache (
	id SERIAL PRIMARY KEY,
	xmltree XML,
	type VARCHAR,
	datefrom DATE,
	dateto DATE
);


CREATE TABLE rates (
	id SERIAL PRIMARY KEY,
	rate XML
	date date 	-- rate ma byc wyciagniety razem z date (effective date)
);


CREATE TABLE currencies (
	id SERIAL PRIMARY KEY, -- ma byc foreign key z tabeli rates
	currency VARCHAR,
	code VARCHAR,
	mid NUMERIC,
	date DATE
)



