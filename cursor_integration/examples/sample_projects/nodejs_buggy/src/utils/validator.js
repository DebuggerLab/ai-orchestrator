// BUG #5: Type error in function
// The function expects a string but returns wrong type

function validateTask(task) {
  // BUG: task might be undefined
  if (!task.title || task.title.trim() === '') {
    return { valid: false, error: 'Title is required' };
  }
  
  if (task.title.length < 3) {
    return { valid: false, error: 'Title must be at least 3 characters' };
  }
  
  // BUG: Should return object but might return undefined in some paths
  return { valid: true };
}

function validateEmail(email) {
  // BUG: regex is correct but no null check
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

module.exports = {
  validateTask,
  validateEmail
};

/* FIXED VERSION:
function validateTask(task) {
  if (!task) {
    return { valid: false, error: 'Task object is required' };
  }
  
  if (!task.title || task.title.trim() === '') {
    return { valid: false, error: 'Title is required' };
  }
  
  if (task.title.length < 3) {
    return { valid: false, error: 'Title must be at least 3 characters' };
  }
  
  return { valid: true };
}

function validateEmail(email) {
  if (!email) return false;
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}
*/
