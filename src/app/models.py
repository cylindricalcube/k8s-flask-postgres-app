from app import db

class TodoList(db.Model):
    __tablename__ = 'todolist'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(120), index=True, unique=True)
    items = db.relationship("TodoItem")
    def __repr__(self):
        return '<TodoList {}>'.format(self.name)

class TodoItem(db.Model):
    __tablename__ = 'todoitem'
    id = db.Column(db.Integer, primary_key=True)
    list_id = db.Column(db.Integer, db.ForeignKey('todolist.id'))
    item = db.Column(db.String(256))
    done = db.Column(db.Boolean)

    def __repr__(self):
        return '<TodoItem {}>'.format(self.item)

