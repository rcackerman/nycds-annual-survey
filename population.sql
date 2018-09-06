-- population.sql

WITH fullnames AS (
-- Get first and last name for each client in a person grouping
  SELECT
    nam_alias_link,
    array_agg(fname ORDER BY fname) AS client_names
  FROM (
    SELECT distinct
      nam_alias_link,
      nam_first_name || ' ' || nam_last_name AS fname
    FROM names
  ) nams
  group BY nam_alias_link
),

sw_assigned AS (
  SELECT
    res_file_number,
    res_date
  FROM results
  WHERE res_code = 'SW ASSIGNED'
),

investigator_assigned AS (
  SELECT
    evt_file_number,
    evt_event_date
  FROM events
  WHERE evt_purpose = 'INVR'
)

SELECT
    client_names,
    survey_people.*,
    survey_cases.*
FROM survey_people
JOIN fullnames
  ON survey_people.person_id = nam_alias_link
JOIN survey_cases
  ON survey_people.person_id = survey_cases.cas_aliasid
LEFT JOIN sentences
  ON survey_cases.cas_file_number = sentences.snt_file_number
;
