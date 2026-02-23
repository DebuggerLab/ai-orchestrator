// BUG #4: Import error - wrong path
// The orchestrator should detect the incorrect import

const express = require('express');
const router = express.Router();
// BUG: This path doesn't exist
const { validateTask } = require('../utilities/validator');

// Mock database
const tasks = [
  { id: 1, title: 'Learn Node.js', completed: false },
  { id: 2, title: 'Build API', completed: false }
];

// Get all tasks
router.get('/', (req, res) => {
  res.json(tasks);
});

// Get task by ID
router.get('/:id', (req, res) => {
  const task = tasks.find(t => t.id === parseInt(req.params.id));
  if (!task) {
    return res.status(404).json({ error: 'Task not found' });
  }
  res.json(task);
});

// Create task
router.post('/', (req, res) => {
  const { title } = req.body;
  
  // Validate input
  const validation = validateTask({ title });
  if (!validation.valid) {
    return res.status(400).json({ error: validation.error });
  }
  
  const newTask = {
    id: tasks.length + 1,
    title,
    completed: false
  };
  tasks.push(newTask);
  res.status(201).json(newTask);
});

// Toggle task completion
router.patch('/:id/toggle', (req, res) => {
  const task = tasks.find(t => t.id === parseInt(req.params.id));
  if (!task) {
    return res.status(404).json({ error: 'Task not found' });
  }
  task.completed = !task.completed;
  res.json(task);
});

module.exports = router;

/* FIXED VERSION:
const { validateTask } = require('../utils/validator');
*/
