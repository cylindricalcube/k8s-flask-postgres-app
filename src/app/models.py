from app import db


class TodoItem(db.Model):
    __tablename__ = 'todoitem'
    id = db.Column(db.Integer, primary_key=True)
    task = db.Column(db.String(256))

    def __repr__(self):
        return '<TodoItem {}>'.format(self.item)

