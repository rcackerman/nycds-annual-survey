-- collapse_clients.sql
-- PDCMS links people to deal with duplicates
-- this query collapses those links into discrete groups

-- For right now, work with clients only
-- Look up clients by alias, because the alias ID is the "master" ID
-- so provides a link across versions of the same person.
-- Also flag the most recently used version of the person
-- because names don't have an entered-on date
WITH potential_clients AS (
  SELECT DISTINCT
    survey_cases.*,
    nam_nameid,
    nam_last_name,
    nam_first_name,
    nam_dob, 
    nam_nysid,
    CASE
      WHEN (nam_interpreter IS NOT NULL AND nam_interpreter != '')
        THEN nam_interpreter
      ELSE 'ENGLISH'
    END AS spoken_language,
    nam_race,
    nam_gender,
    nam_ethnicity,
    nam_citizenship
  FROM names
  JOIN survey_cases
  ON cas_aliasid = nam_alias_link
),

-- For a first pass, get any present language, race, gender, ethnicity, and citizenship.
collapse_demo_details AS (
  SELECT DISTINCT
    cas_aliasid,
    MAX(nam_dob) AS dob, -- get the most recent birthdate, if the alias group has more than 1
    array_agg(DISTINCT spoken_language) AS language,
    array_agg(DISTINCT nam_race) filter (WHERE nam_race != '') AS race,
    array_agg(DISTINCT nam_gender) filter (WHERE nam_gender != '') AS gender,
    array_agg(DISTINCT nam_ethnicity) AS ethnicity,
    MAX(
      CASE
        WHEN nam_citizenship = 'Y' THEN 0
        WHEN nam_citizenship IS NULL THEN 0
        WHEN (nam_citizenship = 'N' OR nam_citizenship = 'U') THEN 1
      END) AS non_citizen,
    nam_nysid AS nysid
  FROM potential_clients
  GROUP BY cas_aliasid
),

-- Remove clients who speak a language other than English or Spanish
clients_filtered as (
  SELECT
    cas_aliasid,
    dob,
    unnest(language) AS language,
    race,
    gender,
    ethnicity,
    citizenship
  FROM collapse_clients
  -- check that either 'ENGLISH' OR 'SPANISH' IS in the language array
  WHERE language && ARRAY['ENGLISH', 'SPANISH']::CHARACTER VARYING[] -- the character varying[] part tells the operator that it's comparing apples to apples
  -- check that the person is only recorded as speaking one language, because otherwise we won't know what to send them
  AND ARRAY_LENGTH(language, 1) = 1 
  AND AGE(current_date, dob) > '18 years'::INTERVAL
)

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

SELECT
  potential_clients.cas_file_number AS case_id,
  potential_clients.cas_aliasid AS person_id,
  potential_clients.cas_open_date AS case_open_date,
  potential_clients.cas_closed_date AS case_closed_date,
  potential_clients.cas_case_type AS case_type,
  potential_clients.cas_case_detail AS case_detail,
  potential_clients.cas_tc_number AS top_charge_number,
  potential_clients.cas_tc_short AS top_charge_short,
  potential_clients.cas_fc_number AS final_charge_number,
  potential_clients.cas_fc_short AS final_charge_short,
  potential_clients.snt_date AS date_sentenced,
  potential_clients.snt_length AS snt_length,
  potential_clients.snt_condition AS snt_condition,
  clients_filtered.dob,
  clients_filtered.language,
  clients_filtered.race,
  clients_filtered.gender,
  clients_filtered.ethnicity,
  clients_filtered.citizenship,
  adr_date AS address_date,
  adr_type AS address_type,
  adr_street1 AS street1,
  adr_street2 AS street2,
  adr_city AS city,
  adr_state AS state,
  adr_zipcode AS zipcode,
  adr_ph_number AS phone_number,
  adr_more_phones AS more_phones
FROM potential_clients
JOIN clients_filtered
  ON potential_clients.cas_aliasid = clients_filtered.cas_aliasid
JOIN client_addresses
  ON potential_clients.cas_aliasid = client_addresses.cas_aliasid
;
