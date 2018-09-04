import os
import pandas as pd
import numpy as np

DATASETS_DIR = os.path.join(
                os.path.dirname(
                    os.path.realpath(__file__)), 'data')

###
# Main survey frame, from PDCMS data
# This is expected to be a CSV in the data subfolder of the main project folder
survey_frame = pd.read_csv('frame.csv')

# Get rid of non-NY county cases
ny_docket_paterns = (survey_frame['cas_docket'].str.contains('[0-9]NY*[0-9]', na=False)
                     or survey_frame['cas_docket'].str.contains('CN', na=False)
                     or survey_frame['cas_docket'].str.contains('/', na=False)
                     or pd.isnull(survey_frame['cas_docket']))
survey_frame = survey_frame.loc[ny_docket_paterns, :]

# Dockets don't belong in the indictment numbers!
# Indictments don't belong in the docket numbers!
indictment_pattern = (survey_frame['cas_docket'].str.contains('/', na=False))
docket_pattern = (survey_frame['cas_indictment'].str.contains('NY', na=False))
# Copies the indictment number into the indictment column,
# then sets the indictment number in the docket column to None
survey_frame.loc[indictment_pattern, 'cas_indictment'] = survey_frame.loc[indictment_pattern, 'cas_docket']
survey_frame.loc[indictment_pattern, 'cas_docket'] = None
# Copies the docket number into the docket column,
# then sets the docket number in the indictment column to None
survey_frame.loc[docket_pattern, 'cas_indictment'] = survey_frame.loc[docket_pattern, 'cas_indictment']
survey_frame.loc[docket_pattern, 'cas_indictment'] = None

###
# Join with other data sources for info we want to stratify on
trials = pd.read_csv('') #clients who went to trial
bail_info = pd.read_csv() #clients' bail status
social_work_referrals = pd.read_csv()
investigation_referral = pd.read_csv()

###
# Some things to potentially stratify on
survey_frame['non-citizen'] = None
survey_frame['trial'] = None
survey_frame['gender'] = None
survey_frame['sentenced_to_incarceration'] = None
survey_frame['single_day_case'] = None # or just get rid of that
survey_frame['first_arrest'] = None

###
# Things that are important to know
survey_frame['social_work_referral'] = None
survey_frame['investigation_referral'] = None
survey_frame['age_group'] = None
survey_frame['indicted'] = survey_frame['cas_indictment'].apply(
                                lambda x: True if pd.notnull(x) else False)
survey_frame['currently_incarcerated'] = None
