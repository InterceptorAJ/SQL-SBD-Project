CREATE OR REPLACE FUNCTION importxml(datafile text) RETURNS boolean AS $$
DECLARE
    myxml XML;
BEGIN
    myxml := pg_read_file(datafile, 0, 100000000);
    INSERT INTO cache (xmltree, type) VALUES(myxml, 'A');
    RETURN TRUE;
END;
$$	LANGUAGE plpgsql;

SELECT importxml('2018-03-01.xml') -- file should be inside "\PostgreSQL\10\data" folder
SELECT importxml('5.xml')

-- dodawanie elementów
CREATE OR REPLACE FUNCTION rateToFullRate(rate XML, date DATE, no TEXT, tableType TEXT) RETURNS XML as $$
DECLARE
    currency TEXT;
    code TEXT;
    mid TEXT;
    xml XML;
BEGIN
    xml = xmlelement(name "Date", date);
    xml = xmlconcat(xmlelement(name "No", no), xml);
    xml = xmlconcat(xmlelement(name "Table", tableType), xml);
    currency = unnest(xpath('//Rate//Currency//text()', rate));
    xml = xmlconcat(xmlelement(name "Currency", currency), xml);
    code = unnest(xpath('//Rate//Code//text()', rate));
    xml = xmlconcat(xmlelement(name "Code", code), xml);
    mid = unnest(xpath('//Rate//Mid//text()', rate));
    xml = xmlconcat(xmlelement(name "Mid", mid), xml);
    RETURN xmlelement(name "Rate", xml);
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION fullRateToRate(rate XML) RETURNS XML as $$
DECLARE
    currency TEXT;
    code TEXT;
    mid TEXT;
    xml XML;
BEGIN
    currency = unnest(xpath('//Rate//Currency//text()', rate));
    xml = xmlconcat(xmlelement(name "Currency", currency), xml);
    code = unnest(xpath('//Rate//Code//text()', rate));
    xml = xmlconcat(xmlelement(name "Code", code), xml);
    mid = unnest(xpath('//Rate//Mid//text()', rate));
    xml = xmlconcat(xmlelement(name "Mid", mid), xml);
    RETURN xmlelement(name "Rate", xml);
END;
$$ LANGUAGE 'plpgsql';

--xml do wielu wierszy
CREATE OR REPLACE FUNCTION importRates() RETURNS void AS $$
DECLARE
    tableCursor CURSOR FOR SELECT *
    	FROM (
    		SELECT unnest(xpath('//ArrayOfExchangeRatesTable//ExchangeRatesTable',xmltree))
    			AS xml_element
    		FROM cache
    ) t;
    ratesCursor REFCURSOR;
    xyz_row RECORD;
    xx XML;
    code VARCHAR;
    No TEXT;
    TableType TEXT;
    date date;
BEGIN
    open tableCursor;
LOOP
    fetch tableCursor into xx;
    exit when NOT FOUND;
    SELECT unnest(xpath('//EffectiveDate/text()', xx)) INTO date;
    SELECT unnest(xpath('//No/text()', xx)) INTO No;
    SELECT unnest(xpath('//Table/text()', xx)) INTO TableType;

    IF date IS NULL or No IS NULL OR TableType IS NULL THEN
	   RAISE EXCEPTION 'Incorrect xml schema %', xx;
    END IF;

    OPEN ratesCursor FOR SELECT * FROM (SELECT unnest(xpath('//Rates//Rate', xx)) AS xml_element) tt;
    LOOP
        fetch ratesCursor into xx;
        exit when NOT FOUND;
	xx := rateToFullRate(xx, date, no, tableType);
	SELECT unnest(xpath('//Code/text()', xx)) INTO code;
	INSERT INTO rates (rate, date, code) VALUES (xx, date, code) ON CONFLICT DO NOTHING;
    END LOOP;
    close ratesCursor;
    END LOOP;
    close tableCursor;
END;
$$ LANGUAGE 'plpgsql';

