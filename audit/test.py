# setup
from os import path
import glob
import pandas
import numpy
from sqlalchemy import create_engine, Table, MetaData
from sqlalchemy.sql import select, text
from sqlalchemy.schema import CreateSchema, DropSchema
from setup import *

def parse_sql(filename):
    """Parses SQL into a list of queries, so SQLAlchemy can deal.
    """
    with open(filename, 'r') as f:
        queries = f.read().split(';')
    return([q for q in queries if q.strip() != ''])


def get_result_comparison(conn, pdcms_table, survey_table):
    """Compare the results against the eligiblity status stated in the test
    tables.

    Arguments:
    conn:           connection object
    results:        records in the survey_* table being tested
    pdcms_table:    SQLAlchemy Table object reflecting the (fake) PDCMS table
    survey_table:   SQLAlchemy Table object reflecting the survey table 
    """
    if survey_table.name == 'survey_cases':
        id_col = 'cas_file_number'
        elig_col = 'eligible_case'
    elif survey_table.name == 'survey_names':
        id_col = 'nam_nameid'
        elig_col = 'eligible_pers'
    else:
        return False

    results = select([survey_table.c[id_col]])

    s_falsepos = select([pdcms_table.c[id_col],
                         pdcms_table.c.eligible_case,
                         pdcms_table.c.eligible_pers
                        ]).where(pdcms.c[elig_col].ilike('no%')) \
                          .where(pdcms_table.c[id_col].in_(results))
    s_falseneg = select([pdcms_table.c[id_col],
                         pdcms_table.c.eligible_case,
                         pdcms_table.c.eligible_pers
                        ]).where(pdcms_table.c[elig_col].ilike('yes%')) \
                          .where(pdcms_table.c[id_col].notin_(results))

    return {'false positives': conn.execute(s_falsepos).fetchall(),
            'false negatives': conn.execute(s_falseneg).fetchall()}


with ENGINE.connect() as conn:
    setup(conn)


def test_cases():
    sql_statements = parse_sql('..\case_population.sql')

    # run
    conn = ENGINE.connect()
    conn.execute('set search_path to audit')
    for s in sql_statements:
        conn.execute(s)

    cases = Table('cases', meta, autoload=True, autoload_with=ENGINE,
                  schema='audit')
    survey_cases = Table('survey_cases', meta, autoload=True, autoload_with=ENGINE,
                  schema='audit')
    print(get_result_comparison(conn, cases, survey_cases))


    conn.close()


# teardown
with ENGINE.connect() as conn:
    teardown(conn)
