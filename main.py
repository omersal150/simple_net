from flask import Flask, request, jsonify
import psycopg2
from psycopg2 import sql

app = Flask(__name__)

# Database connection configuration
DB_NAME = "your_db_name"
DB_USER = "your_db_user"
DB_PASSWORD = "your_db_password"
DB_HOST = "your_db_host"
DB_PORT = "your_db_port"

# Function to connect to the PostgreSQL database
def connect_db():
    try:
        conn = psycopg2.connect(
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            host=DB_HOST,
            port=DB_PORT
        )
        return conn
    except psycopg2.Error as e:
        print("Unable to connect to the database:", e)

# API endpoint to store data
@app.route('/store_data', methods=['POST'])
def store_data():
    try:
        conn = connect_db()
        cur = conn.cursor()
        data = request.json

        name = data['name']
        value = data['value']
        time = data['time']

        # Insert data into the database
        cur.execute(sql.SQL("INSERT INTO your_table (name, value, time) VALUES (%s, %s, %s)"), (name, value, time))
        conn.commit()
        cur.close()
        conn.close()

        return jsonify({'message': 'Data stored successfully'}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

# API endpoint to retrieve data
@app.route('/get_data', methods=['GET'])
def get_data():
    try:
        conn = connect_db()
        cur = conn.cursor()

        cur.execute("SELECT * FROM your_table")
        rows = cur.fetchall()

        data = [{'name': row[0], 'value': row[1], 'time': str(row[2])} for row in rows]

        cur.close()
        conn.close()

        return jsonify(data), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
