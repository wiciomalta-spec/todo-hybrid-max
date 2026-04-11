// Sync Manager dla Web <-> Desktop
class SyncManager {
    constructor() {
        this.syncUrl = 'http://localhost:5000/sync';
        this.isOnline = navigator.onLine;
        window.addEventListener('online', () => this.isOnline = true);
        window.addEventListener('offline', () => this.isOnline = false);
    }

    // Synchronizuj z Desktop aplikacją
    async syncWithDesktop() {
        const syncStatus = document.getElementById('syncStatus');
        
        try {
            syncStatus.textContent = 'Status: Synchronizowanie...';
            
            const data = storage.exportData();
            
            const response = await fetch(this.syncUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(data)
            });

            if (response.ok) {
                const result = await response.json();
                
                // Importuj dane z Desktop
                if (result.tasks) {
                    storage.importData(result);
                }
                
                storage.setLastSync();
                syncStatus.textContent = 'Status: ✅ Synchronizacja udana';
                document.getElementById('lastSync').textContent = 
                    'Ostatnia sync: ' + storage.getLastSync();
                
                return true;
            }
        } catch (error) {
            syncStatus.textContent = 'Status: ⚠️ Brak połączenia z Desktop';
            console.log('Desktop app niedostępna - działa w trybie offline');
        }
        
        return false;
    }

    // Pobierz dane z Desktop
    async pullFromDesktop() {
        try {
            const response = await fetch(this.syncUrl);
            if (response.ok) {
                const data = await response.json();
                storage.importData(data);
                return true;
            }
        } catch (error) {
            console.log('Nie można pobrać danych z Desktop');
        }
        return false;
    }
}

const syncManager = new SyncManager();
