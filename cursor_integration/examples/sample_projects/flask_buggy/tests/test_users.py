"""Tests for users API."""

import pytest
from app import create_app


@pytest.fixture
def client():
    """Create test client."""
    app = create_app()
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


def test_get_users(client):
    """Test getting all users."""
    response = client.get('/api/users')
    assert response.status_code == 200
    data = response.get_json()
    assert isinstance(data, list)
    assert len(data) >= 2


def test_get_user_by_id(client):
    """Test getting user by ID."""
    response = client.get('/api/users/1')
    assert response.status_code == 200
    data = response.get_json()
    assert data['id'] == 1
    assert 'name' in data


def test_get_user_not_found(client):
    """Test getting non-existent user returns 404."""
    response = client.get('/api/users/999')
    # BUG: Currently crashes instead of returning 404
    assert response.status_code == 404
    data = response.get_json()
    assert 'error' in data


def test_create_user(client):
    """Test creating a new user."""
    response = client.post('/api/users', json={
        'name': 'Charlie',
        'email': 'charlie@example.com'
    })
    # BUG: Will fail due to validate_email signature mismatch
    assert response.status_code == 201
    data = response.get_json()
    assert data['name'] == 'Charlie'
