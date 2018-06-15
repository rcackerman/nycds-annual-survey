import os
import pandas as pd
import numpy as np

DATASETS_DIR = os.path.join(
                os.path.dirname(
                    os.path.realpath(__file__)), 'data')

###
# Main survey frame, from PDCMS data
# This is expected to be a CSV in the data subfolder of the main project folder
survey_frame_df = pd.read_csv('frame.csv')

# Get rid of non-NY county cases
non_ny_docket_paterns = (survey_frame_df['cas_docket'].str.contains('NY', na=False)
                         or survey_frame_df['cas_docket'].str.contains('CN', na=False)
                         or survey_frame_df['cas_docket'].str.contains('/', na=False)
                         or pd.isnull(survey_frame_df['cas_docket']))
survey_frame_df = survey_frame_df.loc[non_ny_docket_paterns, :]

# Dockets don't belong in the indictment numbers!
# Indictments don't belong in the docket numbers!
survey_frame_df.loc[(survey_frame_df['cas_docket'].str.contains('/', na=False)), 'cas_docket'] = None
survey_frame_df.loc[(survey_frame_df['cas_indictment'].str.contains('NY', na=False)), 'cas_indictment'] = None

###
# Join with other data sources for info we want to stratify on
trials = pd.read_csv('') #clients who went to trial
bail_info = pd.read_csv() #clients' bail status
social_work_referrals = pd.read_csv()
investigation_referral = pd.read_csv()

###
# Some things to potentially stratify on
survey_frame_df['non-citizen'] = None
survey_frame_df['trial'] = None
survey_frame_df['gender'] = None
survey_frame_df['sentenced_to_jail'] = None
survey_frame_df['single_day_case'] = None # or just get rid of that
survey_frame_df['first_arrest'] = None

###
# Things that are important to know
survey_frame_df['social_work_referral'] = None
survey_frame_df['investigation_referral'] = None
survey_frame_df['age_group'] = None
survey_frame_df['indicted'] = survey_frame_df['cas_indictment'].apply(
                                lambda x: True if pd.notnull(x) else False)
survey_frame_df['currently_incarcerated'] = None
