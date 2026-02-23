"""Utility functions."""

import re


def validate_email(email):
    """Validate email format.
    
    BUG #6: Function signature doesn't match usage in routes.py
    The routes.py calls validate_email(email, strict=True)
    but this function doesn't accept 'strict' parameter
    """
    if not email:
        return False
    
    # Simple email regex
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return bool(re.match(pattern, email))


def sanitize_string(text):
    """Sanitize input string."""
    if text is None:
        return ''
    return text.strip()


# FIXED VERSION:
# def validate_email(email, strict=False):
#     """Validate email format.
#     
#     Args:
#         email: Email address to validate
#         strict: If True, apply stricter validation
#     """
#     if not email:
#         return False
#     
#     if strict:
#         # Stricter pattern
#         pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
#     else:
#         # Basic pattern
#         pattern = r'^[^@]+@[^@]+\.[^@]+$'
#     
#     return bool(re.match(pattern, email))
