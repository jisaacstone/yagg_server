import { gameaction } from './request.js';
import { displayerror } from './err.js';
export function display(label = 'READY', onclick = null) {
    const readyButton = document.createElement('button');
    readyButton.id = 'readybutton';
    readyButton.className = 'uibutton';
    readyButton.innerHTML = label;
    if (onclick !== null) {
        readyButton.onclick = onclick;
    }
    else {
        readyButton.onclick = () => {
            document.getElementById('infobox').innerHTML = '';
            gameaction('ready', {}, 'board').then(() => {
                readyButton.remove();
            }).catch(({ request }) => {
                if (request.status === 400 && request.responseText.includes('notready')) {
                    displayerror('place your monarch first');
                }
            });
        };
    }
    document.getElementById('buttons').appendChild(readyButton);
}
export function ensureDisplayed(label = 'READY', onclick = null) {
    if (!document.getElementById('readybutton')) {
        display(label, onclick);
    }
}
export function hide() {
    const readyButton = document.getElementById('readybutton');
    if (readyButton) {
        readyButton.remove();
    }
}
