import { SKULL } from './constants.js';
import { render_unit } from './unit.js';
import { gameaction, request } from './request.js';
import { select } from './select.js';
import { hostname, getname, tableid } from './urlvars.js';

function boardhtml(el: HTMLElement, width=5, height=5) {
  for (let y=0; y < height; y++) {
    let row = document.createElement('div');
    row.className = 'boardrow';
    el.appendChild(row);
    for (let x=0; x < width; x++) {
      let square = document.createElement('div')
      square.className = 'boardsquare';
      square.id = `c${x}-${y}`;
      square.onclick = select(el, {x, y, ongrid: true});
      row.appendChild(square);
    }
  }
}

function unit_el(unit, el) {
  for (const att of ['name', 'attack', 'defense']) {
    const subel = document.createElement('span');
    subel.className = `unit-${att}`;
    subel.innerHTML = unit[att];
    el.appendChild(subel);
  }
  if (unit.triggers && unit.triggers.death) {
    const subel = document.createElement('span'),
      tt = document.createElement('span');
    subel.className = 'unit-deathrattle';
    subel.innerHTML = SKULL;
    el.firstChild.prepend(subel);  // firstChild should be the name
    tt.className = 'tooltip';
    tt.innerHTML = `When this unit dies: ${unit.triggers.death.description}`;
    subel.appendChild(tt);
  }
  if (unit.ability) {
    const abilbut = document.createElement('button'),
      tt = document.createElement('span'),
      abilname = unit.ability.name;
    console.log({unit: unit, abilname});
    abilbut.className = 'unit-ability';
    abilbut.innerHTML = abilname;
    abilbut.onclick = function(e) {
      if (el.parentNode.tagName === 'TD') {
        e.preventDefault();
        e.stopPropagation();
        if (window.confirm(unit.ability.description)) {
          const square = el.parentNode,
            x = +square.id.charAt(1),
            y = +square.id.charAt(3);
          gameaction('ability', {name: abilname, x: x, y: y}, 'board');
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
  // global.gamestate = newstate;
  Array.prototype.forEach.call(
    document.getElementsByClassName('playername') as HTMLCollectionOf<HTMLInputElement>,
    el => {
      el.dataset.ready = null;
      return null;
    }
  );
}

const eventHandlers = {
  game_started: function() {
    const board = document.getElementById('board');
    gamestatechange('placement');
    boardhtml(board);
  },
  battle_started: function() {
    gamestatechange('battle');
  },
  player_joined: function(event) {
    const nameEl = document.getElementById('name') as HTMLInputElement;
    document.getElementById(`${event.position}name`).innerHTML = event.name;
    document.getElementById(`${event.position}name`).dataset.playername = event.name;
    if (event.name === nameEl.value) {
      document.getElementById(event.position).appendChild(document.getElementById('hand'));
    }
  },
  player_left: function(event) {
    document.getElementById(`${event.player}name`).innerHTML = '';
  },
  add_to_hand: function(event){
    const hand = document.getElementById('hand'),
      card = document.createElement('span'),
      unit = document.createElement('span');
    card.dataset.index = event.index;
    card.className = 'card';
    card.onclick = select(card, {index: event.index, inhand: true, player: event.unit.player});
    hand.appendChild(card);
    unit.className = `unit ${event.unit.player}`;
    unit_el(event.unit, unit);
    card.appendChild(unit);
  },
  unit_assigned: function(event) {
    const hand = document.getElementById('hand'),
      square = document.getElementById(`c${event.x}-${event.y}`);
    for (const card of hand.children as HTMLCollectionOf<HTMLElement>) {
      if (+card.dataset.index === +event.index) {
        square.appendChild(card.firstChild);
        return;
      }
    }
  },
  new_unit: function(event){
    const unit = document.getElementById(`c${event.x}-${event.y}`).firstChild as HTMLElement;
    if (!unit) {
      return console.log({err: 'unitnotfound', event, unit});
    }
    unit.innerHTML = '';
    unit_el(event.unit, unit);
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
    document.getElementById(`${event.player}name`).dataset.ready = 'true';
  },
  feature: function(event) {
    const square = document.getElementById(`c${event.x}-${event.y}`);
    square.innerHTML = event.feature;
    square.dataset.feature = event.feature;
  },
  unit_died: function(event) {
    const square = document.getElementById(`c${event.x}-${event.y}`),
      unit = square.firstChild as HTMLElement;
    unit.innerHTML = SKULL;
    setTimeout(function() {
      square.removeChild(unit);
    }, 750);
  },
  unit_moved: function(event) {
    console.log({E: 'unit_moved', event});
    const to = document.getElementById(`c${event.to.x}-${event.to.y}`),
      from = document.getElementById(`c${event.from.x}-${event.from.y}`),
      unit = from.firstChild;
    while(to.firstChild) {
      to.removeChild(to.firstChild);
    }
    to.appendChild(unit);
    if (from.dataset.feature) {
      to.dataset.feature = from.dataset.feature;
      from.dataset.feature = null;
    }
  },
  gameover: function(event) {
    gamestatechange('over');
    document.getElementById('gamestate').innerHTML = `state: gameover, winner: ${event.winner}!`;
  },
  turn: function(event) {
    if (event.player === 'north') {
      document.getElementById('north').dataset.active = 'true';
      document.getElementById('south').dataset.active = 'false';
    } else if (event.player == 'south') {
      document.getElementById('south').dataset.active = 'true';
      document.getElementById('north').dataset.active = 'false';
    }
  }
};

function game() {
  var eventListener = null;

  function listen() {
    if (eventListener === null) {
      createEventListener();
    }
  }

  function createEventListener() {
    const host = hostname();
    const playername = getname();
    eventListener = new EventSource(`http://${host}/sse/table/ID/events?player=${playername}`);
    eventListener.addEventListener('game_event', function(ssevent) {
      console.log({ ssevent });
      const evt = JSON.parse(ssevent.data);
      if (eventHandlers[evt.event]) {
        eventHandlers[evt.event](evt);
      } else {
        console.log({msg: `no event handler for ${evt.event}`, evt});
      }
    });
  }

  function gamestate() {
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
    if (players >= 2) {
      //eventHandlers.game_started();
      document.getElementById('gamestate').innerHTML = `state: ${gamedata.board.state}`;
      if (gamedata.board.ready) {
        eventHandlers.player_ready({player: gamedata.board.ready});
      }
      Object.entries(gamedata.board.grid).forEach(([coor, feature]: [string, any]) => {
        const [x, y] = coor.split(',');
        if (feature.kind === 'unit') {
          eventHandlers.unit_placed({x, y, player: feature.player});
        } else {
          eventHandlers.feature({x, y, feature});
        }
      });
      eventHandlers.turn({player: gamedata.turn});
    }
  }

  return {
    gamestate,
    listen,
  };
}

window.onload = function() {
  const G = game();
  eventHandlers.game_started();
  G.gamestate();
  G.listen();
};
