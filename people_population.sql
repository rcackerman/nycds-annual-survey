-- people_population.sql
-- PDCMS links people to deal with duplicates
-- this query collapses those links into discrete groups

-- For right now, work with clients only
-- Look up clients by alias, because the alias ID is the "master" ID
-- so provides a link across versions of the same person.
DROP TABLE IF EXISTS survey_people;

CREATE TABLE survey_people AS

  WITH potential_clients AS (
    -- a slightly cleaned version of people who are clients on
    -- eligible cases
    SELECT DISTINCT
      cas_aliasid AS person_id,
      cas_clientid,
      nam_dob::DATE AS nam_dob, 
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
    -- For a first pass, get any present language, race,
    -- gender, ethnicity, and citizenship.
    SELECT DISTINCT
      person_id,
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
    GROUP BY person_id
  )

  -- Remove clients who speak a language other than English or Spanish
    SELECT
      person_id,
      dob,
      language,
      race,
      gender,
      ethnicity,
      non_citizen
    FROM collapse_demo_details
    -- check that either 'ENGLISH' OR 'SPANISH' IS in the language array
    WHERE ('ENGLISH' in language OR 'SPANISH' in language)
    AND AGE(current_date, dob) > '18 years'::INTERVAL
;
