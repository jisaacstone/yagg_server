import { SKULL, MOVE } from './constants.js';
import { render_unit } from './unit.js';
import { gameaction, request } from './request.js';
import { select } from './select.js';
import { hostname, getname, tableid, _name_ } from './urlvars.js';
import { gmeta } from './state.js';
import { displayerror } from './err.js';
import { listen } from './eventlistener.js';

function boardhtml(el: HTMLElement, width=5, height=5) {
  el.innerHTML = '';
  function makerow(y: number) {
    let row = document.createElement('div'),
      className = 'boardrow';
    if (y === 0 || y === 1) {
      className += ' southrow startrow';
    } else if (y === height - 1 || y === height - 2) {
      className += ' northrow startrow';
    }
    row.className = className;
    el.appendChild(row);

    function makesquare(x: number) {
      let square = document.createElement('div')
      square.className = 'boardsquare';
      square.id = `c${x}-${y}`;
      square.onclick = select(square, {x, y, ongrid: true});
      row.appendChild(square);
    }

    if (gmeta.position === 'north') {
      for (let x=width - 1; x >= 0; x--) {
        makesquare(x);
      }
    } else {
      for (let x=0; x < width; x++) {
        makesquare(x);
      }
    }
  }

  if (gmeta.position === 'south') {
    // reverse order
    for (let y=height - 1; y >= 0; y--) {
      makerow(y);
    }
  } else {
    for (let y=0; y < height; y++) {
      makerow(y);
    }
  }
}

function waitingforplayers(el: HTMLElement) {
  const waiting = document.createElement('div'),
    copy = document.createElement('button');
  waiting.className = 'waiting';
  waiting.innerHTML = 'waiting for opponent';
  el.appendChild(waiting);
  copy.innerHTML = 'copy join link';
  copy.className = 'linkcopy';
  copy.onclick = () => {
    const url = new URL(window.location.toString());
    url.searchParams.delete('player');
    navigator.clipboard.writeText(url.toString()).then(() => {
      alert('copied!');
    })
  }
  waiting.appendChild(copy);
}

function unit_el(unit, el) {
  for (const att of ['name', 'attack', 'defense']) {
    const subel = document.createElement('span');
    subel.className = `unit-${att}`;
    subel.innerHTML = unit[att];
    el.appendChild(subel);
  }
  el.style.backgroundImage = `url(img/${unit.name}.png)`;
  if (unit.triggers) {
    const triggerel = document.createElement('div');
    triggerel.className = 'triggers';
    el.appendChild(triggerel);
    if (unit.triggers.death) {
      const subel = document.createElement('div'),
        tt = document.createElement('span');
      subel.className = 'unit-trigger death-trigger';
      subel.innerHTML = SKULL;
      triggerel.appendChild(subel);
      tt.className = 'tooltip';
      tt.innerHTML = `When this unit dies: ${unit.triggers.death.description}`;
      subel.appendChild(tt);
    }
    if (unit.triggers.move) {
      const subel = document.createElement('div'),
        tt = document.createElement('span');
      subel.className = 'unit-trigger move-trigger';
      subel.innerHTML = MOVE;
      triggerel.appendChild(subel);
      tt.className = 'tooltip';
      tt.innerHTML = `When this unit moves: ${unit.triggers.move.description}`;
      subel.appendChild(tt);
    }
  }
  if (unit.ability) {
    const abilbut = document.createElement('button'),
      tt = document.createElement('span'),
      abilname = unit.ability.name;
    abilbut.className = 'unit-ability';
    abilbut.innerHTML = abilname;
    abilbut.onclick = function(e) {
      if (el.parentNode.className === 'boardsquare') {
        e.preventDefault();
        e.stopPropagation();
        if (window.confirm(unit.ability.description)) {
          const square = el.parentNode,
            x = +square.id.charAt(1),
            y = +square.id.charAt(3);
          gameaction('ability', {x: x, y: y}, 'board');
        }
      }
    };
    el.appendChild(abilbut);
    tt.className = 'tooltip';
    tt.innerHTML = unit.ability.description;
    abilbut.appendChild(tt);
  }
  if (unit.name === 'monarch') {
    el.className = `monarch ${el.className}`;
  }
}

function gamestatechange(newstate) {
  document.getElementById('gamestate').innerHTML = `state: ${newstate}`;
  document.getElementsByTagName('body')[0].dataset.gamestate = newstate;
  gmeta.boardstate = newstate;
  Array.prototype.forEach.call(
    document.getElementsByClassName('playername') as HTMLCollectionOf<HTMLInputElement>,
    el => {
      el.dataset.ready = null;
    }
  );
}

