import { tableid } from './urlvars.js';
import { gmeta } from './state.js';
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

function render_board(board, players: number) {
  if (players !== 2) {
    return;
  }
  Event.game_started(board);
  if (board.ready) {
    Event.player_ready({player: board.ready});
  }
  Object.entries(board.grid).forEach(([coor, feature]: [string, any]) => {
    if (feature) {
      const [x, y] = coor.split(',');
      if (feature.kind === 'unit') {
        Event.unit_placed({x, y, ...feature});
      } else {
        Event.feature({x, y, feature});
      }
    }
  });
}

function render_jobfair(jobfair) {
  Event.game_started(jobfair);
}

function render_(boardstate, phase, players) {
  if (phase === 'jobfair') {
    render_jobfair(boardstate);
  } else if (phase === 'board') {
    render_board(boardstate, players)
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

  leav.innerHTML = 'exit';
  leav.className = 'exitbutton uibutton';
  leav.onclick = LeaveButton.leave;
  over.appendChild(leav);
}

function fetchgamestate() {
  Request.request(`table/${tableid()}/state`).then((gamedata: any) => {
    const phase = gamephase(gamedata.board);
    if (setstate(gamedata, phase)) {
      Request.request(`board/${tableid()}/player_state`).then((unitdata: any) => {
        if (phase === 'jobfair') {
          Jobfair.unitdata(unitdata);
        } else if (phase === 'board') {
          Board.unitdata(unitdata);
        }
      });
    }
  });
}

function setstate(gamedata, phase) {
  console.log({gamedata, phase});
  let players = 0;
  for (const player of gamedata.players) {
    Event.player_joined(player);
    players ++;
  }
  render_(gamedata.board, phase, players);
  if (!gamedata.board || players == 1) {
    waitingforplayers();
  }
  if (gamedata.turn) {
    Event.turn({player: gamedata.turn});
  }
  return players === 2;  // continue and fetch player hands
}

function reporterr() {
  const reporttext = prompt("Report an error with game state", "describe the problem");
  Request.post(`table/${tableid()}/report`, { report: reporttext, meta: gmeta });
}

window.onload = function() {
  const errbutton = document.getElementById('errbutton');
  if (errbutton) {
    errbutton.onclick = () => {
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
};
