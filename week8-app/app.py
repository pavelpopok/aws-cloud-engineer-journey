import os

import mysql.connector
from flask import Flask, jsonify

app = Flask(__name__)


def get_db_connection():
    return mysql.connector.connect(
        host=os.environ.get("DB_HOST", "localhost"),
        user=os.environ.get("DB_USER", "root"),
        password=os.environ.get("DB_PASSWORD", ""),
        database=os.environ.get("DB_NAME", "week8db"),
        connection_timeout=5,
    )


@app.route("/")
def home():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT VERSION()")
        version = cursor.fetchone()[0]
        cursor.close()
        conn.close()
        return jsonify(
            {
                "status": "connected",
                "message": "FLASK connected to RDS via Secrets Manager — CI/CD working?!",
                "db_version": version,
                "container": os.environ.get("HOSTNAME", "unknown"),
            }
        )
    except Exception as e:
        return jsonify(
            {
                "status": "error",
                "message": str(e),
                "container": os.environ.get("HOSTNAME", "unknown"),
            }
        ), 500


@app.route("/api/health")
def health():
    return jsonify({"status": "healthy"}), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
