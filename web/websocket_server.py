# websocket_server.py
from flask import Flask, render_template
from flask_socketio import SocketIO, emit
import json
import threading
import time

app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins="*")

@app.route("/")
def index():
    return render_template("web/index.html")

@socketio.on("connect")
def handle_connect():
    print("Web App połączony!")
    emit("sync_status", {"status": "connected"})

@socketio.on("request_sync")
def handle_sync_request():
    # Symulacja: co 1s wysyłaj aktualizację
    def background_sync():
        while True:
            time.sleep(1)
            mock_data = {
                "cpu_usage": 45,
                "ram_usage": 12.7,
                "tasks": [{"id": "task_1", "status": "in_progress"}]
            }
            socketio.emit("realtime_update", mock_data)
    threading.Thread(target=background_sync).start()

if __name__ == "__main__":
    socketio.run(app, port=5000)