from flask import render_template, flash, redirect, url_for
from app import app, db
from app.forms import NewItemForm
from app.models import TodoItem

@app.route('/')
@app.route('/index')
def index():
    items = TodoItem.query.all()
    return render_template('index.html', items=items)

@app.route('/new_item', methods=['GET', 'POST'])
def new_item():
    form = NewItemForm()
    if form.validate_on_submit():
        flash('Created item {}'.format(form.task.data))
        # TODO: sanitize
        ti = TodoItem(task=form.task.data)
        # TODO: Add error handling
        db.session.add(ti)
        db.session.commit()
        return redirect(url_for('index'))
    return render_template('new_item.html', title='New Item', form=form)
