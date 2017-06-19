-- population.sql


WITH closed_cases AS (
  SELECT
    cas_file_number,
    cas_clientid,
    cas_aliasid,
    cas_case_type,
    cas_case_detail
  FROM cases
  WHERE cas_case_status = 'C'
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
    AND (cases.cas_clientid = closed_cases.cas_clientid
      OR cases.cas_aliasid = closed_cases.cas_aliasid
      OR cases.cas_clientid = closed_cases.cas_aliasid
      OR cases.cas_aliasid = closed_cases.cas_clientid
    )
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

-- Remove clients who speak a language other than English (blank) or Spanish
client_info as (
  select
    nam_nameid,
    nam_alias_link,
    nam_nysid,
    nam_last_name,
    nam_first_name,
    nam_middle_name,
    nam_dob,
    nam_interpreter,
    nam_race,
    nam_gender,
    nam_ethnicity,
    nam_citizenship
  FROM names
  JOIN cases_not_transferred
    ON cas_clientid = nam_nameid
    OR cas_aliasid = nam_nameid
    OR cas_clientid = nam_alias_link
    OR cas_aliasid = nam_alias_link
  WHERE interpreter in ('English', 'Spanish')
)

-- get address information
SELECT
  *
FROM client_info
JOIN addresses
ON adr_nameid = nam_nameid
OR adr_nameid = nam_alias_link

-- TODO: get in or out status
;  
