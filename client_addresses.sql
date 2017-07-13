

-- Get all addresses for a given alias set.
-- This will get us a row for every address a client had when their case started
client_addresses AS (
  SELECT DISTINCT
    cas_aliasid,
    COALESCE(cas_open_date::varchar, adr_date) AS adr_date, -- sometimes addresses don't have dates, so fall back on case open date
    adr_type,
    adr_street1,
    adr_street2,
    adr_city,
    adr_state,
    adr_zipcode,
    adr_ph_number,
    adr_more_phones
  FROM clients_filtered
  JOIN addresses
    ON nam_nameid = adr_nameid
)

