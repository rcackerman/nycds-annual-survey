-- collapse_clients.sql
-- PDCMS links people to deal with duplicates
-- this query collapses those links into discrete groups

-- For right now, work with clients only
-- Look up clients by alias, because the alias ID is the "master" ID
-- so provides a link across versions of the same person.
-- Also flag the most recently used version of the person
-- because names don't have an entered-on date
WITH potential_clients AS (
  SELECT
    names.*,
    RANK() OVER (PARTITION BY nam_alias_link ORDER BY cas_open_date::DATE, cas_file_number desc)
  FROM names
  JOIN survey_cases
  ON cas_aliasid = nam_alias_link
),

-- Collapse NYSIDs into an array so we can check on them in OCA.
-- Any given PDCMS name connected to an alias can have a different NYSID,
-- so we'll capture all of them for now.
nysids_per_person AS (
  SELECT
    nam_alias_link,
    array_agg(DISTINCT nam_nysid) AS nysids
  FROM potential_clients
  GROUP BY nam_alias_link
),

-- Get all addresses for a given alias set.
-- Any PDCMS name can have multiple addresses, so we'll create an array of them.
client_addresses AS (
  SELECT DISTINCT
    cas_aliasid,
    COALESCE(cas_open_date::varchar, adr_date) AS adr_date, -- fall back on case open date in case of data entry problems
    ARRAY[adr_type, adr_street1, adr_street2, adr_city, adr_state, adr_zipcode, adr_ph_number, adr_more_phones] as addresses
  FROM survey_cases
  JOIN addresses
    ON cas_clientid = adr_nameid
    AND cas_file_number = adr_file_number
   group by cas_aliasid, cas_clientid
),

collapse_clients AS (
  -- For a first pass, get the most recent first AND last name
  -- as well as the first present language, race, gender, ethnicity, and citizenship.
  SELECT DISTINCT
    nam_nameid,
    potential_clients.nam_alias_link AS person_id,
    FIRST_VALUE(nam_first_name) OVER (PARTITION BY potential_clients.nam_alias_link ORDER BY rank) AS first_name,
    FIRST_VALUE(nam_last_name) OVER (PARTITION BY potential_clients.nam_alias_link ORDER BY rank) AS last_name,
    FIRST_VALUE(nam_interpreter) OVER (PARTITION BY potential_clients.nam_alias_link ORDER BY nam_interpreter desc) AS language,
    FIRST_VALUE(nam_race) OVER (PARTITION BY potential_clients.nam_alias_link ORDER  BY nam_race desc) AS race,
    FIRST_VALUE(nam_gender) OVER (PARTITION BY potential_clients.nam_alias_link ORDER  BY nam_gender desc) AS gender,
    FIRST_VALUE(nam_ethnicity) OVER (PARTITION BY potential_clients.nam_alias_link ORDER  BY nam_ethnicity desc) AS ethnicity,
    FIRST_VALUE(nam_citizenship) OVER (PARTITION BY potential_clients.nam_alias_link ORDER  BY nam_citizenship desc) AS citizenship,
    nysids,
    adr_date,
    addresses
  FROM potential_clients
  LEFT JOIN nysids_per_person
    ON potential_clients.nam_alias_link = nysids_per_person.nam_alias_link
  LEFT JOIN collapse_client_addresses
    ON potential_clients.nam_alias_link = cas_aliasid
),

-- Remove clients who speak a language other than English (blank) or Spanish
clients_english_spanish as (
  SELECT
    *
  FROM collapse_clients
  WHERE (language in ('ENGLISH', 'SPANISH')
    OR language = '' -- means English
    OR language is null -- means English
    )
)

select * from clients_english_spanish


-- -- TODO: remove homeless? any address that doesn't start WITH a number?
