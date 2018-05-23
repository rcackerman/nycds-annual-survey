# setup
from os import path
import glob
import pandas
import numpy
from sqlalchemy import create_engine, Table, MetaData
from sqlalchemy.sql import select, text
from sqlalchemy.schema import CreateSchema, DropSchema
from setup import *




with ENGINE.connect() as conn:
    setup(conn)

pdcms_tables = MetaData(bind=ENGINE, schema='audit')

# run
conn = ENGINE.connect()
conn.close()

def test_case_pop_sql():
    """Test that only eligible cases are returned.
    """
    execute_survey_sql(conn, '..\case_population.sql')

    # define the survey table in SQL alchemy
    survey_cases = Table('survey_cases', meta, autoload=True, autoload_with=ENGINE,
                  schema='audit')
    print(get_result_comparison(conn, cases, survey_cases))


def test_people_pop_sql():
    """Test that only eligible people are returned.
    """
    execute_survey_sql(conn, '..\people_population.sql')
    
    # define the survey table in SQL alchemy
    survey_people = Table('survey_people', meta, autoload=True, autoload_with=ENGINE,
                          schema='audit')


# teardown
with ENGINE.connect() as conn:
    teardown(conn)
