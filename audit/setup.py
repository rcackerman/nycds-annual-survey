from os import path
import glob
import pandas
import numpy
from sqlalchemy import create_engine
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

def teardown(conn):
    """Teardown testing database.
    """
    conn.execute(DropSchema('audit', cascade=True))


with ENGINE.connect() as conn:
    setup(conn)


with ENGINE.connect() as conn:
    teardown(conn)
