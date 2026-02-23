// BUG #2: Syntax error - missing closing parenthesis
// The orchestrator should detect and fix this

const express = require('express');
const usersRouter = require('./routes/users');
const tasksRouter = require('./routes/tasks');

const app = express();

app.use(express.json();

// Routes
app.use('/api/users', usersRouter);
app.use('/api/tasks', tasksRouter);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

module.exports = app;

/* FIXED VERSION:
app.use(express.json());
*/
