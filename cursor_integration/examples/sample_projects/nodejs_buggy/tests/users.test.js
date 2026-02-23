// Tests for users API
// These tests will fail until bugs are fixed

const request = require('supertest');
const app = require('../src/app');

describe('Users API', () => {
  test('GET /api/users returns all users', async () => {
    const response = await request(app).get('/api/users');
    expect(response.status).toBe(200);
    expect(Array.isArray(response.body)).toBe(true);
  });

  test('GET /api/users/:id returns 404 for non-existent user', async () => {
    const response = await request(app).get('/api/users/999');
    // BUG: Currently crashes instead of returning 404
    expect(response.status).toBe(404);
    expect(response.body.error).toBe('User not found');
  });

  test('POST /api/users creates a new user', async () => {
    const response = await request(app)
      .post('/api/users')
      .send({ name: 'Charlie', email: 'charlie@example.com' });
    expect(response.status).toBe(201);
    expect(response.body.name).toBe('Charlie');
  });
});
