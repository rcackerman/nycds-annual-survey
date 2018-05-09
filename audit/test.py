# setup
from os import path
import glob
import pandas
import numpy
from sqlalchemy import create_engine
from sqlalchemy.schema import CreateSchema, DropSchema
from setup import *

with ENGINE.connect() as conn:
    setup(conn)

# run
conn = ENGINE.connect()
conn.execute('set search_path to audit')
conn.execute() # survey sql
conn.close()

# get case ids

# check columns

# check whether case is eligible

# check whether person is eligible

# teardown
with ENGINE.connect() as conn:
    teardown(conn)
