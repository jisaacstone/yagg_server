/* jshint esversion: 6 */
const eventHandlers = {
  'game_started': function() {
    document.getElementById('gamestate').innterHTML = 'started';
  },
  'player_joined': function(event) {
    console.log({e: event, p: event.position});
    document.getElementById(`${event.position}name`).innerHTML = event.name;
    document.getElementById(`${event.position}name`).class = event.name;
  },
  'player_left': function(event) {
    document.getElementsByClassName(event.name)[0].innerHTML = '';
  },
  'unit_placed': function(event) {
    console.log(event);
    console.log(`c${event.x}-${event.y}`);
    document.getElementById(`c${event.x}-${event.y}`).innerHTML = event.id;
  },
  'new_unit': function(event){
    console.log({nu: event});
      const newElement = document.createElement('p');
      newElement.innerHTML = `id: ${event.id}, unit: ${event.unit}`;
      document.getElementById('units').appendChild(newElement);
  }
};

window.onload = function() {
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

  function gameaction(actionJson, callback) {
    const host = hostForm.value;
    const playername = nameForm.value;
    const baseUrl = `http://${host}/game/ID/action?player=${playername}`;  
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
    oReq.send(JSON.stringify(actionJson));
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
    for (const [k, v] of Object.entries(gamedata.board.features)) {
      const [x, y] = k.split(',');
      document.getElementById(`c${x}-${y}`).innerHTML = v;
    }
  }

  leaveButton.onclick = function() {
    gameaction({action: 'leave'}, function() {
      leavegame();
    });
  };

  joinButton.onclick = function() {
    gameaction({action: 'join'}, function() {
      ingame();
    });
    gamestate();
  };

  startButton.onclick = function() {
    gameaction({action: 'start'});
  };

  leavegame();
};
