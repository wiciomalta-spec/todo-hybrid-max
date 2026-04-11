"""
To-Do Hybrid MAX - Desktop Edition
Python 3.8+ with PyQt5
"""

import sys
import json
import sqlite3
from datetime import datetime
from pathlib import Path
from PyQt5.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QLineEdit, QPushButton, QListWidget, QListWidgetItem, QLabel,
    QCheckBox, QComboBox, QMessageBox, QFileDialog
)
from PyQt5.QtCore import Qt, QTimer, pyqtSignal
from PyQt5.QtGui import QColor, QFont
from flask import Flask, request, jsonify
import threading

# Database setup
class TodoDatabase:
    def __init__(self, db_path='todos.db'):
        self.db_path = db_path
        self.init_db()
    
    def init_db(self):
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS todos (
                id INTEGER PRIMARY KEY,
                text TEXT NOT NULL,
                completed BOOLEAN DEFAULT 0,
                created TEXT,
                updated TEXT
            )
        ''')
        conn.commit()
        conn.close()
    
    def get_all(self):
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        cursor.execute('SELECT id, text, completed, created, updated FROM todos')
        tasks = cursor.fetchall()
        conn.close()
        return tasks
    
    def add(self, text):
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        now = datetime.now().isoformat()
        cursor.execute(
            'INSERT INTO todos (text, completed, created, updated) VALUES (?, ?, ?, ?)',
            (text, 0, now, now)
        )
        conn.commit()
        conn.close()
        return cursor.lastrowid
    
    def delete(self, task_id):
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        cursor.execute('DELETE FROM todos WHERE id = ?', (task_id,))
        conn.commit()
        conn.close()
    
    def toggle(self, task_id):
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        cursor.execute(
            'UPDATE todos SET completed = NOT completed, updated = ? WHERE id = ?',
            (datetime.now().isoformat(), task_id)
        )
        conn.commit()
        conn.close()
    
    def clear_completed(self):
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        cursor.execute('DELETE FROM todos WHERE completed = 1')
        conn.commit()
        conn.close()

# Flask API for Sync
app = Flask(__name__)
db = None

@app.route('/sync', methods=['POST'])
def sync():
    data = request.json
    if data.get('tasks'):
        # Import tasks from Web
        for task in data['tasks']:
            try:
                db.add(task['text'])
            except:
                pass
    
    # Return all tasks
    tasks = db.get_all()
    return jsonify({
        'tasks': [
            {
                'id': t[0],
                'text': t[1],
                'completed': bool(t[2]),
                'created': t[3],
                'updated': t[4]
            } for t in tasks
        ]
    })

@app.route('/sync', methods=['GET'])
def get_tasks():
    tasks = db.get_all()
    return jsonify({
        'tasks': [
            {
                'id': t[0],
                'text': t[1],
                'completed': bool(t[2]),
                'created': t[3],
                'updated': t[4]
            } for t in tasks
        ]
    })

# Main GUI Application
class TodoApp(QMainWindow):
    def __init__(self):
        super().__init__()
        self.db = TodoDatabase()
        self.init_ui()
        self.load_tasks()
        self.start_sync_server()
    
    def init_ui(self):
        self.setWindowTitle('📝 To-Do Hybrid MAX - Desktop Edition v1.0')
        self.setGeometry(100, 100, 600, 700)
        
        # Main widget
        main_widget = QWidget()
        self.setCentralWidget(main_widget)
        layout = QVBoxLayout()
        
        # Title
        title = QLabel('To-Do Hybrid MAX')
        title_font = QFont()
        title_font.setPointSize(16)
        title_font.setBold(True)
        title.setFont(title_font)
        layout.addWidget(title)
        
        # Input section
        input_layout = QHBoxLayout()
        self.input_field = QLineEdit()
        self.input_field.setPlaceholderText('Dodaj nowe zadanie...')
        self.input_field.returnPressed.connect(self.add_task)
        input_layout.addWidget(self.input_field)
        
        add_btn = QPushButton('➕ Dodaj')
        add_btn.clicked.connect(self.add_task)
        input_layout.addWidget(add_btn)
        
        layout.addLayout(input_layout)
        
        # Filter section
        filter_layout = QHBoxLayout()
        self.filter_combo = QComboBox()
        self.filter_combo.addItems(['Wszystkie', 'Aktywne', 'Ukończone'])
        self.filter_combo.currentTextChanged.connect(self.load_tasks)
        filter_layout.addWidget(QLabel('Filtr:'))
        filter_layout.addWidget(self.filter_combo)
        filter_layout.addStretch()
        
        layout.addLayout(filter_layout)
        
        # Task list
        self.task_list = QListWidget()
        layout.addWidget(self.task_list)
        
        # Stats
        stats_layout = QHBoxLayout()
        self.task_count = QLabel('Zadań: 0')
        stats_layout.addWidget(self.task_count)
        stats_layout.addStretch()
        
        clear_btn = QPushButton('🗑️ Wyczyść')
        clear_btn.clicked.connect(self.clear_completed)
        stats_layout.addWidget(clear_btn)
        
        sync_btn = QPushButton('🔄 Sync Web')
        sync_btn.clicked.connect(self.sync_with_web)
        stats_layout.addWidget(sync_btn)
        
        layout.addLayout(stats_layout)
        
        # Sync status
        self.sync_status = QLabel('Status: Gotowy')
        layout.addWidget(self.sync_status)
        
        main_widget.setLayout(layout)
    
    def load_tasks(self):
        self.task_list.clear()
        tasks = self.db.get_all()
        
        filter_text = self.filter_combo.currentText()
        
        for task_id, text, completed, created, updated in tasks:
            if filter_text == 'Aktywne' and completed:
                continue
            if filter_text == 'Ukończone' and not completed:
                continue
            
            self.add_list_item(task_id, text, completed)
        
        self.task_count.setText(f'Zadań: {len(tasks)}')
    
    def add_list_item(self, task_id, text, completed):
        item = QListWidgetItem()
        
        # Create checkbox
        checkbox = QCheckBox(text)
        checkbox.setChecked(completed)
        checkbox.stateChanged.connect(lambda: self.toggle_task(task_id))
        
        if completed:
            checkbox.setStyleSheet("text-decoration: line-through; color: gray;")
        
        item.setSizeHint(checkbox.sizeHint())
        self.task_list.addItem(item)
        self.task_list.setItemWidget(item, checkbox)
    
    def add_task(self):
        text = self.input_field.text().strip()
        if not text:
            QMessageBox.warning(self, 'Błąd', 'Wpisz zadanie!')
            return
        
        self.db.add(text)
        self.input_field.clear()
        self.load_tasks()
    
    def toggle_task(self, task_id):
        self.db.toggle(task_id)
        self.load_tasks()
    
    def clear_completed(self):
        reply = QMessageBox.question(
            self, 'Potwierdzenie',
            'Usunąć wszystkie ukończone zadania?',
            QMessageBox.Yes | QMessageBox.No
        )
        if reply == QMessageBox.Yes:
            self.db.clear_completed()
            self.load_tasks()
    
    def sync_with_web(self):
        self.sync_status.setText('Status: Synchronizowanie...')
        QApplication.processEvents()
        
        try:
            import requests
            response = requests.get('http://localhost:5000/sync')
            if response.status_code == 200:
                self.sync_status.setText('Status: ✅ Synchronizacja udana')
                self.load_tasks()
            else:
                self.sync_status.setText('Status: ⚠️ Błąd synchronizacji')
        except:
            self.sync_status.setText('Status: ⚠️ Web app niedostępna')
    
    def start_sync_server(self):
        global db
        db = self.db
        
        def run_server():
            app.run(host='localhost', port=5000, debug=False)
        
        server_thread = threading.Thread(target=run_server, daemon=True)
        server_thread.start()

if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = TodoApp()
    window.show()
    sys.exit(app.exec_())
