import os
import pandas as pd
import numpy as np

DATASETS_DIR = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'data')

###
# Main survey frame, from PDCMS data
# This is expected to be a CSV in the data subfolder of the main project folder
survey_frame_df = pd.read_csv('frame.csv')

# Get rid of non-NY county cases
non_ny_docket_paterns = (survey_frame_df['cas_docket'].str.contains('NY', na=False)
                         or survey_frame_df['cas_docket'].str.contains('CN', na=False)
                         or pd.isnull(survey_frame_df['cas_docket']))
survey_frame_df = survey_frame_df.loc[non_ny_docket_paterns, :]


###
# Join with other data sources for info we want to stratify on
trials = pd.read_csv('') #clients who went to trial
bail_info = pd.read_csv() #clients' bail status

###
# Some things to potentially stratify on

# Stop and Frisk-type arrests: marijuana, jumping turnstiles, etc
survey_frame_df['stop_frisk']
survey_frame_df['indicted'] = survey_frame_df['cas_indictment'].apply(
                                lambda x: True if pd.notnull(x) else False)
survey_frame_df['non-citizen']

