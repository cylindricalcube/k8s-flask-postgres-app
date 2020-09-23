from flask import render_template, flash, redirect, url_for
from app import app
from app.forms import NewListForm

@app.route('/')
@app.route('/index')
def index():
    lists = [
        { 'id': 1, 'name': 'Shopping' },
        { 'id': 2, 'name': 'Groceries' }
    ]
    return render_template('index.html', lists=lists)

@app.route('/new_list', methods=['GET', 'POST'])
def new_list():
    form = NewListForm()
    if form.validate_on_submit():
        flash('Created list {}'.format(form.name.data))
        return redirect(url_for('index'))
    return render_template('new_list.html', title='New List', form=form)
