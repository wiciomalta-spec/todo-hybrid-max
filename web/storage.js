// LocalStorage Manager
class TodoStorage {
    constructor() {
        this.storageKey = 'todoHybridMax_tasks';
        this.syncKey = 'todoHybridMax_lastSync';
    }

    // Pobierz wszystkie zadania
    getTasks() {
        const data = localStorage.getItem(this.storageKey);
        return data ? JSON.parse(data) : [];
    }

    // Dodaj zadanie
    addTask(text) {
        const tasks = this.getTasks();
        const newTask = {
            id: Date.now(),
            text: text,
            completed: false,
            created: new Date().toISOString(),
            updated: new Date().toISOString()
        };
        tasks.push(newTask);
        localStorage.setItem(this.storageKey, JSON.stringify(tasks));
        return newTask;
    }

    // Usuń zadanie
    deleteTask(id) {
        let tasks = this.getTasks();
        tasks = tasks.filter(task => task.id !== id);
        localStorage.setItem(this.storageKey, JSON.stringify(tasks));
    }

    // Oznacz jako ukończone
    toggleTask(id) {
        const tasks = this.getTasks();
        const task = tasks.find(t => t.id === id);
        if (task) {
            task.completed = !task.completed;
            task.updated = new Date().toISOString();
            localStorage.setItem(this.storageKey, JSON.stringify(tasks));
        }
    }

    // Wyczyść wszystkie zadania
    clearCompleted() {
        let tasks = this.getTasks();
        tasks = tasks.filter(task => !task.completed);
        localStorage.setItem(this.storageKey, JSON.stringify(tasks));
    }

    // Pobierz ostatnią synchronizację
    getLastSync() {
        return localStorage.getItem(this.syncKey) || 'Nigdy';
    }

    // Zapisz czas synchronizacji
    setLastSync() {
        const now = new Date().toLocaleString('pl-PL');
        localStorage.setItem(this.syncKey, now);
    }

    // Eksportuj dane
    exportData() {
        return {
            tasks: this.getTasks(),
            exported: new Date().toISOString(),
            version: '1.0'
        };
    }

    // Importuj dane
    importData(data) {
        if (data.tasks && Array.isArray(data.tasks)) {
            localStorage.setItem(this.storageKey, JSON.stringify(data.tasks));
            return true;
        }
        return false;
    }
}

const storage = new TodoStorage();
