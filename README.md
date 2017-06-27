# Annual Survey

This is the codebase for the annual survey.

Steps for population:
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
4. Remove clients who speak a language other than English (blank) or Spanish.
5. Remove clients whose last address is 'homeless' or an address that is a shelter, hospital, or rehab facility.
6. Remove clients whose last address is not an address at all (since we can't mail them anything).
6. Remove clients who were ever 730'd.
7. Remove clients currently under 18.

Potentially remove clients who are in mental health court and clients who had more than one assigned attorney.

Steps for sample:
1. Create dummy variable for disposition at arraignments (1 court appearance total).
2. Create dummy variable for having gone to trial.
3. Create dummy variable for female.
4. Create dummy variable for incarcerated at Rikers.
5. Create dummy variable for incarcerated upstate.
6. Create dummy variable for felony.
7. ~~Create dummy variable for whether they were in jail during pendency of their case.~~
