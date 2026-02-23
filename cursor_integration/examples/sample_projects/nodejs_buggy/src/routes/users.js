// BUG #3: Runtime error - accessing property of undefined
// The orchestrator should detect null reference and add checks

const express = require('express');
const router = express.Router();

// Mock database
const users = [
  { id: 1, name: 'Alice', email: 'alice@example.com' },
  { id: 2, name: 'Bob', email: 'bob@example.com' }
];

// Get all users
router.get('/', (req, res) => {
  res.json(users);
});

// Get user by ID - BUG: No null check
router.get('/:id', (req, res) => {
  const user = users.find(u => u.id === parseInt(req.params.id));
  // BUG: This will fail if user is not found
  res.json({
    id: user.id,
    name: user.name,
    email: user.email
  });
});

// Create user
router.post('/', (req, res) => {
  const { name, email } = req.body;
  const newUser = {
    id: users.length + 1,
    name,
    email
  };
  users.push(newUser);
  res.status(201).json(newUser);
});

module.exports = router;

/* FIXED VERSION:
router.get('/:id', (req, res) => {
  const user = users.find(u => u.id === parseInt(req.params.id));
  if (!user) {
    return res.status(404).json({ error: 'User not found' });
  }
  res.json({
    id: user.id,
    name: user.name,
    email: user.email
  });
});
*/
