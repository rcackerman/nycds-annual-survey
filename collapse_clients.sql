-- collapse_clients.sql
-- PDCMS links people to deal with duplicates
-- this query collapses those links into discrete groups

-- For right now, work with clients only
-- Look up clients by alias, because the alias ID is the "master" ID
-- so provides a link across versions of the same person.
-- Also flag the most recently entered version of the person
-- because names don't have an entered-on date
WITH potential_clients AS (
  SELECT
    names.*,
    RANK() OVER (PARTITION BY nam_alias_link ORDER BY cas_open_date::DATE, cas_file_number desc)
  FROM names
  JOIN survey_cases
  ON cas_aliasid = nam_alias_link
)
,

nysids_per_person AS (
  -- Collapse NYSIDs into an array so we can check on them in OCA.
  -- Any given person connected to an alias can have a different NYSID,
  -- so we'll capture all of them for now.
  SELECT
    nam_alias_link,
    array_agg(DISTINCT nam_nysid) AS nysids
  FROM potential_clients
  GROUP BY nam_alias_link
),

collapse_clients AS (
  -- -- For a first pass, get the most recent first AND last name
  -- -- as well as the first present language, race, gender, ethnicity, and citizenship.
  -- -- In the next CLE we will collapse NYSIDs, but for now we will keep them as-is.
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
    nysids
  FROM potential_clients
  JOIN nysids_per_person
    ON potential_clients.nam_alias_link = nysids_per_person.nam_alias_link
  order by person_id
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
),

-- get address information
-- TODO: add CASE open date because if the address doesn't exist it won't have an address itself
-- TODO: COALESCE CASE open date AND address date so we have an approximate date for the blank address
clients_addresses AS (
  SELECT
    clients_english_spanish.*,
    adr_type,
    adr_street1,
    adr_street2,
    adr_city,
    adr_state,
    adr_zipcode,
    adr_ph_number,
    adr_more_phones,
    RANK() OVER (PARTITION BY person_id ORDER BY adr_date desc, adr_type, adr_file_number desc) AS addr_nb
  FROM clients_english_spanish
  JOIN addresses
    ON adr_nameid = nam_nameid
),

-- Remove people whose address most recent is blank
clients_no_blank_addresses AS (
  SELECT
    *
  FROM clients_addresses
  WHERE NOT exists (
    -- if the person_id's most recent address is blank, take out the person
    -- we need there to be address information in at least one street fields
    SELECT 1
    FROM (SELECT * FROM clients_addresses WHERE addr_nb = 1) firsts
    WHERE clients_addresses.person_id = firsts.person_id
      AND (adr_street1 = '' 
          OR adr_street2 = '')
  )
)

select * from clients_no_blank_addresses


-- -- TODO: remove homeless? any address that doesn't start WITH a number?
