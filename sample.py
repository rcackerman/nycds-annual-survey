import pandas as pd

# For now, read from csv report
survey_frame = pd.read_sql('select * from TABLE')
survey_frame.columns = ['client_name', 'tc_pl_short', 'tc_class',
                                                'fc_pl_short', 'fc_type', 'dispo', 'dispo_date',
                                                'sent_type', 'sent_condition', 'sent_notes',
                                                'age', 'docket', 'indictment', 'closed_date',
                                                'open_date', 'unnamed']


survey_frame['length_of_case'] = pd.to_datetime(survey_frame.closed_date) - pd.to_datetime(survey_frame.open_date)

# Figure out which cases are NY county cases
# we only want those
survey_frame['county'] = survey_frame.docket.str.extract('([a-zA-Z/]+)', expand=False)
survey_frame['county'] = survey_frame.apply(lambda row: 'NY' if ((row['county'] in ['/', 'N/', 'NY', 'O'])) else 'Out of County', axis=1)
survey_frame.loc[~pd.isnull(survey_frame['indictment']), 'county'] = 'NY'

survey_frame = survey_frame.loc[survey_frame['county'] == 'NY', :]