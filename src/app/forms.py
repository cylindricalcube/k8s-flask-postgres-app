from flask_wtf import FlaskForm
from wtforms import StringField, SubmitField
from wtforms.validators import DataRequired

class NewItemForm(FlaskForm):
    task = StringField('Item', validators=[DataRequired()])
    submit = SubmitField('Create')