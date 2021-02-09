import * as Storage from './storage.js';

export function dropdown(key: string, text: string) {
  if (Storage.getItem('dropdown', key)) {
    return;
  }
  displayDropdown(key, text);
}

export function clear() {
  const existing = document.getElementsByClassName('dropdown');
  Array.prototype.forEach.call(existing, (el) => el.remove());
}

function displayDropdown(key: string, text: string) {
  const tableEl = document.getElementById('table'),
    dropdownEl = document.createElement('div'),
    dropdownText = document.createElement('div'),
    dismiss = document.createElement('button');
  dropdownEl.className = 'dropdown';
  dropdownEl.appendChild(dropdownText);
  dropdownEl.appendChild(dismiss);
  dropdownText.innerHTML = text;
  dismiss.innerHTML = 'X';
  dismiss.className = 'dismiss uibutton';
  tableEl.appendChild(dropdownEl);
  dismiss.onclick = () => {
    Storage.setItem('dropdown', key, 'dismissed');
    tableEl.removeChild(dropdownEl);
  }
}
