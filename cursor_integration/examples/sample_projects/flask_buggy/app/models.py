"""Database models."""

from datetime import datetime


class User:
    """User model."""
    
    def __init__(self, id, name, email):
        self.id = id
        self.name = name
        self.email = email
        self.created_at = datetime.utcnow()
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'email': self.email,
            'created_at': self.created_at.isoformat()
        }


class Task:
    """Task model."""
    
    # BUG #3: Indentation error
    def __init__(self, id, title, user_id):
        self.id = id
        self.title = title
        self.user_id = user_id
        self.completed = False
       self.created_at = datetime.utcnow()  # Wrong indentation!
    
    def to_dict(self):
        return {
            'id': self.id,
            'title': self.title,
            'user_id': self.user_id,
            'completed': self.completed,
            'created_at': self.created_at.isoformat()
        }
    
    def toggle_complete(self):
        self.completed = not self.completed


# Mock database
USERS = [
    User(1, 'Alice', 'alice@example.com'),
    User(2, 'Bob', 'bob@example.com')
]

TASKS = [
    Task(1, 'Learn Flask', 1),
    Task(2, 'Build API', 1)
]


def get_user_by_id(user_id):
    """Get user by ID."""
    for user in USERS:
        if user.id == user_id:
            return user
    return None


def get_task_by_id(task_id):
    """Get task by ID."""
    for task in TASKS:
        if task.id == task_id:
            return task
    return None


# FIXED VERSION:
#     def __init__(self, id, title, user_id):
#         self.id = id
#         self.title = title
#         self.user_id = user_id
#         self.completed = False
#         self.created_at = datetime.utcnow()  # Fixed indentation
