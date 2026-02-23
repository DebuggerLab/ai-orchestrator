"""Flask application factory."""

import os
from flask import Flask

def create_app():
    """Create and configure the Flask application."""
    app = Flask(__name__)
    
    # Configuration
    app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev')
    app.config['DATABASE_URL'] = os.environ.get('DATABASE_URL')
    
    # BUG: No check if DATABASE_URL is set
    if not app.config['DATABASE_URL']:
        # This should use a default but currently raises error later
        pass
    
    # Register routes
    from app.routes import bp
    app.register_blueprint(bp)
    
    return app


# FIXED VERSION:
# def create_app():
#     app = Flask(__name__)
#     app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev')
#     app.config['DATABASE_URL'] = os.environ.get('DATABASE_URL', 'sqlite:///app.db')
#     from app.routes import bp
#     app.register_blueprint(bp)
#     return app
