/* jshint esversion: 6 */
const global = {};
const SKULL = String.fromCodePoint(0x1F480);

function select(el, meta) {
  function select() {
    const sel = global.selected;
    console.log({el, meta, sel});
    if (sel) {
      sel.element.dataset.unstate = 'selected';
      if (sel.element !== el) {
        if (sel.meta.ongrid && sel.meta.inhand) {
          return;
        }
        if (sel.meta.inhand) {
          global.game.gameaction('place', {index: sel.meta.index, x: meta.x, y: meta.y}, null, 'move');
        } else {
          global.game.gameaction('move', {from_x: sel.meta.x, from_y: sel.meta.y, to_x: meta.x, to_y: meta.y}, null, 'move');
        }
      }
      sel.element.dataset.uistate = '';
      for (const opt of sel.options) {
        opt.dataset.uistate = '';
      }
      global.selected = null;
    } else {
      if (global.gamestate === 'placement' && meta.x) {
        // changing placement not supported yet
        return;
      }
      const options = [];
      if (meta.inhand) {
        for (const el of document.getElementsByClassName(`${meta.player}option`)) {
          el.dataset.uistate = 'moveoption';
          options.push(el);
        }
      } else {
        for (const neighbor of [[meta.x + 1, meta.y], [meta.x - 1, meta.y], [meta.x, meta.y + 1], [meta.x, meta.y - 1]]) {
          const nel = document.getElementById(`c${neighbor[0]}-${neighbor[1]}`);
          if (nel) {
            nel.dataset.uistate = 'moveoption';
            options.push(nel);
          }
        }
      }
      global.selected = {element: el, meta: meta, options: options};
    }
  }
  return select;
}

