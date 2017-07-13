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
    cas_aliasid,
    cas_clientid,
    nam_dob::DATE AS nam_dob, 
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
      END) AS non_citizen
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
    non_citizen
  FROM collapse_demo_details
  -- check that either 'ENGLISH' OR 'SPANISH' IS in the language array
  WHERE language && ARRAY['ENGLISH', 'SPANISH']::CHARACTER VARYING[] -- the character varying[] part tells the operator that it's comparing apples to apples
  -- check that the person is only recorded as speaking one language, because otherwise we won't know what to send them
  AND ARRAY_LENGTH(language, 1) = 1 
  AND AGE(current_date, dob) > '18 years'::INTERVAL
)

SELECT
  potential_clients.cas_aliasid AS person_id,
  clients_filtered.dob,
  clients_filtered.language,
  clients_filtered.race,
  clients_filtered.gender,
  clients_filtered.ethnicity,
  clients_filtered.citizenship
FROM potential_clients
JOIN clients_filtered
  ON potential_clients.cas_aliasid = clients_filtered.cas_aliasid
;
