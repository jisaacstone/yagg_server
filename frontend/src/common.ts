import { SKULL } from './constants.js';
import { render_unit } from './unit.js';
import { gameaction } from './request.js';
import { select } from './select.js';
import { boardhtml } from './board.js';

function fetchConfigs(hostname) {
  const baseUrl = `http://${hostname}/configurations`;
  function listener() {
    const select = document.getElementById('config') as HTMLInputElement;
    if (this.status != 400) {
      const configs = JSON.parse(this.response);
      for (const config of Object.keys(configs)) {
        const opt = document.createElement('option');
        opt.value = config;
        opt.innerHTML = config;
        select.appendChild(opt);
      }
    }
    select.onchange = function() {
      gameaction('rules', {configuration: select.value});
    };
  }
  var oReq = new XMLHttpRequest();
  oReq.addEventListener('load', listener);
  oReq.open('GET', baseUrl);
  oReq.send();
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
    gamestatechange('placement');
    document.getElementById('config').style.display = 'none';
    const board = document.getElementById('board');
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
    document.getElementById('config').style.display = 'inline';
  },
  turn: function(event) {
    if (event.player === 'north') {
      document.getElementById('northname').dataset.active = 'true';
      document.getElementById('southname').dataset.active = 'false';
    } else if (event.player == 'south') {
      document.getElementById('southname').dataset.active = 'true';
      document.getElementById('northname').dataset.active = 'false';
    }
  }
};

function game() {
  const eventDiv = document.getElementById('events'),
    nameForm = document.getElementById('name') as HTMLInputElement,
    hostForm = document.getElementById('host') as HTMLInputElement,
    errorDiv = document.getElementById('error'),
    joinButton = document.getElementById('joinbutton'),
    leaveButton = document.getElementById('leavebutton'),
    readyButton = document.getElementById('readybutton');
  var eventListener = null;

  function ingame() {
    readyButton.style.display = 'block';
    nameForm.style.display = 'none';
    hostForm.style.display = 'none';
  }

  function leavegame() {
    readyButton.style.display = 'none';
    nameForm.style.display = 'block';
    hostForm.style.display = 'block';
  }

  function listen() {
    if (eventListener === null) {
      createEventListener();
    }
  }

  function createEventListener() {
    const host = (document.getElementById('host') as HTMLInputElement).value;
    const playername = (document.getElementById('name') as HTMLInputElement).value;
    eventListener = new EventSource(`http://${host}/sse/table/ID/events?player=${playername}`);
    eventListener.addEventListener('game_event', function(ssevent) {
      const newElement = document.createElement('p');
      newElement.innerHTML = 'message: ' + ssevent.data;
      eventDiv.appendChild(newElement);
      const evt = JSON.parse(ssevent.data);
      if (eventHandlers[evt.event]) {
        eventHandlers[evt.event](evt);
      } else {
        console.log({msg: `no event handler for ${evt.event}`, evt});
      }
    });
  }

  function gamestate() {
    const host = hostForm.value,
      name = nameForm.value,
      oReq = new XMLHttpRequest(),
      uReq = new XMLHttpRequest();

    uReq.addEventListener('load', function () {
      const unitdata = JSON.parse(this.responseText);
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
    oReq.addEventListener('load', function () {
      const gamedata = JSON.parse(this.responseText);
      setstate(gamedata);
      uReq.open('GET', `http://${host}/board/ID/player_state/${name}`);  
      uReq.setRequestHeader('Content-Type', 'application/json');
      uReq.send();
    });
    oReq.open('GET', `http://${host}/table/ID/state`);  
    oReq.setRequestHeader('Content-Type', 'application/json');
    oReq.send();
  }

  function setstate(gamedata) {
    document.getElementById('gamestate').innerHTML = `state: ${gamedata.board.state}`;
    // global.gamestate = gamedata.state;
    for (const player of gamedata.players) {
      eventHandlers.player_joined(player);
    }
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

  return {
    ingame,
    leavegame,
    gamestate,
    listen,
  };
}

onload = function() {
  const G = game(),
    host = window.location.hostname,
    port = window.location.port,
    hostname = port ? `${host}:${port}` : host;

  document.getElementById('leavebutton').onclick = function() {
    gameaction('leave', {}).then(function() {
      G.leavegame();
    });
  };

  document.getElementById('joinbutton').onclick = function() {
    const name = (document.getElementById('name') as HTMLInputElement).value;
    gameaction('join', {player: name}).then(function () {
      fetchConfigs(hostname);
    });
    G.listen();
    G.gamestate();
    G.ingame();
  };

  document.getElementById('readybutton').onclick = function() {
    gameaction('ready', {}, 'board');
  };

  for (const el of document.getElementsByTagName('td')) {
    const x = +el.id.charAt(1), y = +el.id.charAt(3);
    el.onclick = select(el, {x, y, ongrid: true});
  }

  (document.getElementById('host') as HTMLInputElement).value = hostname;
  G.leavegame();
};
