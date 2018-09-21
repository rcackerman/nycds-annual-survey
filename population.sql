-- population.sql

WITH fullnames AS (
-- Get first and last name for each client in a person grouping
  SELECT
    nam_alias_link,
    array_agg(fname ORDER BY fname) AS client_names
  FROM (
    SELECT distinct
      nam_alias_link,
      COALESCE(nam_first_name, '') || ' ' || COALESCE(nam_last_name, '') AS fname
    FROM names
  ) nams
  group BY nam_alias_link
),

sw_assigned AS (
  SELECT
    res_file_number,
    res_date,
    1 AS sw_assigned
  FROM results
  WHERE res_code = 'SW ASSIGNED'
),

investigator_assigned AS (
  SELECT
    evt_file_number,
    evt_event_date,
    1 AS investigator_assigned
  FROM events
  WHERE evt_purpose = 'INVR'
),

sentenced_to_incarceration AS (
  SELECT
    snt_file_number,
    MAX(CASE when snt_type in ('JAIL', 'JAIL&PROB') THEN 1 ELSE 0 END) AS sentenced_to_incarceration,
    MAX(CASE when snt_type = 'JAIL T S' THEN 1 ELSE 0 END) AS time_served,
    MAX(CASE when snt_type = 'COND DISC' THEN 1 ELSE 0 END) AS conditional_discharge
  FROM sentences
  WHERE exists (
    -- filters down TO survey cases because the CASE statements above are costly
    SELECT 1
    FROM survey_cases
    WHERE survey_cases.cas_file_number = snt_file_number
  )
  group BY snt_file_number
)

SELECT distinct
    client_names,
    survey_people.*,
    cas_file_number AS pdcms_case_id,
    docket_number,
    indictment_number,
    assigned_attorney,
    case_open_date,
    case_close_date,
    case_type,
    top_charge,
    top_charge_desc,
    top_charge_type,
    final_charge,
    final_charge_desc,
    final_charge_type,
    only_acd,
    case_dismissed,
    sentenced_to_incarceration,
    time_served,
    conditional_discharge,
    sw_assigned,
    res_date AS sw_assign_date,
    investigator_assigned,
    investigator_assigned.evt_event_date AS inv_assign_date
FROM survey_people
JOIN fullnames
  ON survey_people.person_id = nam_alias_link
JOIN survey_cases
  ON survey_people.person_id = survey_cases.cas_aliasid
LEFT JOIN sw_assigned
  ON survey_cases.cas_file_number = sw_assigned.res_file_number
LEFT JOIN investigator_assigned
  ON survey_cases.cas_file_number = investigator_assigned.evt_file_number
LEFT JOIN sentenced_to_incarceration
  ON survey_cases.cas_file_number = snt_file_number
;
