/* jshint esversion: 6 */
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
    leaveButton.style.display = 'block';
    startButton.style.display = 'block';
    nameForm.style.display = 'none';
    hostForm.style.display = 'none';
    if (eventListener == null) {
      createEventListener();
    }
  }

  function leavegame() {
    leaveButton.style.display = 'none';
    startButton.style.display = 'none';
    nameForm.style.display = 'block';
    hostForm.style.display = 'block';
  }

  function createEventListener() {
    const host = document.getElementById('host').value;
    const playername = document.getElementById('name').value;
    eventListener = new EventSource(`http://${host}/sse/game/ID/events?player=${name}`);
    eventListener.addEventListener('game_event', function(event) {
      const newElement = document.createElement('p');
      newElement.innerHTML = 'message: ' + event.data;
      eventDiv.appendChild(newElement);
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
    document.getElementById('gamestate').innerHTML = `state: ${gamedata.state}, players: ${JSON.stringify(gamedata.players)}`;
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
