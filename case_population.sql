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
      cas_indictment,
      dsp_action,
      dsp_date,
      dsp_notes,
      CASE
        WHEN dsp_action in ('ACD', 'MACD', 'FACD')
          THEN true
        ELSE
          false
      END AS dsp_ACD,
      CASE
        WHEN dsp_action in ('ADBR', 'ADBX', 'ADQU', 'ADRI', 'ADSA', 'AFC',
                            'C/I', 'EXH', 'INEL', 'PROS', 'R18B', 'RELC',
                            'RHOM', 'RLAS', 'RNDS', 'RPC')
          THEN true
        ELSE
          false
      END AS dsp_transfer
    FROM cases
    LEFT JOIN dispositions
      ON cas_file_number = dsp_file_number
      AND dsp_action IS NOT null AND dsp_action != ''
    WHERE cas_case_status = 'C'
    AND cas_closed_date::DATE > current_date - '6 months'::INTERVAL
    AND cas_closed_date::DATE <= current_date
  ),

  -- Remove clients with current case.
  -- Remove clients with disposition of being transferred to another provider.
  clients_no_current_case AS (
    SELECT
      *
    FROM closed_cases
    WHERE dsp_ACD = 'f'
    AND dsp_transfer = 'f'
    AND NOT EXISTS (
      SELECT 1
      FROM cases
      WHERE cases.cas_case_status != 'C'
      AND cases.cas_aliasid = closed_cases.cas_aliasid
    )
    -- AND NOT EXISTS (
      -- SELECT 1
      -- FROM closed_cases AS self
      -- WHERE self.dispo_type = 'ACD'
      -- AND self.cas_aliasid = closed_cases.cas_aliasid
      -- AND self.cas_file_number != closed_cases.cas_file_number
    -- )
  ),

  -- Remove clients who were ever 730'd
  clients_never_730d AS (
    SELECT
      *
    FROM clients_no_current_case
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
      WHERE clients_no_current_case.cas_aliasid = ever_mi.cas_aliasid
    )
  )

  SELECT
    clients_never_730d.*,
    snt_type,
    snt_condition,
    snt_notes
  FROM clients_never_730d
  LEFT JOIN sentences
    ON cas_file_number = snt_file_number
;  
