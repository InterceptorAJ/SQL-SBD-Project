CREATE OR REPLACE FUNCTION importxml(
	datafile text -- := '[dir]\2018-03-01.xml'
)
  RETURNS boolean AS $$
DECLARE
    myxml XML;
BEGIN

myxml := pg_read_file(datafile, 0, 100000000); 
RETURN TRUE;
END;
$$	LANGUAGE plpgsql


SELECT importxml('2018-03-01.xml')
