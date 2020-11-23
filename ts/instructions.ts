export function dropdown(key: string, text: string) {
  const lsKey = `dropdown.${key}`;
  if (localStorage.getItem(lsKey)) {
    return;
  }
  displayDropdown(lsKey, text);
}

export function clear() {
  const existing = document.getElementsByClassName('dropdown');
  Array.prototype.forEach.call(existing, (el) => el.remove());
}

function displayDropdown(lsKey: string, text: string) {
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
    localStorage.setItem(lsKey, 'dismissed');
    dropdownEl.remove();
  }
}
