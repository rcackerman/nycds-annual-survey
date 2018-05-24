from os import path
import glob
import pandas
import numpy
from sqlalchemy import create_engine
from sqlalchemy.sql import select, text
from sqlalchemy.schema import CreateSchema, DropSchema

ENGINE = create_engine('postgresql://postgres@localhost:5433/pdcms')
AUDIT_DIR = path.dirname(path.realpath(__file__))

def load_df(filename, **kwargs):
    """Import csv as pandas DataFrame, then clean.
    """
    frame = pandas.read_csv(filename, 
                            na_values = ['00000000', ' ', ''],
                            encoding='latin1',
                            dtype='object')
    return frame


def parse_sql(filename):
    """Parses SQL into a list of queries, so SQLAlchemy can deal.
    """
    with open(filename, 'r') as f:
        queries = f.read().split(';')
    return([q for q in queries if q.strip() != ''])


def execute_survey_sql(conn, sql_file):
    sql_statements = parse_sql(sql_file)
    conn.execute('set search_path to audit')
    for s in sql_statements:
        conn.execute(s)
    return True


def setup(conn): 
    """Set up testing database.
    """
    conn.execute(CreateSchema('audit'))
    for filename in glob.iglob('{}\*.csv'.format(AUDIT_DIR)):
        df = load_df(filename)
        df.to_sql(name=path.basename(filename)[5:-4], # get rid of test_ and .csv,
                          con=conn,
                          schema='audit',
                          if_exists = 'replace')
    return True


def teardown(conn):
    """Teardown testing database.
    """
    conn.execute(DropSchema('audit', cascade=True))
    return True


def test_intermediate_pop_tables(conn, pdcms_table, survey_table):
    """Compare the results against the eligiblity status stated in the test
    tables.

    Arguments:
    conn:           connection object
    results:        records in the survey_* table being tested
    pdcms_table:    SQLAlchemy Table object reflecting the (fake) PDCMS table
    survey_table:   SQLAlchemy Table object reflecting the survey table 
    """
    if survey_table.name == 'survey_cases':
        pdcms_table_id_col = 'cas_file_number'
        survey_table_id_col = 'cas_file_number'
        elig_col = 'eligible_case'
    elif survey_table.name == 'survey_people':
        pdcms_table_id_col = 'nam_alias_link'
        survey_table_id_col = 'cas_aliasid'
        elig_col = 'eligible_pers'
    else:
        return False


    results = select([survey_table.c[survey_table_id_col]])

    s_falsepos = select([pdcms_table.c[pdcms_table_id_col],
                         pdcms_table.c.eligible_case,
                         pdcms_table.c.eligible_pers
                        ]).where(pdcms_table.c[elig_col].ilike('no%')) \
                          .where(pdcms_table.c[pdcms_table_id_col].in_(results))
    s_falseneg = select([pdcms_table.c[pdcms_table_id_col],
                         pdcms_table.c.eligible_case,
                         pdcms_table.c.eligible_pers
                        ]).where(pdcms_table.c[elig_col].ilike('yes%')) \
                          .where(pdcms_table.c[pdcms_table_id_col].notin_(results))

    return {'false positives': conn.execute(s_falsepos).fetchall(),
            'false negatives': conn.execute(s_falseneg).fetchall()}


def get_final_test_results(sql_table_df, desired_result_df):
    """Compare the final postgresql survey table against the desired result.
    For ease of re-use, takes two pandas dataframes.
    
    Arguments:
    sql_table_df:       Pandas DataFrame object
    desired_result_df:  Pandas DataFrame object
    """
    pass


