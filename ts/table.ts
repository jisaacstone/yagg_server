import { tableid } from './urlvars.js';
import * as State from './state.js';
import { listen } from './eventlistener.js';
import * as Player from './player.js';
import * as Request from './request.js';
import * as Overlay from './overlay.js';
import * as Event from './event.js';
import * as Jobfair from './jobfair.js';
import * as Board from './board.js';
import * as Dialog from './dialog.js';
import * as Element from './element.js';
import * as LeaveButton from './leaveButton.js';
import * as SFX from './sfx.js';
import * as Soundtrack from './soundtrack.js';
import * as Settings from './settings.js';

function renderTable(): void {
  const table = Element.create({
    id: 'table',
    children: [
      Element.create({ id: 'board' }),
      Element.create({ id: 'hand' }),
      Element.create({
        id: 'hud',
        children: [
          Element.create({ id: 'player' }),
          Element.create({ id: 'opponent' }),
          Element.create({ id: 'buttons' }),
        ]
      })
    ]
  });
  document.body.appendChild(table);
}

function renderBoard(board, players: number) {
  if (players !== 2) {
    return;
  }
  Event.game_started(board)();
  if (board.ready) {
    Event.player_ready({player: board.ready})();
  }
  Object.entries(board.grid).forEach(([coor, feature]: [string, any]) => {
    if (feature) {
      const [x, y] = coor.split(',');
      if (feature.kind === 'unit') {
        Event.unit_placed({x, y, ...feature})();
      } else {
        Event.feature({x, y, feature})();
      }
    }
  });
}

function renderJobfair(jobfair) {
  Event.game_started(jobfair)();
}

function render_(boardstate, phase, players) {
  if (!boardstate) {
    console.warn('no state');
    return;
  }
  if (phase === 'jobfair') {
    renderJobfair(boardstate);
  } else if (phase === 'board') {
    renderBoard(boardstate, players)
  }
}

function gamephase(board) {
  if (!board) {
    return null;
  } else if (board.army_size !== undefined) {
    return 'jobfair';
  } else if (board.grid !== undefined) {
    return 'board';
  }
  return null;
}

function waitingforplayers() {
  const waiting = document.createElement('div'),
    copy = document.createElement('button'),
    comp = document.createElement('button'),
    leav = document.createElement('button'),
    over = Overlay.create();

  Soundtrack.setSoundtrack('waiting');

  over.className = over.className + ' waiting';
  waiting.innerHTML = 'waiting for opponent';
  over.appendChild(waiting);

  copy.innerHTML = 'copy join link';
  copy.className = 'linkcopy uibutton';
  copy.onclick = () => {
    const url = new URL(window.location.toString());
    url.searchParams.delete('player');
    if (! navigator.clipboard) {
      Dialog.displayMessage('could not access clipboard, sorry. You can still copy the url and send manually', 'error');
      return;
    }
    navigator.clipboard.writeText(url.toString()).then(() => {
      Dialog.displayMessage('copied!');
    }).catch((e) => {
      console.error(e);
      Dialog.displayMessage('could not access clipboard, sorry. You can still copy the url and send manually', 'error');
    });
  }
  over.appendChild(copy);

  comp.innerHTML = 'play the computer';
  comp.className = 'aibutton uibutton';
  comp.onclick = function() {
    Request.gameaction('ai', {}, 'table').then(() => {
      Overlay.clear();
    });
  }
  over.appendChild(comp);

  leav.innerHTML = 'cancel';
  leav.className = 'exitbutton uibutton';
  leav.onclick = LeaveButton.leave;
  over.appendChild(leav);
}

function fetchgamestate() {
  Request.request(`table/${tableid()}/state`).then((gamedata: any) => {
    const phase = gamephase(gamedata.board),
      oldmute = SFX.settings().mute;
    SFX.mute();
    Soundtrack.mute();
    if (setstate(gamedata, phase)) {
      Request.request(`board/${tableid()}/player_state`).then((unitdata: any) => {
        if (phase === 'jobfair') {
          Jobfair.unitdata(unitdata);
        } else if (phase === 'board') {
          Board.unitdata(unitdata);
        }
      }).finally(() => {
        SFX.setMute(oldmute);
        Soundtrack.setMute(oldmute);
      });
    } else {
      SFX.setMute(oldmute);
      Soundtrack.setMute(oldmute);
    }
  });
}

function setstate(gamedata, phase) {
  let players = 0;
  for (const player of gamedata.players) {
    Event.player_joined(player)();
    players ++;
  }
  if (!gamedata.board || players == 1) {
    waitingforplayers();
  } else {
    render_(gamedata.board, phase, players);
    if (gamedata.timer) {
      Event.timer(gamedata)();
    }
  }
  if (gamedata.turn) {
    Event.turn({player: gamedata.turn})();
  }
  return players === 2;  // continue and fetch player hands
}

function reporterr() {
  const reporttext = prompt("Report an error with game state", "describe the problem");
  Request.post(`table/${tableid()}/report`, { report: reporttext, meta: State.gmeta });
}

window.onload = function() {
  renderTable();
  SFX.loadSettings();
  Soundtrack.loadSettings();
  const mml = () => {
    console.log('mml');
    Soundtrack.play();
    document.removeEventListener('click', mml);
  };
  document.addEventListener('click', mml);
  const errbutton = document.getElementById('errbutton');
  if (errbutton) {
    errbutton.onclick = () => {
      SFX.play('click');
      reporterr();
    }
  }

  document.addEventListener('touchend', () => {
    const hovered = document.querySelectorAll('.hover');
    for ( const el of hovered ) {
      el.classList.remove('hover');
    }
  }, false);


  Player.check();
  Request.gameaction('join', {}, 'table')
    .then(() => {
      fetchgamestate();
      listen();
    }).catch((err) => {
      console.log({ joinerror: err });
      fetchgamestate();
      listen();
    });
  const settingsEl = Settings.button();
  document.getElementById('buttons').appendChild(settingsEl);
};
