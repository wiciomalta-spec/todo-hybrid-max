// sync.js (Web App)
class WebSyncManager {
  constructor(syncFile = "sync.json") {
    this.syncFile = syncFile;
    this.data = { tasks: [], stats: {} };
    this.loadData();
  }

  loadData() {
    // Ładuje dane z LocalStorage
    const savedData = localStorage.getItem("todoData");
    if (savedData) {
      this.data = JSON.parse(savedData);
    }
  }

  saveData() {
    // Zapisuje dane do LocalStorage i sync.json (symulowane przez pobieranie pliku)
    localStorage.setItem("todoData", JSON.stringify(this.data));
    this._simulateSaveToFile();
  }

  _simulateSaveToFile() {
    // W praktyce: użyj FileSystem API lub wysyłaj dane do Desktop App przez WebSocket
    console.log("Zapisano do sync.json (symulacja):", this.data);
    const blob = new Blob([JSON.stringify(this.data, null, 2)], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "sync.json";
    a.click();
  }

  syncWithDesktop() {
    // Symulacja synchronizacji: pobierz sync.json z Desktop App
    fetch("/api/sync")  // Endpoint w Desktop App (Flask)
      .then(response => response.json())
      .then(remoteData => {
        if (remoteData.metadata.timestamp > this.data.stats.last_sync) {
          this.data = remoteData;
          this.saveData();
          alert("Zsynchronizowano z Desktop App!");
        }
      });
  }
}