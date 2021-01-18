import * as Dialog from './dialog.js';
import * as Element from './element.js';
import * as Request from './request.js';
import * as State from './state.js';
import * as Ready from './ready.js';

export function ensureCreated() {
  clear();
  if (State.gmeta.boardstate === 'jobfair') {
    const leavebutton = Element.create({
      tag: 'button',
      id: 'leavebutton',
      innerHTML: 'leave',
      className: 'uibutton'
    });
    leavebutton.onclick = () => {
      Dialog.choices(
        'You will lose this game. Return to lobby?',
        {
          leave,
          cancel: () => null
        }
      );
    };
    document.getElementById('buttons').appendChild(leavebutton);
  } else if (['battle', 'placement'].includes(State.gmeta.boardstate)) {
    const leavebutton = Element.create({
      tag: 'button',
      id: 'leavebutton',
      innerHTML: 'concede',
      className: 'uibutton',
    });
    leavebutton.onclick = () => {
      Dialog.choices(
        'You will lose this game. Return to lobby or propose rematch?',
        {
          leave,
          rematch,
          cancel: () => null
        }
      );
    }
    document.getElementById('buttons').appendChild(leavebutton);
  } else if (State.gmeta.boardstate === 'gameover') {
    const leavebutton = Element.create({
      tag: 'button',
      id: 'leavebutton',
      innerHTML: 'leave',
      className: 'uibutton'
    });
    leavebutton.onclick = leave;
    document.getElementById('buttons').appendChild(leavebutton);
  }
}

function clear() {
  const existing = document.getElementById('leavebutton');
  if (existing) {
    existing.remove();
  }
}

export function rematch() {
  return Request.gameaction('concede', {}, 'board').then(() => {
    return Request.gameaction('ready', {}, 'board');
  }).then(() => {
    Ready.hide();
  });
}

export function leave() {
  Request.gameaction('leave', {}, 'table').then(() => {
    window.location.href = 'index.html';
  }).catch((e) => {
    console.log({error: e});
    window.location.href = 'index.html';
  });
}
