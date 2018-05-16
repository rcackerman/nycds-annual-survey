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
      cas_fc_short,
      cas_docket,
      cas_indictment
    FROM cases
    WHERE cas_case_status = 'C'
    AND cas_closed_date::DATE > current_date - '6 months'::INTERVAL
    AND cas_closed_date::DATE <= current_date
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

  -- Remove clients who were ever 730'd
  clients_ever_730d AS (
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

  SELECT
    cas_file_number,
    cas_aliasid,
    cas_open_date,
    cas_closed_date,
    cas_case_type,
    cas_case_detail,
    cas_tc_number,
    cas_tc_short,
    cas_fc_number,
    cas_fc_short
  FROM clients_ever_730d
;  
