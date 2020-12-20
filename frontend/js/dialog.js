import * as Overlay from './overlay.js';
export function displayMessage(message, cls = 'info') {
    const messageEl = document.createElement('div');
    messageEl.innerHTML = message;
    messageEl.className = `message ${cls}`;
    Overlay.dismissable(messageEl);
}
export function prompt(message, defaultv = '', confirm = 'ok') {
    const promptEl = document.createElement('div'), msgEl = document.createElement('div'), inputEl = document.createElement('input'), okEl = document.createElement('button'), clearOverlay = Overlay.clearable(promptEl);
    promptEl.className = 'message prompt';
    msgEl.innerHTML = message;
    promptEl.appendChild(msgEl);
    inputEl.setAttribute('type', 'text');
    inputEl.setAttribute('default', defaultv);
    promptEl.appendChild(inputEl);
    okEl.className = 'uibutton';
    okEl.innerHTML = confirm;
    promptEl.appendChild(okEl);
    return new Promise((resolve) => {
        okEl.onclick = () => {
            const value = inputEl.value;
            if (value) {
                clearOverlay();
                resolve(value);
            }
            else {
                displayMessage('you must enter something!', 'error');
            }
        };
    });
}
export function confirm(message, confirm = 'ok', cancel = 'cancel') {
    const promptEl = document.createElement('div'), msgEl = document.createElement('div'), okEl = document.createElement('button'), cancelEl = document.createElement('button'), clearOverlay = Overlay.clearable(promptEl);
    promptEl.className = 'message confirm';
    msgEl.innerHTML = message;
    promptEl.appendChild(msgEl);
    okEl.className = 'uibutton';
    okEl.innerHTML = confirm;
    promptEl.appendChild(okEl);
    cancelEl.className = 'uibutton';
    cancelEl.innerHTML = cancel;
    promptEl.appendChild(cancelEl);
    return new Promise((resolve) => {
        okEl.onclick = () => {
            clearOverlay();
            resolve(true);
        };
        cancelEl.onclick = () => {
            clearOverlay();
            resolve(false);
        };
    });
}
