function renderTask(task) {
  const li = document.createElement("li");
  li.className = "task-item" + (task.completed ? " completed" : "");

  const label = document.createElement("label");
  const checkbox = document.createElement("input");
  checkbox.type = "checkbox";
  checkbox.checked = task.completed;

  const span = document.createElement("span");
  span.className = "task-text" + (task.completed ? " completed" : "");
  span.textContent = task.text;

  const removeBtn = document.createElement("button");
  removeBtn.className = "task-remove";
  removeBtn.textContent = "✕";

  // ...eventy itd.

  label.appendChild(checkbox);
  label.appendChild(span);
  li.appendChild(label);
  li.appendChild(removeBtn);

  return li;
}
