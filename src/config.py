import os

class Config(object):
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'super-s3cure-pla!nt3xt-s3cret'
    SQLALCHEMY_DATABASE_URI = os.environ.get('PG_DATABASE_URL') or 'localhost'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    # DATABASE_PORT = os.environ.get('PG_DATABASE_PORT') or '5432'