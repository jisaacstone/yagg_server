export function dropdown(key, text) {
    const lsKey = `dropdown.${key}`;
    if (localStorage.getItem(lsKey)) {
        return;
    }
    displayDropdown(lsKey, text);
}
function displayDropdown(lsKey, text) {
    const tableEl = document.getElementById('table'), existing = document.getElementsByClassName('dropdown'), dropdownEl = document.createElement('div'), dropdownText = document.createElement('div'), dismiss = document.createElement('button');
    Array.prototype.forEach.call(existing, (el) => el.remove());
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
    };
}
