// Tests for tasks API
// These tests will fail until bugs are fixed

const request = require('supertest');
const app = require('../src/app');

describe('Tasks API', () => {
  test('GET /api/tasks returns all tasks', async () => {
    const response = await request(app).get('/api/tasks');
    expect(response.status).toBe(200);
    expect(Array.isArray(response.body)).toBe(true);
  });

  test('POST /api/tasks with valid title creates task', async () => {
    const response = await request(app)
      .post('/api/tasks')
      .send({ title: 'New Task' });
    expect(response.status).toBe(201);
    expect(response.body.title).toBe('New Task');
  });

  test('POST /api/tasks with empty title returns 400', async () => {
    const response = await request(app)
      .post('/api/tasks')
      .send({ title: '' });
    expect(response.status).toBe(400);
  });

  test('PATCH /api/tasks/:id/toggle toggles completion', async () => {
    const response = await request(app)
      .patch('/api/tasks/1/toggle');
    expect(response.status).toBe(200);
    expect(response.body.completed).toBe(true);
  });
});
