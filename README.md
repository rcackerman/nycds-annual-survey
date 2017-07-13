# Annual Survey

This is the codebase for the annual survey.

### Population construction
The population dataset is created in 3 stages.

#### population.sql

`population.sql` generates a dataset of clients on cases that qualify:
1. Get all clients who are on a closed case, which was disposed of in the last 3 years.
2. Remove clients with current case.
3. Remove clients with disposition of being transferred to another provider. Disposition codes are:
  * 'ADBR' - adjourned to Brooklyn
  * 'ADBX' - adjourned to Bronx
  * 'ADQU' - adjourned to Queens
  * 'ADRI' - adjourned to Richmond (Staten Island)
  * 'ADSA' - adjourned to SAP part
  * 'AFC' - adjourned to family court
  * 'C/I' - conflict of interest necessitated transfer
  * 'EXH'- extradited after hearing
  * 'INEL' - ineligible
  * 'PROS' - relieved due to pro se
  * 'R18B' - relieved by 18b attorney
  * 'RELC' - relieved by court action
  * 'RHOM' - relieved by homicide
  * 'RLAS' - relieved by Legal Aid
  * 'RNDS' - relieved by NDS
  * 'RPC' - client retained private counsel
4. Remove clients who were ever 730'd.

In this file we do not collapse people; that is, if someone is on multiple cases, or has multiple dispositions of a case, they will appear in this dataset multiple times.

#### client_information.sql

In this file, we collect all demographic information for clients, including information from any aliases that client might have.

This file also does not collapse clients, so a given client - and their aliases - may appear more than once.

`client_information.sql` uses `population.sql` and further refines it. Specifically, in `client_information.sql`, we:
5. Remove clients who speak a language other than English (blank) or Spanish.
6. Remove clients currently under 18.


#### population.py

Finally, we use python to remove clients who are homeless or have unstable housing. In `population.py` we:
7. Remove clients whose last address is 'homeless' or an address that is a shelter, hospital, or rehab facility.

In `population.py`, we also create dummy variables for the following:
1. Disposition at arraignments (1 court appearance total).
2. Having gone to trial.
3. Female clients.
4. Cases ended with incarceration at Rikers.
5. Cases ended with incarceration upstate.
6. Felony indictments.

#### Population dataset

Once completed, the final population dataset will contain data needed to select a stratified random sample as well as information needed to tell the recipient which case experience to answer questions about.

The final columns will be:
* `cas_docket` - the docket number for the case
* `cas_indictment` or other felony case #
* `cas_open_date` - the date the case opened
* `cas_closed_date` - the date the case was closed
* `cas_tc_number` - top charge
* `cas_tc_short` - top charge
* `cas_fc_number` - final charge
* `cas_fc_short` - final charge
* `person_id` - corresponding to `cas_aliasid`, this is the ID for the group of duplicate people on different cases
* `snt_type` - the type of sentence
* `snt_length` - the length of the sentence
* `snt_condition` - any conditions of the sentence
* `snt_date` - the date the sentence was imposed (will be used to figure out if someone is still in jail/prison)
* `first_name` - the most recent first name across all aliases 
* `last_name` - the most recent last name across all aliases
* `language` - the first language code found across all aliases
* `race` - the first race code found across all aliases
* `ethnicity` - the first ethnicity code found across all aliases
* `citizenship` - the first citizenship code found across all aliases
* `nysids` - a list of all NYSIDs associated with the person's aliases
* address information - TBD

### Potential to-dos/etc

Potentially remove clients who are in mental health court and clients who had more than one assigned attorney.

Due to how messy the address data are, we will need to do more processing (maybe manually) to figure out who to mail things to.


Steps for sample:
7. ~~Create dummy variable for whether they were in jail during pendency of their case.~~
6. ~~Remove clients whose last address is blank (since we can't mail them anything).~~
