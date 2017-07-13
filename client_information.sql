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

collapse_demo_details AS (
  -- For a first pass, get any present language, race, gender, ethnicity, and citizenship.
  SELECT DISTINCT
    cas_aliasid,
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
),

-- Remove clients who speak a language other than English or Spanish
clients_english_spanish as (
  SELECT
    cas_aliasid,
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
)

-- Get all addresses for a given alias set.
-- Any PDCMS name can have multiple addresses, so we'll create an array of them.
client_addresses AS (
  SELECT DISTINCT
    cas_aliasid,
    nam_nameid,
    COALESCE(cas_open_date::varchar, adr_date) AS adr_date, -- fall back on case open date in case of data entry problems
    adr_type,
    adr_street1,
    adr_street2,
    adr_city,
    adr_state,
    adr_zipcode,
    adr_ph_number,
    adr_more_phones
  FROM 
  JOIN addresses
    ON nam_nameid = adr_nameid
),


select * from clients_english_spanish;
