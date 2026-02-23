"""Tests for tasks API."""

import pytest
from app import create_app


@pytest.fixture
def client():
    """Create test client."""
    app = create_app()
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


def test_health_check(client):
    """Test health check endpoint."""
    response = client.get('/api/health')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'ok'


def test_get_tasks(client):
    """Test getting all tasks."""
    response = client.get('/api/tasks')
    assert response.status_code == 200
    data = response.get_json()
    assert isinstance(data, list)


def test_get_task_by_id(client):
    """Test getting task by ID."""
    response = client.get('/api/tasks/1')
    assert response.status_code == 200
    data = response.get_json()
    assert data['id'] == 1


def test_get_task_not_found(client):
    """Test getting non-existent task returns 404."""
    response = client.get('/api/tasks/999')
    assert response.status_code == 404


def test_toggle_task(client):
    """Test toggling task completion."""
    # First check initial state
    response = client.get('/api/tasks/1')
    initial_completed = response.get_json()['completed']
    
    # Toggle
    response = client.patch('/api/tasks/1/toggle')
    assert response.status_code == 200
    data = response.get_json()
    assert data['completed'] != initial_completed
