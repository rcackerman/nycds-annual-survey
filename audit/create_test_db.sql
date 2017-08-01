CREATE TABLE addresses (
  adr_nameid CHARACTER VARYING,
  adr_file_number CHARACTER VARYING,
  adr_type CHARACTER VARYING,
  adr_date CHARACTER VARYING,
  adr_street1 CHARACTER VARYING,
  adr_street2 CHARACTER VARYING,
  adr_city CHARACTER VARYING,
  adr_state CHARACTER VARYING,
  adr_zipcode CHARACTER VARYING,
  adr_ph_number CHARACTER VARYING
)
WITH (
  OIDS=FALSE
);

CREATE TABLE cases (
  eligible CHARACTER VARYING,
  cas_clientid CHARACTER VARYING,
  cas_aliasid CHARACTER VARYING,
  cas_file_number CHARACTER VARYING,
  cas_case_status CHARACTER VARYING,
  cas_open_date CHARACTER VARYING,
  cas_closed_date CHARACTER VARYING,
  cas_entry_date CHARACTER VARYING,
  cas_case_detail CHARACTER VARYING,
  cas_orig_tc_number CHARACTER VARYING,
  cas_orig_tc_short CHARACTER VARYING,
  cas_orig_tc_type CHARACTER VARYING,
  cas_orig_tc_atd CHARACTER VARYING,
  cas_tc_number CHARACTER VARYING,
  cas_tc_short CHARACTER VARYING,
  cas_tc_type CHARACTER VARYING,
  cas_tc_atd CHARACTER VARYING,
  cas_fc_number CHARACTER VARYING,
  cas_fc_short CHARACTER VARYING,
  cas_fc_type CHARACTER VARYING,
  cas_court CHARACTER VARYING,
  cas_atty CHARACTER VARYING,
  cas_intake_type CHARACTER VARYING,
  cas_docket CHARACTER VARYING,
  cas_indictment CHARACTER VARYING,
  cas_sci CHARACTER VARYING,
  cas_fct_number CHARACTER VARYING,
  cas_idv_ct_number CHARACTER VARYING,
  cas_idv_docket CHARACTER VARYING,
  CONSTRAINT cas_file_number_pk PRIMARY KEY (cas_file_number)
)
WITH (
 OIDS=FALSE
)
;

CREATE TABLE dispositions (
  dsp_file_number CHARACTER VARYING,
  dsp_top_chg CHARACTER VARYING,
  dsp_ini_chg_short CHARACTER VARYING,
  dsp_ini_chg_number CHARACTER VARYING,
  dsp_ini_chg_type CHARACTER VARYING,
  dsp_ini_chg_atd CHARACTER VARYING,
  dsp_date CHARACTER VARYING,
  dsp_action CHARACTER VARYING,
  dsp_final_chg_number CHARACTER VARYING,
  dsp_final_chg_short CHARACTER VARYING,
  dsp_final_chg_type CHARACTER VARYING,
  dsp_final_chg_atd CHARACTER VARYING,
  dsp_notes TEXT
)
WITH (
  OIDS=FALSE
)
;

CREATE TABLE names (
  nam_nameid CHARACTER VARYING,
  nam_alias_link CHARACTER VARYING,
  nam_nysid CHARACTER VARYING,
  nam_last_name CHARACTER VARYING,
  nam_middle_name CHARACTER VARYING,
  nam_first_name CHARACTER VARYING,
  nam_dob CHARACTER VARYING,
  nam_interpreter CHARACTER VARYING,
  nam_country_born CHARACTER VARYING,
  nam_race CHARACTER VARYING,
  nam_gender CHARACTER VARYING,
  nam_ethnicity CHARACTER VARYING,
  nam_citizenship CHARACTER VARYING,
  nam_green_card CHARACTER VARYING,
  nam_imm_stat CHARACTER VARYING,
  nam_imm_date_gc CHARACTER VARYING,
  nam_imm_eff_dt_stat CHARACTER VARYING,
  nam_imm_entry_date CHARACTER VARYING,
  nam_imm_entry_stat CHARACTER VARYING
) 
WITH (
  OIDS=FALSE
)
;
 
CREATE TABLE sentences (
  snt_file_number CHARACTER VARYING,
  snt_topchg CHARACTER VARYING,
  snt_chg_number CHARACTER VARYING,
  snt_chg_descr CHARACTER VARYING,
  snt_chg_type CHARACTER VARYING,
  snt_date CHARACTER VARYING,
  snt_type CHARACTER VARYING,
  snt_length CHARACTER VARYING,
  snt_condition CHARACTER VARYING,
  snt_notes TEXT
)
WITH (
  OIDS=FALSE
)
;

-- Index: public.cas_aliasid
-- DROP INDEX cas_aliasid_ix;
CREATE INDEX cas_aliasid_ix
ON public.cases
USING btree
(cas_aliasid COLLATE pg_catalog."default");

-- Index: public.cas_clientid_aliasid_idx
-- DROP INDEX cas_clientid_aliasid_idx;
CREATE INDEX cas_clientid_aliasid_idx 
ON public.cases
USING btree
(cas_clientid COLLATE pg_catalog."default", cas_aliasid COLLATE pg_catalog."default");

-- Index: public.cas_clientid_idx
-- DROP INDEX cas_clientid_ix;
CREATE INDEX cas_clientid_idx
ON public.cases
USING btree
(cas_clientid COLLATE pg_catalog."default");

-- Index: public.dsp_file_number_idx
-- DROP INDEX public.dsp_file_number_ix;
CREATE INDEX dsp_file_number_idx
ON public.dispositions
USING btree
(dsp_file_number COLLATE pg_catalog."default");