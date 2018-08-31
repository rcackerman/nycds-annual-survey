-- population.sql

-- Get first and last name for each client in a person grouping
SELECT
    array_agg(DISTINCT nam_first_name || nam_last_name ORDER BY nam_last_name, nam_first_name) AS client_names,
    survey_people.*,
    survey_cases.*
FROM survey_people
JOIN names
  ON survey_people.person_id = names.nam_alias_link
JOIN survey_cases
  ON survey_people.person_id = survey_cases.cas_aliasid
;
