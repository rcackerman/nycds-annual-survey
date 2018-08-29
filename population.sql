-- population.sql

-- Get first and last name for each client in a person grouping
SELECT
    nam_nameid,
    person_id,
    array_agg(DISTINCT nam_first_name || nam_last_name) AS client_names,
    dob,
    language,
    gender,
    ethnicity,
    citizenship,
    array_agg(DISTINCT nam_citizenship_status) AS citizenship_statuses
FROM survey_people
JOIN names
  ON survey_people.person_id = names.nam_alias_link
;
