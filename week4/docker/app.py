from flask import Flask, jsonify
import os
import socket
from datetime import datetime

app = Flask(__name__)

# Read environment variable with default value
APP_NAME = os.getenv('APP_NAME', 'Flask Docker App')
ENVIRONMENT = os.getenv('ENVIRONMENT', 'development')

visit_count = 0

@app.route('/')
def home():
    global visit_count
    visit_count += 1

    return f'''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>{APP_NAME}</title>
        <style>
            body {{
                font-family: Arial, sans-serif;
                max-width: 900px;
                margin: 50px auto;
                padding: 30px;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                border-radius: 10px;
            }}
            .env-badge {{
                display: inline-block;
                padding: 5px 15px;
                background: {'#28a745' if ENVIRONMENT == 'production' else '#ffc107'};
                border-radius: 20px;
                font-weight: bold;
            }}
        </style>
    </head>
    <body>
        <h1>🐍 {APP_NAME}</h1>
        <p>Environment: <span class="env-badge">{ENVIRONMENT}</span></p>
        <p>Container: <code>{socket.gethostname()}</code></p>
        <p>Visits: <strong>{visit_count}</strong></p>
    </body>
    </html>
    '''

@app.route('/api/info')
def info():
    return jsonify({
        'app_name': APP_NAME,
        'environment': ENVIRONMENT,
        'container_id': socket.gethostname(),
        'visits': visit_count
    })
@app.route('/api/health')
def health():
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat()
    }), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
