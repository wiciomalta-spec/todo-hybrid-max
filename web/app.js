// Main Application Logic
class TodoApp {
    constructor() {
        this.currentFilter = 'all';
        this.init();
    }

    init() {
        this.cacheElements();
        this.bindEvents();
        this.render();
        this.updateLastSync();
    }

    cacheElements() {
        this.taskInput = document.getElementById('taskInput');
        this.addBtn = document.getElementById('addBtn');
        this.syncBtn = document.getElementById('syncBtn');
        this.taskList = document.getElementById('taskList');
        this.taskCount = document.getElementById('taskCount');
        this.clearBtn = document.getElementById('clearBtn');
        this.filterBtns = document.querySelectorAll('.filter-btn');
    }

    bindEvents() {
        this.addBtn.addEventListener('click', () => this.addTask());
        this.taskInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') this.addTask();
        });
        this.syncBtn.addEventListener('click', () => this.sync());
        this.clearBtn.addEventListener('click', () => this.clearCompleted());
        
        this.filterBtns.forEach(btn => {
            btn.addEventListener('click', (e) => this.setFilter(e.target.dataset.filter));
        });
    }

    addTask() {
        const text = this.taskInput.value.trim();
        if (text === '') {
            alert('Wpisz zadanie!');
            return;
        }
        
        storage.addTask(text);
        this.taskInput.value = '';
        this.render();
    }

    deleteTask(id) {
        storage.deleteTask(id);
        this.render();
    }

    toggleTask(id) {
        storage.toggleTask(id);
        this.render();
    }

    clearCompleted() {
        if (confirm('Usunąć wszystkie ukończone zadania?')) {
            storage.clearCompleted();
            this.render();
        }
    }

    setFilter(filter) {
        this.currentFilter = filter;
        this.filterBtns.forEach(btn => btn.classList.remove('active'));
        event.target.classList.add('active');
        this.render();
    }

    getFilteredTasks() {
        const tasks = storage.getTasks();
        
        switch(this.currentFilter) {
            case 'active':
                return tasks.filter(t => !t.completed);
            case 'completed':
                return tasks.filter(t => t.completed);
            default:
                return tasks;
        }
    }

    render() {
        const tasks = this.getFilteredTasks();
        
        this.taskList.innerHTML = tasks.map(task => 
            <div class="task-item ">
                <input 
                    type="checkbox" 
                    class="task-checkbox"
                    
                    onchange="app.toggleTask()"
                >
                <span class="task-text"></span>
                <button class="task-delete" onclick="app.deleteTask()">Usuń</button>
            </div>
        ).join('');

        const totalTasks = storage.getTasks().length;
        this.taskCount.textContent = \Zadań: \\;
    }

    async sync() {
        await syncManager.syncWithDesktop();
        this.render();
    }

    updateLastSync() {
        document.getElementById('lastSync').textContent = 
            'Ostatnia sync: ' + storage.getLastSync();
    }

    escapeHtml(text) {
        const map = {
            '&': '&amp;',
            '<': '&lt;',
            '>': '&gt;',
            '"': '&quot;',
            "'": '&#039;'
        };
        return text.replace(/[&<>\"']/g, m => map[m]);
    }
}

const app = new TodoApp();
