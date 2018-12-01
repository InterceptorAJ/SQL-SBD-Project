CREATE OR REPLACE FUNCTION importxml(
datafile text
)
  RETURNS boolean AS $$
DECLARE
    myxml XML;
BEGIN

myxml := pg_read_file(datafile, 0, 100000000); 
RETURN TRUE;
END;
$$	LANGUAGE plpgsql;

SELECT importxml('2018-03-01.xml') -- file should be inside "\PostgreSQL\10\data" folder
