// realtime.js (Web App)
const socket = io("http://localhost:5000");  // Połączenie z Desktop App

socket.on("connect", () => {
  console.log("Połączono z Desktop App!");
  socket.emit("request_sync");  // Żądanie synchronizacji
});

socket.on("realtime_update", (data) => {
  // Aktualizuj interfejs w czasie rzeczywistym
  document.getElementById("cpu-usage").textContent = `${data.cpu_usage}%`;
  document.getElementById("ram-usage").textContent = `${data.ram_usage} GB`;

  // Aktualizuj listę zadań
  const tasksList = document.getElementById("tasks-list");
  tasksList.innerHTML = data.tasks.map(task =>
    `<li>${task.id}: ${task.status}</li>`
  ).join("");
});

socket.on("sync_status", (status) => {
  console.log("Status synchronizacji:", status.status);
});