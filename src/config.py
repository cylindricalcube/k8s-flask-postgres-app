import os

class Config(object):
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'super-s3cure-pla!nt3xt-s3cret'
    DB_USER = os.environ.get('PG_DB_USER') or 'todoozle'
    DB_PASS = os.environ.get('PG_DB_PASS') or 'toor'
    DB_HOST = os.environ.get('PG_DB_HOST') or 'localhost'
    DB_PORT = os.environ.get('PG_DB_PORT') or '5432'
    DB_NAME = os.environ.get('PG_DB_NAME') or 'todoozle'
    SQLALCHEMY_DATABASE_URI = "postgresql://{}:{}@{}:{}/{}".format(
        DB_USER, DB_PASS, DB_HOST, DB_PORT, DB_NAME
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False