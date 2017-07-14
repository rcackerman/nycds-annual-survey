-- client_addresses.sql

-- Get first and last name for each client in a person grouping
WITH

client_names AS (
  SELECT
    person_id,
    nam_nameid,
    nam_first_name AS first_name,
    nam_last_name AS last_name,
    nam_nysid AS nysid,
    dob,
    language,
    gender,
    ethnicity,
    citizenship
FROM survey_people
JOIN names
  ON survey_people.person_id = names.nam_alias_link
    
)

-- Get all addresses for a given alias set.
-- This will get us a row for every address a client had when their case started
SELECT DISTINCT
  client_names.*,
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
;
