"""API routes."""

from flask import Blueprint, jsonify, request

# BUG #2: This import will work but we have a subtle bug
from app.models import USERS, TASKS, get_user_by_id, get_task_by_id
from app.utils import validate_email

bp = Blueprint('api', __name__, url_prefix='/api')


@bp.route('/health')
def health_check():
    """Health check endpoint."""
    return jsonify({'status': 'ok'})


@bp.route('/users')
def get_users():
    """Get all users."""
    return jsonify([user.to_dict() for user in USERS])


@bp.route('/users/<int:user_id>')
def get_user(user_id):
    """Get user by ID."""
    user = get_user_by_id(user_id)
    # BUG #4: No null check - will crash if user not found
    return jsonify(user.to_dict())


@bp.route('/users', methods=['POST'])
def create_user():
    """Create a new user."""
    data = request.get_json()
    
    if not data or 'name' not in data or 'email' not in data:
        return jsonify({'error': 'Name and email required'}), 400
    
    # BUG #6: validate_email expects different signature
    if not validate_email(data['email'], strict=True):
        return jsonify({'error': 'Invalid email'}), 400
    
    from app.models import User
    new_user = User(
        id=len(USERS) + 1,
        name=data['name'],
        email=data['email']
    )
    USERS.append(new_user)
    
    return jsonify(new_user.to_dict()), 201


@bp.route('/tasks')
def get_tasks():
    """Get all tasks."""
    return jsonify([task.to_dict() for task in TASKS])


@bp.route('/tasks/<int:task_id>')
def get_task(task_id):
    """Get task by ID."""
    task = get_task_by_id(task_id)
    if task is None:
        return jsonify({'error': 'Task not found'}), 404
    return jsonify(task.to_dict())


@bp.route('/tasks/<int:task_id>/toggle', methods=['PATCH'])
def toggle_task(task_id):
    """Toggle task completion."""
    task = get_task_by_id(task_id)
    if task is None:
        return jsonify({'error': 'Task not found'}), 404
    task.toggle_complete()
    return jsonify(task.to_dict())


# FIXED VERSION for get_user:
# @bp.route('/users/<int:user_id>')
# def get_user(user_id):
#     user = get_user_by_id(user_id)
#     if user is None:
#         return jsonify({'error': 'User not found'}), 404
#     return jsonify(user.to_dict())
