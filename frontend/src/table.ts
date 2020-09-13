import { gameaction, request } from './request.js';
import { getname, tableid, _name_ } from './urlvars.js';
import { gmeta } from './state.js';
import { listen } from './eventlistener.js';
import * as Overlay from './overlay.js';
import * as Event from './event.js';
import * as Jobfair from './jobfair.js';
import * as Board from './board.js';

function render_board(board) {
  Event.game_started(board);
  if (board.ready) {
    Event.player_ready({player: board.ready});
  }
  Object.entries(board.grid).forEach(([coor, feature]: [string, any]) => {
    if (feature) {
      const [x, y] = coor.split(',');
      if (feature.kind === 'unit') {
        Event.unit_placed({x, y, player: feature.player});
      } else {
        Event.feature({x, y, feature});
      }
    }
  });
}

function render_jobfair(jobfair) {
  Jobfair.render(jobfair.min, jobfair.max, jobfair[gmeta.position].choices);
}

function render_(boardstate, phase) {
  if (phase === 'jobfair') {
    console.log('rjf');
    render_jobfair(boardstate);
  } else if (phase === 'board') {
    console.log('rb');
    render_board(boardstate)
  }
}

function gamephase(board) {
  console.log({ board });
  if (board.min !== undefined && board.max !== undefined) {
    return 'jobfair';
  } else if (board.grid) {
    return 'board';
  }
  return null;
}

function waitingforplayers() {
  const waiting = document.createElement('div'),
    copy = document.createElement('button'),
    comp = document.createElement('button'),
    over = Overlay.create();

  over.className = over.className + ' waiting';
  waiting.innerHTML = 'waiting for opponent';
  over.appendChild(waiting);

  copy.innerHTML = 'copy join link';
  copy.className = 'linkcopy';
  copy.onclick = () => {
    const url = new URL(window.location.toString());
    url.searchParams.delete('player');
    navigator.clipboard.writeText(url.toString()).then(() => {
      alert('copied!');
    })
  }
  over.appendChild(copy);

  comp.innerHTML = 'play the computer';
  comp.className = 'aibutton';
  comp.onclick = function() {
    gameaction('ai', {}, 'table').then(() => {
      Overlay.clear();
    });
  }
  over.appendChild(comp);
}

function fetchgamestate() {
  request(`table/${tableid()}/state`).then((gamedata: any) => {
    const phase = gamephase(gamedata.board);
    setstate(gamedata, phase);
    request(`board/${tableid()}/player_state/${getname()}`).then((unitdata: any) => {
      if (phase === 'jobfair') {
        Jobfair.unitdata(unitdata);
      } else if (phase === 'board') {
        Board.unitdata(unitdata);
      }
    });
  });
}

function namedialog(): string {
  const gn = getname();
  if (gn) {
    return gn;
  }
  const name = prompt('enter your name', _name_());
  history.pushState({ name }, '', `${window.location}&player=${name}`);
  return name;
}

window.onload = function() {
  const name = namedialog();
  gmeta.name = name;
  gameaction('join', { player: name }, 'table')
    .then(() => {
      fetchgamestate();
      listen(Event);
    }).catch((err) => {
      console.log({ joinerror: err });
      fetchgamestate();
      listen(Event);
    });
};

function setstate(gamedata, phase) {
  console.log({gamedata, phase});
  let players = 0;
  for (const player of gamedata.players) {
    Event.player_joined(player);
    players ++;
  }
  if (!gamedata.board || players == 1) {
    waitingforplayers();
  } else {
    render_(gamedata.board, phase);
  }
  if (gamedata.turn) {
    Event.turn({player: gamedata.turn});
  }
}

