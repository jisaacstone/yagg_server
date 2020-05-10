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
    const unit = document.getElementById(`unit-${event.unit.id}`);
    unit.innerHTML = '';
    for (const att of ['id', 'name', 'attack', 'defense']) {
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
    unit.id = `unit-${event.id}`;
    unit.innerHTML = event.id;
    unit.dataset.id = event.id;
    if (event.id.startsWith('north')) {
      unit.className = 'unit north';
    } else if (event.id.startsWith('south')) {
      unit.className = 'unit south';
    }
    square.appendChild(unit);
  },
  unit_died: function(event) {
    document.getElementById(`unit-${event.id}`).parentNode.innerHTML = '';
  },
  unit_moved: function(event) {
    console.log({E: 'unit_moved', event});
    const to = document.getElementById(`c${event.to.x}-${event.to.y}`);
    to.appendChild(document.getElementById(`unit-${event.id}`));
  },
  gameover: function(event) {
    document.getElementById('gamestate').innerHTML = `state: gameover, winner: ${event.winner}!`;
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
    const host = hostForm.value, name = nameForm.value;
    const oReq = new XMLHttpRequest();
    oReq.addEventListener('load', function () {
      const gamedata = JSON.parse(this.responseText);
      setstate(gamedata);
    });
    oReq.open('GET', `http://${host}/game/ID/state`);  
    oReq.setRequestHeader('Content-Type', 'application/json');
    oReq.send();
    const oReq2 = new XMLHttpRequest();
    oReq2.addEventListener('load', function () {
      const unitdata = JSON.parse(this.responseText);
      console.log({unitdata});
      for (const [_, unit] of Object.entries(unitdata)) {
        eventHandlers.new_unit({unit});
      }
    });
    oReq2.open('GET', `http://${host}/game/ID/units/${name}`);  
    oReq2.setRequestHeader('Content-Type', 'application/json');
    oReq2.send();
  }

  function setstate(gamedata) {
    document.getElementById('gamestate').innerHTML = `state: ${gamedata.state}`;
    for (const player of gamedata.players) {
      eventHandlers.player_joined(player);
    }
    for (const [coor, id] of Object.entries(gamedata.board.features)) {
      const [x, y] = coor.split(',');
      eventHandlers.unit_placed({x, y, id});
    }
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
    data.element.uistate = '';
    while(data.moveoptions.length) {
      const nel = data.moveoptions.pop();
      nel.dataset.uistate = '';
    }
    data.selected = false;
    data.element = null;
    data.unitId = '';
  }
  function move(to_el) {
    const id = to_el.id,
      x = +id.charAt(1),
      y = +id.charAt(3),
      from_el = data.element;
    G.gameaction('move', {id: data.unitId, to_x: x, to_y: y});
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
    selected = Selected(G);

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

  G.leavegame();
};
