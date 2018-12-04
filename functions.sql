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


-- function that export all rates and dates from xmltree to rates table
CREATE OR REPLACE FUNCTION exportrates() RETURNS void AS $$

BEGIN
INSERT INTO rates 
(rate, edate)
SELECT
	(xpath('//ExchangeRatesTable/Rates/Rate', xml_element))::text::xml,
	unnest(xpath('//ExchangeRatesTable/EffectiveDate/text()', xml_element::xml))::text::date
FROM (
	SELECT unnest(xpath('//ArrayOfExchangeRatesTable',xmltree)) AS xml_element FROM cache
) t;
END;
$$ LANGUAGE 'plpgsql';	

--execution of this function
SELECT exportrates()
                
                
