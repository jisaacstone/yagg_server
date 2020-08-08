import { gameaction } from './request.js';
import { displayerror } from './err.js';

export function display(label = 'READY') {
  const readyButton = document.createElement('button');
  readyButton.id = 'readybutton';
  readyButton.innerHTML = label;
  readyButton.onclick = () => {
    gameaction('ready', {}, 'board').then(() => {
      readyButton.remove();
    }).catch(({ request }) => {
      if (request.status === 400 && request.responseText.includes('notready')) {
        displayerror('place your monarch first');
      }
    });
  };
  document.getElementById('player').appendChild(readyButton);
}

export function hide() {
  const readyButton = document.getElementById('readybutton');
  if (readyButton) {
    readyButton.remove();
  }
}
