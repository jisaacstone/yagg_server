/* jshint esversion: 6 */
const eventHandlers = {
  game_started: function() {
    document.getElementById('gamestate').innterHTML = 'started';
  },
  player_joined: function(event) {
    console.log({e: event, p: event.position});
    document.getElementById(`${event.position}name`).innerHTML = event.name;
    document.getElementById(`${event.position}name`).className = event.name;
  },
  player_left: function(event) {
    document.getElementsByClassName(event.name)[0].innerHTML = '';
  },
  new_unit: function(event){
    console.log({nu: event});
    const newElement = document.createElement('p');
    event.unit.id = event.id;
    for (const [att, val] of Object.entries(event.unit)) {
      const subel = document.createElement('span');
      subel.className = `unit-${att}`;
      subel.innerHTML = val;
      newElement.appendChild(subel);
    }
    document.getElementById('units').appendChild(newElement);
  },
  unit_placed: function(event) {
    console.log({event});
    const square = document.getElementById(`c${event.x}-${event.y}`);
    square.innerHTML = event.id;
    if (event.id.startsWith('north')) {
      square.dataset.unitowner = 'north';
    } else if (event.id.startsWith('south')) {
      square.dataset.unitowner = 'south';
    }
  },
  unit_moved: function(event) {
    const from = document.getElementById(`c${event.from.x}-${event.from.y}`);
    const to = document.getElementById(`c${event.to.x}-${event.to.y}`);
    to.innerHTML = event.id;
    if (event.id.startsWith('north')) {
      to.dataset.unitowner = 'north';
    } else if (event.id.startsWith('south')) {
      to.dataset.unitowner = 'south';
    }
    from.dataset.unitowner = null;
    from.innerHTML = '';
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
    if (eventListener == null) {
      createEventListener();
    }
  }

  function leavegame() {
    startButton.style.display = 'none';
    nameForm.style.display = 'block';
    hostForm.style.display = 'block';
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
        console.log(`no event handler for ${evt.event}`);
      }
    });
  }

  function gameaction(action, data, callback) {
    const host = hostForm.value;
    const playername = nameForm.value;
    const baseUrl = `http://${host}/game/ID/action/${action}?player=${playername}`;  
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
    const host = hostForm.value;
    const baseUrl = `http://${host}/game/ID/state`;  
    function listener() {
      const gamedata = JSON.parse(this.responseText);
      setstate(gamedata);
    }
    var oReq = new XMLHttpRequest();
    oReq.addEventListener('load', listener);
    oReq.open('GET', baseUrl);
    oReq.setRequestHeader('Content-Type', 'application/json');
    oReq.send();
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
  };
}

function Selected(G) {
  const data = {moveoptions: []};
  function select(el) {
    const x = +el.id.charAt(1), y = +el.id.charAt(3);
    el.dataset.uistate = 'selected';
    data.selected = true;
    data.element = el;
    data.unitId = el.textContent;
    for (const neighbor of [[x + 1, y], [x - 1, y], [x, y + 1], [x, y - 1]]) {
      const nel = document.getElementById(`c${neighbor[0]}-${neighbor[1]}`);
      console.log({neighbor, nel});
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
      console.log({ev: 'handleclc', el});
      if (data.selected) {
        if (el == data.element) {
          deselect();
        } else {
          move(el);
        }
      } else if (el.dataset.unitowner) {
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