function fetchConfigs(hostname) {
  const baseUrl = `http://${hostname}/configurations`;
  function listener() {
    const select = document.getElementById('config');
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
      global.game.gameaction('rules', {configuration: select.value});
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
          global.game.gameaction('ability', {name: abilname, x: x, y: y}, null, 'move');
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
  global.gamestate = newstate;
  for (const el of document.getElementsByClassName('playername')) {
    el.dataset.ready = null;
  }
}

const eventHandlers = {
  game_started: function() {
    gamestatechange('placement');
    document.getElementById('config').style.display = 'none';
  },
  battle_started: function() {
    gamestatechange('battle');
  },
  player_joined: function(event) {
    document.getElementById(`${event.position}name`).innerHTML = event.name;
    document.getElementById(`${event.position}name`).dataset.playername = event.name;
    if (event.name === document.getElementById('name').value) {
      document.getElementById(event.position).appendChild(document.getElementById('hand'));
    }
  },
  player_left: function(event) {
    document.getElementById(`${event.player}name`).innerHTML = '';
  },
  new_hand: function(event){
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
    for (const card of hand.children) {
      console.log({i: card.dataset.index, event, card});
      if (+card.dataset.index === +event.index) {
        square.appendChild(card.firstChild);
        return;
      }
    }
  },
  new_unit: function(event){
    const unit = document.getElementById(`c${event.x}-${event.y}`).firstChild;
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
    document.getElementById(`${event.player}name`).dataset.ready = true;
  },
  feature: function(event) {
    const square = document.getElementById(`c${event.x}-${event.y}`);
    square.innerHTML = event.feature;
    square.dataset.feature = event.feature;
  },
  unit_died: function(event) {
    const square = document.getElementById(`c${event.x}-${event.y}`),
      unit = square.firstChild;
    unit.innerHTML = SKULL;
    setTimeout(function() {
      square.removeChild(unit);
    }, 750);
  },
  unit_moved: function(event) {
    console.log({E: 'unit_moved', event});
    const to = document.getElementById(`c${event.to.x}-${event.to.y}`),
      unit = document.getElementById(`c${event.from.x}-${event.from.y}`).firstChild;
    while(to.firstChild) {
      to.removeChild(to.firstChild);
    }
    to.appendChild(unit);
  },
  gameover: function(event) {
    gamestatechange('over');
    document.getElementById('gamestate').innerHTML = `state: gameover, winner: ${event.winner}!`;
  },
  turn: function(event) {
    if (event.player === 'north') {
      document.getElementById('northname').dataset.active = true;
      document.getElementById('southname').dataset.active = false;
    } else if (event.player == 'south') {
      document.getElementById('southname').dataset.active = true;
      document.getElementById('northname').dataset.active = false;
    }
  }
};

function game() {
  const eventDiv = document.getElementById('events'),
    nameForm = document.getElementById('name'),
    hostForm = document.getElementById('host'),
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
    const host = document.getElementById('host').value;
    const playername = document.getElementById('name').value;
    eventListener = new EventSource(`http://${host}/sse/game/ID/events?player=${playername}`);
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

  function gameaction(action, data, callback, key = 'action') {
    const host = hostForm.value;
    const name = nameForm.value;
    const baseUrl = `http://${host}/game/ID/${key}/${action}?player=${name}`;
    function listener() {
      if (this.status >= 400) {
         errorDiv.innerHTML = `error: ${this.status}, message: ${this.responseText}`;
      } else {
        errorDiv.innerHTML = '';
        if (callback) {
          callback(this.response);
        }
      }
    }
    var oReq = new XMLHttpRequest();
    oReq.addEventListener('load', listener);
    oReq.open('POST', baseUrl);
    oReq.setRequestHeader('Content-Type', 'application/json');
    oReq.send(JSON.stringify(data || {}));
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
      for (const [index, card] of Object.entries(unitdata.hand)) {
        eventHandlers.new_hand({index: +index, unit: card.unit});
        if (card.assigned) {
          eventHandlers.unit_assigned({index: +index, x: card.assigned.x, y: card.assigned.y});
        }
      }
    });
    oReq.addEventListener('load', function () {
      const gamedata = JSON.parse(this.responseText);
      setstate(gamedata);
      uReq.open('GET', `http://${host}/game/ID/units/${name}`);  
      uReq.setRequestHeader('Content-Type', 'application/json');
      uReq.send();
    });
    oReq.open('GET', `http://${host}/game/ID/state`);  
    oReq.setRequestHeader('Content-Type', 'application/json');
    oReq.send();
  }

  function setstate(gamedata) {
    document.getElementById('gamestate').innerHTML = `state: ${gamedata.board.state}`;
    global.gamestate = gamedata.state;
    for (const player of gamedata.players) {
      eventHandlers.player_joined(player);
    }
    if (gamedata.board.ready) {
      eventHandlers.player_ready({player: gamedata.board.ready});
    }
    for (const [coor, feature] of Object.entries(gamedata.board.grid)) {
      const [x, y] = coor.split(',');
      if (feature.kind === 'unit') {
        eventHandlers.unit_placed({x, y, player: feature.player});
      } else {
        eventHandlers.feature({x, y, feature});
      }
    }
    eventHandlers.turn({player: gamedata.turn});
  }

  return {
    ingame,
    leavegame,
    gameaction,
    gamestate,
    listen,
  };
}

window.onload = function() {
  const G = game(),
    host = window.location.hostname,
    port = window.location.port,
    hostname = port ? `${host}:${port}` : host;

  global.game = G;
  global.hostname = hostname;
  document.getElementById('leavebutton').onclick = function() {
    G.gameaction('leave', {}, function() {
      G.leavegame();
    });
  };

  document.getElementById('joinbutton').onclick = function() {
    const name = document.getElementById('name').value;
    G.gameaction('join', {player: name}, function() {
      fetchConfigs(global.hostname);
    });
    G.listen();
    G.gamestate();
    G.ingame();
  };

  document.getElementById('readybutton').onclick = function() {
    G.gameaction('ready', {}, null, 'move');
  };

  document.getElementById('restartbutton').onclick = function() {
    G.gameaction('restart');
  };

  for (const el of document.getElementsByTagName('td')) {
    const x = +el.id.charAt(1), y = +el.id.charAt(3);
    el.onclick = select(el, {x, y, ongrid: true});
  }

  document.getElementById('host').value = hostname;
  G.leavegame();
};
