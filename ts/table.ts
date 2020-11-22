import { tableid } from './urlvars.js';
import { gmeta } from './state.js';
import { listen } from './eventlistener.js';
import * as Player from './playerdata.js';
import * as Request from './request.js';
import * as Overlay from './overlay.js';
import * as Event from './event.js';
import * as Jobfair from './jobfair.js';
import * as Board from './board.js';

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
  if (board.army_size !== undefined) {
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
    navigator.clipboard.writeText(url.toString()).then(() => {
      alert('copied!');
    })
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
  leav.onclick = leave;
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

window.onload = function() {
  const errbutton = document.getElementById('errbutton'),
    leavebutton = document.getElementById('leavebutton');
  if (errbutton) {
    errbutton.onclick = () => {
      reporterr();
    }
  }
  if (leavebutton) {
    leavebutton.onclick = () => {
      leave();
    }
  }
  Player.check();
  Request.gameaction('join', {}, 'table')
    .then(() => {
      fetchgamestate();
      listen(Event);
    }).catch((err) => {
      console.log({ joinerror: err });
      fetchgamestate();
      listen(Event);
    });
};

function leave() {
  Request.gameaction('leave', {}, 'table').then(() => {
    window.location.href = 'index.html';
  }).catch((e) => {
    console.log({error: e});
    window.location.href = 'index.html';
  });
}

function setstate(gamedata, phase) {
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
