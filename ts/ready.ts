import { gameaction } from './request.js';
import { displayerror } from './err.js';
import * as SFX from './sfx.js';
import * as Select from './select.js';
import * as Soundtrack from './soundtrack.js';

const state = {
  displayed: false,
  waiting: false,
}

export function display(label = 'ready', onclick = null) {
  const readyButton = document.createElement('button');
  readyButton.id = 'readybutton';
  readyButton.className = `uibutton ${label}-b`;

  readyButton.innerHTML = label;
  readyButton.setAttribute('title', label);
  if (!onclick) {
    onclick = () => {
      gameaction('ready', {}, 'board').then(() => {
        waiting();
      }).catch(({ request }) => {
        if (request.status === 400) {
          if (request.responseText.includes('notready')) {
            displayerror('place your monarch first');
          } else {
            displayerror(request.responseText);
          }
        } else {
          displayerror('unknown error, please try again');
        }
      });
    };
  }
  readyButton.onclick = () => {
    SFX.play('click').then(Soundtrack.play);
    Select.deselect();
    onclick();
  }
  document.getElementById('buttons').appendChild(readyButton);
  state.displayed = true;
}

export function waiting() {
  const readyButton = document.getElementById('readybutton');
  if (readyButton) {
    readyButton.innerHTML = 'waiting';
    readyButton.className = `${readyButton.className} readywaiting`;
    state.waiting = true;
  }
}

export function ensureDisplayed(label='ready', onclick=null) {
  if (! document.getElementById('readybutton')) {
    display(label, onclick);
  }
}

export function hide() {
  const readyButton = document.getElementById('readybutton');
  if (readyButton) {
    readyButton.remove();
    state.displayed = false;
    state.waiting = false;
  }
}

export function hideIfWaiting() {
  if (state.displayed && state.waiting) {
    hide();
  }
}
