# sync_manager.py
import json
import sqlite3
from datetime import datetime
from pathlib import Path

class SyncManager:
    def __init__(self, db_path="desktop/data.db", sync_file="sync.json"):
        self.db_path = db_path
        self.sync_file = sync_file
        self.conn = sqlite3.connect(db_path)
        self.cursor = self.conn.cursor()

    def load_local_data(self):
        """Ładuje dane z SQLite."""
        self.cursor.execute("SELECT * FROM tasks")
        tasks = [{"id": row[0], "title": row[1], "status": row[2]} for row in self.cursor.fetchall()]
        return {"tasks": tasks, "stats": {"last_sync": datetime.now().isoformat()}}

    def save_local_data(self, data):
        """Zapisuje dane do SQLite."""
        for task in data["tasks"]:
            self.cursor.execute(
                "INSERT OR REPLACE INTO tasks (id, title, status) VALUES (?, ?, ?)",
                (task["id"], task["title"], task["status"])
            )
        self.conn.commit()

    def load_web_data(self):
        """Ładuje dane z sync.json (Web App)."""
        if Path(self.sync_file).exists():
            with open(self.sync_file, "r") as f:
                return json.load(f)
        return None

    def save_web_data(self, data):
        """Zapisuje dane do sync.json (dla Web App)."""
        with open(self.sync_file, "w") as f:
            json.dump(data, f, indent=2)

    def sync(self):
        """Synchronizuje dane między Web App a Desktop App."""
        web_data = self.load_web_data()
        local_data = self.load_local_data()

        if not web_data:
            # Jeśli brak danych z Web App, zapisz lokalne dane do sync.json
            self.save_web_data(local_data)
            return "synced_from_desktop"

        # Porównaj timestampy i rozwiąż konflikty (tu: priorytet dla Web App)
        if web_data["metadata"]["timestamp"] > local_data["stats"]["last_sync"]:
            self.save_local_data(web_data)
            return "synced_from_web"
        else:
            self.save_web_data(local_data)
            return "synced_from_desktop"