select importRates()


CREATE OR REPLACE FUNCTION exportRate(dateParam DATE, codeParam VARCHAR) RETURNS boolean AS $$
DECLARE
    xml XML;
BEGIN
    IF EXISTS(SELECT FROM rates WHERE date = dateParam and code = codeParam) THEN
        EXECUTE 'COPY(SELECT rate FROM rates WHERE date = ''' || dateParam || ''' and code = ''' || codeParam || ''') TO ''/var/lib/postgresql/10/main/export.xml''';
        RETURN TRUE;
    END IF;
    RETURN FALSE;

END;
$$ LANGUAGE plpgsql;
SELECT exportRate('2018-12-24', 'USD')


CREATE OR REPLACE FUNCTION exportToTree(codeParam VARCHAR) RETURNS boolean AS $$
DECLARE
    xml XML;
BEGIN
    EXECUTE 'COPY(SELECT * FROM (SELECT xmlelement(name "Rates", xmlagg(rate)) FROM rates WHERE code = ''' || codeParam || ''') t) TO ''/var/lib/postgresql/10/main/exportTree.xml''';
    RETURN TRUE;
END;
$$	LANGUAGE plpgsql;

SELECT exportToTree('USD')

CREATE OR REPLACE FUNCTION exportToOriginal(dateParam DATE) RETURNS boolean AS $$
DECLARE
    xml XML;
    tableType VARCHAR;
    no VARCHAR;
BEGIN
    IF NOT EXISTS(SELECT FROM rates WHERE date = dateParam) THEN
        RETURN FALSE;
    END IF;
    SELECT rate INTO xml FROM rates WHERE date = dateParam LIMIT 1;
    SELECT unnest(xpath('//Rate//Table/text()', xml)) INTO tableType;
    SELECT unnest(xpath('//Rate//No/text()', xml)) INTO no;
    EXECUTE 'COPY(
	SELECT * FROM (
	    SELECT xmlelement(name "ArrayOfExchangeRatesTable",
		xmlelement(name "ExchangeRatesTable",
		    xmlelement(name "Table", ''' || tableType || '''),
		    xmlelement(name "No", ''' || no || '''),
		    xmlelement(name "EffectiveDate", ''' || dateParam || '''),
		    xmlelement(name "Rates", xmlagg(fullRateToRate(rate)))
		)
	    ) FROM rates) as t
	) TO ''/var/lib/postgresql/10/main/org.xml''';
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

SELECT exportToOriginal('2018-12-24')


CREATE OR REPLACE FUNCTION filterRates(dateParam DATE, code TEXT, mid TEXT) RETURNS BOOLEAN AS $$
DECLARE
    xml XML;
    condition VARCHAR;
    query VARCHAR;
BEGIN
    query := 'SELECT * FROM rates';
    condition := '';
    IF dateParam IS NOT NULL THEN
	condition = 'xmlexists(''//Rate//Date[text()="' || dateParam || '"]'' PASSING BY REF rate)';
    END IF;
    IF code IS NOT NULL THEN
	IF condition <> '' THEN
	    condition := condition || ' and ' ;
	END IF;
	condition := condition || 'xmlexists(''//Rate//Code[text()="' || code || '"]'' PASSING BY REF rate)';

    END IF;
    IF mid IS NOT NULL THEN
        IF condition <> '' THEN
	    condition := condition || ' and ' ;
	END IF;
	condition := condition || 'xmlexists(''//Rate//Mid[text()="' || mid || '"]'' PASSING BY REF rate)';
    END IF;
    IF condition <> '' THEN
	query := query || ' WHERE ' || condition;
    END IF;
    RAISE NOTICE '%', query;
    EXECUTE 'COPY (' || query ||')  TO ''/var/lib/postgresql/10/main/res.csv'' WITH (FORMAT CSV, HEADER);';
    RETURN true;
END;
$$ LANGUAGE plpgsql;

SELECT filterRates('2018-12-24', null, null);
