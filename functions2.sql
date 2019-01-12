CREATE FUNCTION ImportXML1(datafile text) RETURNS BOOLEAN AS $$
DECLARE 
myxml XML;
BEGIN
myxml := pg_read_file(datafile,0,1000000000);
INSERT INTO nbpdata (xmltree) VALUES(myxml);
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

SELECT importxml('2018-03-01.xml')

SELECT importxml('5.xml')

---------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION XMLtoDBTable(codeParam VARCHAR) 
RETURNS TABLE (id integer, TableCurrency text, NoOfTableCurrency text, Date text, currency text, code text, mid text)
AS 
$$

BEGIN
RETURN QUERY
SELECT xmltable.*
FROM nbpdata,
XMLTABLE ('/ArrayOfExchangeRatesTable/ExchangeRatesTable/Rates/Rate/Currency' PASSING xml
		 COLUMNS
		 id FOR ORDINALITY,
		 TableCurrency text PATH '../../../Table' NOT NULL,
		 NoOfTableCurrency text PATH '../../../No' NOT NULL,
		 Date text PATH '../../../EffectiveDate' NOT NULL,
		 currency text PATH '../Currency' NOT NULL,
		 code text PATH '../Code' NOT NULL,
		 mid text PATH '../Mid' NOT NULL
		 ) GROUP BY codeParam;
END;
$$ LANGUAGE 'plpgsql';

SELECT XMLtoDBTable()

---------------------------------------------------------------------------------------------------------------------------

SELECT XMLtoDB()

SELECT xmltable.*
FROM nbpdata,
XMLTABLE ('/ArrayOfExchangeRatesTable/ExchangeRatesTable/Rates/Rate/Currency' PASSING xml
		 COLUMNS
		 id FOR ORDINALITY,
		 TableCurrency text PATH '../../../Table' NOT NULL,
		 NoOfTableCurrency text PATH '../../../No' NOT NULL,
		 Date text PATH '../../../EffectiveDate' NOT NULL,
		 currency text PATH '../Currency' NOT NULL,
		 code text PATH '../Code' NOT NULL,
		 mid text PATH '../Mid' NOT NULL
		 );
