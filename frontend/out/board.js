import { SKULL } from './constants.js';
import { render_unit } from './unit.js';
import { gameaction, request } from './request.js';
import { select } from './select.js';
import { getname, tableid, _name_ } from './urlvars.js';
import { gmeta } from './state.js';
import { displayerror } from './err.js';
import { listen } from './eventlistener.js';
import * as overlay from './overlay.js';
function boardhtml(el, width = 5, height = 5) {
    console.log('b2h');
    el.innerHTML = '';
    function makerow(y) {
        let row = document.createElement('div'), className = 'boardrow';
        if (y === 0 || y === 1) {
            className += ' southrow startrow';
        }
        else if (y === height - 1 || y === height - 2) {
            className += ' northrow startrow';
        }
        row.className = className;
        el.appendChild(row);
        function makesquare(x) {
            let square = document.createElement('div');
            square.className = 'boardsquare';
            square.id = `c${x}-${y}`;
            square.onclick = select(square, { x, y, ongrid: true });
            row.appendChild(square);
        }
        if (gmeta.position === 'north') {
            for (let x = width - 1; x >= 0; x--) {
                makesquare(x);
            }
        }
        else {
            for (let x = 0; x < width; x++) {
                makesquare(x);
            }
        }
    }
    if (gmeta.position === 'south') {
        // reverse order
        for (let y = height - 1; y >= 0; y--) {
            makerow(y);
        }
    }
    else {
        for (let y = 0; y < height; y++) {
            makerow(y);
        }
    }
}
function waitingforplayers() {
    const waiting = document.createElement('div'), copy = document.createElement('button'), comp = document.createElement('button'), over = overlay.create();
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
        });
    };
    over.appendChild(copy);
    comp.innerHTML = 'play the computer';
    comp.className = 'aibutton';
    comp.onclick = function () {
        gameaction('ai', {}, 'table').then(() => {
            overlay.clear();
        });
    };
    over.appendChild(comp);
}
function gamestatechange(newstate) {
    document.getElementById('gamestate').innerHTML = `state: ${newstate}`;
    document.getElementsByTagName('body')[0].dataset.gamestate = newstate;
    gmeta.boardstate = newstate;
    Array.prototype.forEach.call(document.getElementsByClassName('playername'), el => {
        el.dataset.ready = null;
    });
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
    game_started: function (event) {
        const board = document.getElementById('board'), state = (event.state || 'placement').toLowerCase();
        console.log({ gs: event });
        if (event.dimensions) {
            boardhtml(board, event.dimensions.x, event.dimensions.y);
        }
        gamestatechange(state);
        if (state === 'placement' || state === 'gameover') {
            displayready(state === 'placement' ? 'READY' : 'REMATCH');
        }
    },
    battle_started: function () {
        gamestatechange('battle');
    },
    player_joined: function (event) {
        console.log({ e: 'player_joined', event });
        const nameEl = document.createElement('div'), whois = event.name === getname() ? 'player' : 'opponent', container = document.getElementById(whois);
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
    player_left: function (event) {
        document.getElementById(`${event.player}name`).innerHTML = '';
    },
    add_to_hand: function (event) {
        const hand = document.getElementById('hand'), card = document.createElement('span'), unit = document.createElement('span');
        let className = `unit ${event.unit.player}`;
        card.dataset.index = event.index;
        card.className = 'card';
        card.onclick = select(card, { index: event.index, inhand: true, player: event.unit.player });
        hand.appendChild(card);
        if (event.unit.player === gmeta.position) {
            className += ' owned';
        }
        unit.className = className;
        unit.dataset.index = event.index;
        render_unit(event.unit, unit);
        card.appendChild(unit);
        unitsbyindex[event.index] = unit;
    },
    unit_assigned: function (event) {
        const square = document.getElementById(`c${event.x}-${event.y}`), unit = unitsbyindex[event.index];
        square.appendChild(unit);
    },
    new_unit: function (event) {
        const unit = document.getElementById(`c${event.x}-${event.y}`).firstElementChild;
        if (!unit) {
            return console.log({ err: 'unitnotfound', event, unit });
        }
        unit.innerHTML = '';
        render_unit(event.unit, unit);
    },
    unit_changed: function (event) {
        eventHandlers.new_unit(event); // for now
    },
    unit_placed: function (event) {
        const square = document.getElementById(`c${event.x}-${event.y}`);
        if (!square.firstChild) {
            const unit = document.createElement('span');
            unit.className = `unit ${event.player}`;
            square.appendChild(unit);
        }
    },
    player_ready: function (event) {
        if (event.player === gmeta.position) {
            document.querySelector('#player .playername').dataset.ready = 'true';
            hideready();
        }
        else {
            document.querySelector('#opponent .playername').dataset.ready = 'true';
        }
    },
    feature: function (event) {
        console.log({ feature: event });
        const square = document.getElementById(`c${event.x}-${event.y}`), feature = document.createElement('div');
        feature.className = `feature ${event.feature}`;
        feature.innerHTML = event.feature;
        square.appendChild(feature);
    },
    unit_died: function (event) {
        const square = document.getElementById(`c${event.x}-${event.y}`), unit = square.firstChild;
        unit.innerHTML = `<div class="death">${SKULL}</div>`;
        unit.animate({ opacity: [1, 0] }, { duration: 1000, easing: "ease-in" });
        setTimeout(function () {
            unit.remove();
        }, 850);
    },
    thing_moved: function (event) {
        const to = document.getElementById(`c${event.to.x}-${event.to.y}`), from = document.getElementById(`c${event.from.x}-${event.from.y}`), thing = from.firstChild;
        if (to) {
            const child = to.firstChild;
            to.appendChild(thing);
        }
        else {
            from.removeChild(thing);
        }
    },
    gameover: function (event) {
        gamestatechange('gameover');
        document.getElementById('gamestate').innerHTML = `state: gameover, winner: ${event.winner}!`;
        displayready('REMATCH');
    },
    turn: function (event) {
        gmeta.turn = event.player;
        if (event.player === gmeta.position) {
            document.querySelector('#player .playername').dataset.turn = 'true';
            document.querySelector('#opponent .playername').dataset.turn = 'false';
        }
        else {
            document.querySelector('#player .playername').dataset.turn = 'false';
            document.querySelector('#opponent .playername').dataset.turn = 'true';
        }
    }
};
function fetchgamestate() {
    request(`table/${tableid()}/state`).then((gamedata) => {
        setstate(gamedata);
        request(`board/${tableid()}/player_state/${getname()}`).then((unitdata) => {
            for (const ob of unitdata.grid) {
                eventHandlers.new_unit(ob);
            }
            Array.prototype.forEach.call(Object.entries(unitdata.hand), ([index, card]) => {
                eventHandlers.add_to_hand({ index: +index, unit: card.unit });
                if (card.assigned) {
                    eventHandlers.unit_assigned({ index: +index, x: card.assigned.x, y: card.assigned.y });
                }
            });
        });
    });
}
function setstate(gamedata) {
    let players = 0;
    for (const player of gamedata.players) {
        eventHandlers.player_joined(player);
        players++;
    }
    if (gamedata.board) {
        eventHandlers.game_started(gamedata.board);
        if (players >= 2) {
            if (gamedata.board.ready) {
                eventHandlers.player_ready({ player: gamedata.board.ready });
            }
            Object.entries(gamedata.board.grid).forEach(([coor, feature]) => {
                if (feature) {
                    const [x, y] = coor.split(',');
                    if (feature.kind === 'unit') {
                        eventHandlers.unit_placed({ x, y, player: feature.player });
                    }
                    else {
                        eventHandlers.feature({ x, y, feature });
                    }
                }
            });
            eventHandlers.turn({ player: gamedata.turn });
        }
    }
    if (!gamedata.board || gamedata.board.state === 'open') {
        waitingforplayers();
    }
}
function namedialog() {
    const gn = getname();
    if (gn) {
        return gn;
    }
    const name = prompt('enter your name', _name_());
    history.pushState({ name }, '', `${window.location}&player=${name}`);
    return name;
}
window.onload = function () {
    const name = namedialog();
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
