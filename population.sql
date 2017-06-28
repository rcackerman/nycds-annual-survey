-- population.sql

DROP TABLE IF EXISTS survey_cases;

CREATE TABLE survey_cases AS

WITH closed_cases AS (
  SELECT
    cas_file_number,
    cas_clientid,
    cas_aliasid,
    cas_open_date::DATE AS cas_open_date,
    cas_closed_date::DATE AS cas_closed_date,
    cas_case_type,
    cas_case_detail,
    cas_tc_number,
    cas_tc_short,
    cas_fc_number,
    cas_fc_short
  FROM cases
  WHERE cas_case_status = 'C'
  AND cas_closed_date::DATE > current_date - '3 years'::INTERVAL
),

-- Remove clients with current case.
clients_no_current_case AS (
  SELECT
    *
  FROM closed_cases
  WHERE NOT EXISTS (
    SELECT 1
    FROM cases
    WHERE cases.cas_case_status != 'C'
    AND cases.cas_aliasid = closed_cases.cas_aliasid
  )
),

-- Remove clients with disposition of being transferred to another provider.
cases_not_transferred AS (
  SELECT
    *
  FROM clients_no_current_case
  WHERE NOT EXISTS (
    SELECT 1
    FROM dispositions
    WHERE dispositions.dsp_file_number = cas_file_number
    AND dsp_action in ('ADBR', 'ADBX', 'ADQU', 'ADRI', 'ADSA', 'AFC',
                       'C/I', 'EXH', 'INEL', 'PROS', 'R18B', 'RELC',
                       'RHOM', 'RLAS', 'RNDS', 'RPC')
  )
),

-- Get sentence info so we can tell who will be in or out
cases_with_sentencing AS (
  SELECT
    cases_not_transferred.*,
    snt_date,
    snt_type,
    snt_length,
    snt_condition
  FROM cases_not_transferred
  LEFT JOIN sentences
    ON cas_file_number = snt_file_number
    AND (snt_date != ''
      OR snt_length != ''
      OR snt_condition != '')
),

-- Remove clients who were ever 730'd
clients_ever_730d AS (
  SELECT
    *
  FROM cases_with_sentencing
  WHERE NOT EXISTS (
    SELECT 1
    FROM (
      -- this finds all clients who ever had a case
      -- with a mental illness disposition
      SELECT DISTINCT
        cas_aliasid -- use the alias ID to get the linked people
      FROM cases
      JOIN dispositions
        ON cas_file_number = dsp_file_number
      WHERE dsp_action = '730'  
        OR dsp_action = 'NGMD'
    ) ever_mi
    WHERE cases_with_sentencing.cas_aliasid = ever_mi.cas_aliasid
  )
)

  SELECT *
  FROM clients_ever_730d
;  
