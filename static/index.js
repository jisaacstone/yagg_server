/* jshint esversion: 6 */
const eventHandlers = {
  game_started: function() {
    document.getElementById('gamestate').innerHTML = 'state: battle!';
  },
  player_joined: function(event) {
    document.getElementById(`${event.position}name`).innerHTML = event.name;
    document.getElementById(`${event.position}name`).className = event.name;
  },
  player_left: function(event) {
    document.getElementsByClassName(event.name)[0].innerHTML = '';
  },
  new_unit: function(event){
    const unit = document.getElementById(`c${event.x}-${event.y}`).firstChild;
    if (!unit) {
      return console.log({err: 'unitnotfound', event, unit});
    }
    unit.innerHTML = '';
    for (const att of ['name', 'attack', 'defense']) {
      const subel = document.createElement('span');
      subel.className = `unit-${att}`;
      subel.innerHTML = event.unit[att];
      unit.appendChild(subel);
    }
    if (event.unit.name === 'monarch') {
      unit.className = `monarch ${unit.className}`;
    }
  },
  unit_placed: function(event) {
    const square = document.getElementById(`c${event.x}-${event.y}`);
    const unit = document.createElement('span');
    unit.className = `unit ${event.player}`;
    square.appendChild(unit);
  },
  feature: function(event) {
    const square = document.getElementById(`c${event.x}-${event.y}`);
    square.innerHTML = event.feature;
  },
  unit_died: function(event) {
    document.getElementById(`c${event.x}-${event.y}`).innerHTML = '';
  },
  unit_moved: function(event) {
    console.log({E: 'unit_moved', event});
    const to = document.getElementById(`c${event.to.x}-${event.to.y}`),
      unit = document.getElementById(`c${event.from.x}-${event.from.y}`).firstChild;
    to.appendChild(unit);
  },
  gameover: function(event) {
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
    startButton = document.getElementById('startbutton');
  var eventListener = null;

  function ingame() {
    startButton.style.display = 'block';
    nameForm.style.display = 'none';
    hostForm.style.display = 'none';
  }

  function leavegame() {
    startButton.style.display = 'none';
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

  function gameaction(action, data, callback) {
    const host = hostForm.value;
    const name = nameForm.value;
    const baseUrl = `http://${host}/game/ID/action/${action}?player=${name}`;
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
      oReq2 = new XMLHttpRequest();

    oReq2.addEventListener('load', function () {
      const unitdata = JSON.parse(this.responseText);
      console.log({unitdata});
      for (const unitdatum of unitdata) {
        eventHandlers.new_unit(unitdatum);
      }
    });
    oReq.addEventListener('load', function () {
      const gamedata = JSON.parse(this.responseText);
      setstate(gamedata);
      oReq2.open('GET', `http://${host}/game/ID/units/${name}`);  
      oReq2.setRequestHeader('Content-Type', 'application/json');
      oReq2.send();
    });
    oReq.open('GET', `http://${host}/game/ID/state`);  
    oReq.setRequestHeader('Content-Type', 'application/json');
    oReq.send();
  }

  function setstate(gamedata) {
    document.getElementById('gamestate').innerHTML = `state: ${gamedata.state}`;
    for (const player of gamedata.players) {
      eventHandlers.player_joined(player);
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

function Selected(G) {
  const data = {moveoptions: []};
  function select(el) {
    console.log({action: 'selelct', el});
    const x = +el.id.charAt(1), y = +el.id.charAt(3);
    const unit = el.children[0];
    el.dataset.uistate = 'selected';
    data.selected = true;
    data.element = el;
    data.x = x;
    data.y = y;
    if (unit) {
      data.unitId = unit.dataset.id;
    }
    for (const neighbor of [[x + 1, y], [x - 1, y], [x, y + 1], [x, y - 1]]) {
      const nel = document.getElementById(`c${neighbor[0]}-${neighbor[1]}`);
      if (nel) {
        nel.dataset.uistate = 'moveoption';
        data.moveoptions.push(nel);
      }
    }
  }
  function deselect() {
    data.element.dataset.uistate = '';
    while(data.moveoptions.length) {
      const nel = data.moveoptions.pop();
      nel.dataset.uistate = '';
    }
    data.selected = false;
    data.element = null;
    data.unitId = '';
    data.x = null;
    data.y = null;
  }
  function move(to_el) {
    const id = to_el.id,
      x = +id.charAt(1),
      y = +id.charAt(3);
    G.gameaction('move', {from_x: data.x, from_y: data.y, to_x: x, to_y: y});
    deselect();
  }
  function clickhandler(el) {
    function handleclick() {
      console.log({data, el});
      if (data.selected) {
        if (el == data.element) {
          deselect();
        } else {
          move(el);
        }
      } else if (el.children[0]) {
        select(el);
      }
    }
    return handleclick;
  }
  return { clickhandler };
}

window.onload = function() {
  const G = game(),
    selected = Selected(G),
    host = window.location.hostname,
    port = window.location.port;

  document.getElementById('leavebutton').onclick = function() {
    G.gameaction('leave', {}, function() {
      G.leavegame();
    });
  };

  document.getElementById('joinbutton').onclick = function() {
    const name = document.getElementById('name').value;
    G.gameaction('join', {player: name}, function() {
      G.ingame();
    });
    G.listen();
    G.gamestate();
  };

  document.getElementById('startbutton').onclick = function() {
    G.gameaction('start');
  };

  for (const el of document.getElementsByTagName('td')) {
    el.onclick = selected.clickhandler(el);
  }

  document.getElementById('host').value = port ? `${host}:${port}` : host;
  G.leavegame();
};
