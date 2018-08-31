-- case_population.sql
-- Get all cases that are eligible to be picked

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
      cas_fc_short,
      cas_docket,
      cas_indictment
    FROM cases
    WHERE cas_case_status = 'C'
    AND cas_closed_date::DATE > current_date - '6 months'::INTERVAL
    AND cas_closed_date::DATE <= current_date
  ),

  cases_w_clients_without_current_case AS (
  -- Remove clients if they or any of their aliases have an open case.
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

  cases_not_transferred AS (
  -- Remove case if it had a transfer disposition
    SELECT
      *
    FROM cases_w_clients_without_current_case
    WHERE NOT exists (
      SELECT 1
      FROM dispositions
      WHERE dsp_file_number = cas_file_number
      AND dsp_action IN ('ADBR', 'ADBX', 'ADQU', 'ADRI', 'ADSA', 'AFC',
                            'C/I', 'EXH', 'INEL', 'PROS', 'R18B', 'RELC',
                            'RHOM', 'RLAS', 'RNDS', 'RPC')
      )
  ),

  cases_with_clients_never_730d AS (
  -- Remove cases with clients who were ever 730'd or found not guilty by reason of insanity
    SELECT
      *
    FROM cases_not_transferred
    WHERE NOT EXISTS (
      SELECT 1
      FROM (
        -- this finds all clients who ever had a case
        -- with a mental illness disposition
        SELECT DISTINCT
          -- use the alias ID to get the linked people
          cas_aliasid
        FROM cases
        JOIN dispositions
          ON cas_file_number = dsp_file_number
        WHERE dsp_action = '730'  
          OR dsp_action = 'NGMD'
      ) ever_mi
      WHERE cases_not_transferred.cas_aliasid = ever_mi.cas_aliasid
    )
  )

  SELECT distinct
    cas_file_number,
    cas_clientid,
    cas_aliasid,
    cas_open_date,
    cas_closed_date,
    cas_case_type,
    cas_case_detail,
    cas_tc_number,
    cas_tc_short,
    cas_fc_number,
    cas_fc_short,
    cas_docket,
    cas_indictment,
    only_acd,
    case_dismissed
  FROM cases_with_clients_never_730d
  LEFT JOIN (
    SELECT
      dsp_file_number,
      MIN(CASE
        WHEN dsp_action in ('ACD', 'MACD', 'FACD') THEN 1
        ELSE 0 END) AS only_acd,
      MIN(CASE
        WHEN dsp_action like 'DIS%' THEN 1
        ELSE 0 END) AS case_dismissed
    FROM dispositions
    WHERE dsp_action != '' AND dsp_action IS NOT NULL
    group BY dsp_file_number
  ) disps
    ON cas_file_number = dsp_file_number
;  
