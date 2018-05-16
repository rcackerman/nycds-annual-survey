# setup
from os import path
import glob
import pandas
import numpy
from sqlalchemy import create_engine
from sqlalchemy.schema import CreateSchema, DropSchema, Table
from sqlalchemy.sql import text
from setup import *

def parse_sql(filename):
    """Parses SQL into a list of queries, so SQLAlchemy can deal.
    """
    with open(filename, 'r') as f:
        queries = f.read().split(';')
    return([q for q in queries if q.strip() != ''])


with ENGINE.connect() as conn:
    setup(conn)


sql_statements = parse_sql('..\case_population.sql')
# run
conn = ENGINE.connect()
conn.execute('set search_path to audit')
for s in sql_statements:
    conn.execute(s)

cases = conn.execute(
            'select cas_file_number, cas_aliasid from survey_cases').fetchall()
results = conn.execute(text(
                        "select eligible_case, eligible_pers, cas_file_number "
                        "from cases where cas_file_number in :numbers"),
                       numbers = tuple([i[0] for i in ids])
                       ).fetchall()



# teardown
teardown(conn)
conn.close()