function displayready(label = 'READY') {
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

function hideready() {
  const readyButton = document.getElementById('readybutton');
  if (readyButton) {
    readyButton.remove();
  }
}

const unitsbyindex = {};

const eventHandlers = {
  game_started: function(event) {
    const board = document.getElementById('board'),
      state = (event.state || 'placement').toLowerCase();
    if (! event.dimensions) {
      console.log({event, foob: "gog"});
      return request(`table/${tableid()}/state`).then((gamedata) => {
        setstate(gamedata);
      });
    }
    boardhtml(board, event.dimensions.x, event.dimensions.y);
    gamestatechange(state);
    if (state === 'placement' || state === 'gameover') {
      displayready(state === 'placement' ? 'READY' : 'REMATCH');
    }
  },
  battle_started: function() {
    gamestatechange('battle');
  },
  player_joined: function(event) {
    console.log({e: 'player_joined', event});
    const nameEl = document.createElement('div'),
      whois = event.name === getname() ? 'player' : 'opponent',
      container = document.getElementById(whois);
    if (container.firstElementChild) {
      return;
    }
    nameEl.className = 'playername';
    nameEl.innerHTML = event.name;
    container.appendChild(nameEl);
    if (whois === 'player') {
      gmeta.position = event.position;
    }
  },
  player_left: function(event) {
    document.getElementById(`${event.player}name`).innerHTML = '';
  },

  add_to_hand: function(event){
    const hand = document.getElementById('hand'),
      card = document.createElement('span'),
      unit = document.createElement('span');
    let className = `unit ${event.unit.player}`;
    card.dataset.index = event.index;
    card.className = 'card';
    card.onclick = select(card, {index: event.index, inhand: true, player: event.unit.player});
    hand.appendChild(card);
    if (event.unit.player === gmeta.position) {
      className += ' owned';
    }
    unit.className = className;
    unit.dataset.index = event.index;
    unit_el(event.unit, unit);
    card.appendChild(unit);
    unitsbyindex[event.index] = unit;
  },

  unit_assigned: function(event) {
    const square = document.getElementById(`c${event.x}-${event.y}`),
      unit = unitsbyindex[event.index];
    square.appendChild(unit);
  },

  new_unit: function(event){
    const unit = document.getElementById(`c${event.x}-${event.y}`).firstElementChild as HTMLElement;
    if (!unit) {
      return console.log({err: 'unitnotfound', event, unit});
    }
    unit.innerHTML = '';
    unit_el(event.unit, unit);
  },

  unit_changed: function(event) {
    eventHandlers.new_unit(event);  // for now
  },

  unit_placed: function(event) {
    const square = document.getElementById(`c${event.x}-${event.y}`);
    if (! square.firstChild) {
      const unit = document.createElement('span');
      unit.className = `unit ${event.player}`;
      square.appendChild(unit);
    }
  },

  player_ready: function(event) {
    if ( event.player === gmeta.position ) {
      (document.querySelector('#player .playername') as HTMLElement).dataset.ready = 'true';
      hideready();
    } else {
      (document.querySelector('#opponent .playername') as HTMLElement).dataset.ready = 'true';
    }
  },
  feature: function(event) {
    const square = document.getElementById(`c${event.x}-${event.y}`),
      feature = document.createElement('div');
    feature.className = `feature ${event.feature}`;
    feature.innerHTML = event.feature;
    square.appendChild(feature);
  },
  unit_died: function(event) {
    const square = document.getElementById(`c${event.x}-${event.y}`),
      unit = square.firstChild as HTMLElement;
    unit.innerHTML = `<div class="death">${SKULL}</div>`;
    unit.animate({ opacity: [1, 0] }, { duration: 1000, easing: "ease-in" });
    setTimeout(function() {
      unit.remove();
    }, 850);
  },

  thing_moved: function(event) {
    const to = document.getElementById(`c${event.to.x}-${event.to.y}`),
      from = document.getElementById(`c${event.from.x}-${event.from.y}`),
      thing = from.firstChild;
    if (to) {
      const child = to.firstChild as HTMLElement;
      to.appendChild(thing);
    } else {
      from.removeChild(thing);
    }
  },

  gameover: function(event) {
    gamestatechange('gameover');
    document.getElementById('gamestate').innerHTML = `state: gameover, winner: ${event.winner}!`;
    displayready('REMATCH');
  },

  turn: function(event) {
    gmeta.turn = event.player;
    if (event.player === gmeta.position) {
      (document.querySelector('#player .playername') as HTMLElement).dataset.turn = 'true';
      (document.querySelector('#opponent .playername') as HTMLElement).dataset.turn = 'false';
    } else {
      (document.querySelector('#player .playername') as HTMLElement).dataset.turn = 'false';
      (document.querySelector('#opponent .playername') as HTMLElement).dataset.turn = 'true';
    }
  }
};

function fetchgamestate() {
  request(`table/${tableid()}/state`).then((gamedata) => {
    setstate(gamedata);
    request(`board/${tableid()}/player_state/${getname()}`).then((unitdata: any) => {
      for (const ob of unitdata.grid) {
        eventHandlers.new_unit(ob);
      }
      Array.prototype.forEach.call(
        Object.entries(unitdata.hand),
        ([index, card]: [string, any]) => {
          eventHandlers.add_to_hand({index: +index, unit: card.unit});
          if (card.assigned) {
            eventHandlers.unit_assigned({index: +index, x: card.assigned.x, y: card.assigned.y});
          }
        }
      );
    });
  });
}

function setstate(gamedata) {
  let players = 0;
  for (const player of gamedata.players) {
    eventHandlers.player_joined(player);
    players ++;
  }
  if (gamedata.board) {
    eventHandlers.game_started(gamedata.board);
    if (players >= 2) {
      if (gamedata.board.ready) {
        eventHandlers.player_ready({player: gamedata.board.ready});
      }
      Object.entries(gamedata.board.grid).forEach(([coor, feature]: [string, any]) => {
        if (feature) {
          const [x, y] = coor.split(',');
          if (feature.kind === 'unit') {
            eventHandlers.unit_placed({x, y, player: feature.player});
          } else {
            eventHandlers.feature({x, y, feature});
          }
        }
      });
      eventHandlers.turn({player: gamedata.turn});
    }
  } else {
    waitingforplayers(document.getElementById('board'));
  }
}

function namedialog() {
  return prompt('enter your name', _name_());
}

window.onload = function() {
  const name = getname() || namedialog();
  gmeta.name = name;
  gameaction('join', { player: name }, 'table')
    .then(() => {
      fetchgamestate();
      listen(eventHandlers);
    }).catch((err) => {
      console.log({ joinerror: err });
      fetchgamestate();
      listen(eventHandlers);
    });
};
