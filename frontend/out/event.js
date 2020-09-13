import { getname } from './urlvars.js';
import { gmeta } from './state.js';
import { select } from './select.js';
import * as Unit from './unit.js';
import { SKULL } from './constants.js';
import * as Board from './board.js';
import * as readyButton from './ready.js';
const unitsbyindex = {};
function gamestatechange(newstate) {
    document.getElementById('gamestate').innerHTML = `state: ${newstate}`;
    document.getElementsByTagName('body')[0].dataset.gamestate = newstate;
    gmeta.boardstate = newstate;
    Array.prototype.forEach.call(document.getElementsByClassName('playername'), el => {
        el.dataset.ready = null;
    });
}
export function game_started(event) {
    const board = document.getElementById('board'), state = (event.state || 'placement').toLowerCase();
    if (event.dimensions) {
        Board.render(board, event.dimensions.x, event.dimensions.y);
    }
    gamestatechange(state);
    if (state === 'placement' || state === 'gameover') {
        readyButton.display(state === 'placement' ? 'READY' : 'REMATCH');
    }
}
export function battle_started() {
    gamestatechange('battle');
}
export function player_joined(event) {
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
}
export function player_left(event) {
    document.getElementById(`${event.player}name`).innerHTML = '';
}
export function add_to_hand(event) {
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
    Unit.render_into(event.unit, unit);
    card.appendChild(unit);
    unitsbyindex[event.index] = unit;
}
export function unit_assigned(event) {
    const square = document.getElementById(`c${event.x}-${event.y}`), unit = unitsbyindex[event.index];
    square.appendChild(unit);
}
export function new_unit(event) {
    const unit = document.getElementById(`c${event.x}-${event.y}`).firstElementChild;
    if (!unit) {
        return console.log({ err: 'unitnotfound', event, unit });
    }
    unit.innerHTML = '';
    Unit.render_into(event.unit, unit);
}
export function unit_changed(event) {
    new_unit(event); // for now
}
export function unit_placed(event) {
    const square = document.getElementById(`c${event.x}-${event.y}`);
    if (!square.firstChild) {
        const unit = document.createElement('span');
        unit.className = `unit ${event.player}`;
        square.appendChild(unit);
    }
}
export function player_ready(event) {
    if (event.player === gmeta.position) {
        document.querySelector('#player .playername').dataset.ready = 'true';
        readyButton.hide();
    }
    else {
        document.querySelector('#opponent .playername').dataset.ready = 'true';
    }
}
export function feature(event) {
    console.log({ feature: event });
    const square = document.getElementById(`c${event.x}-${event.y}`), feature = document.createElement('div');
    feature.className = `feature ${event.feature}`;
    feature.innerHTML = event.feature;
    square.appendChild(feature);
}
export function unit_died(event) {
    const square = document.getElementById(`c${event.x}-${event.y}`), unit = square.firstChild;
    unit.innerHTML = `<div class="death">${SKULL}</div>`;
    unit.animate({ opacity: [1, 0] }, { duration: 1000, easing: "ease-in" });
    setTimeout(function () {
        unit.remove();
    }, 850);
}
export function thing_moved(event) {
    const to = document.getElementById(`c${event.to.x}-${event.to.y}`), from = document.getElementById(`c${event.from.x}-${event.from.y}`), thing = from.firstChild;
    if (to) {
        const child = to.firstChild, fromRect = from.getBoundingClientRect(), toRect = to.getBoundingClientRect(), xOffset = Math.round(fromRect.left - toRect.left) + 'px', yOffset = Math.round(fromRect.top - toRect.top) + 'px';
        thing.style.position = 'relative';
        console.log([from.getBoundingClientRect(), to.getBoundingClientRect()]);
        thing.animate({
            top: [yOffset, '0'],
            left: [xOffset, '0'],
        }, { duration: 100, easing: 'ease-in' });
        delete thing.style.position;
        to.appendChild(thing);
    }
    else {
        from.removeChild(thing);
    }
}
export function gameover(event) {
    gamestatechange('gameover');
    document.getElementById('gamestate').innerHTML = `state: gameover, winner: ${event.winner}!`;
    readyButton.display('REMATCH');
}
export function turn(event) {
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
export function candidate(event) {
    const jf = document.getElementById('jobfair'), cdd = document.createElement('div'), unitEl = Unit.render(event.unit, event.index);
    cdd.className = 'candidate';
    cdd.appendChild(unitEl);
    jf.appendChild(cdd);
}
