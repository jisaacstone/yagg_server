import { getname } from './urlvars.js';
import { gmeta } from './state.js';
import * as Select from './select.js';
import * as Unit from './unit.js';
import { SKULL } from './constants.js';
import * as Board from './board.js';
import * as readyButton from './ready.js';
import * as Dialog from './dialog.js';
import * as Jobfair from './jobfair.js';
import * as Overlay from './overlay.js';
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
    const board = document.getElementById('board'), state = (event.state || '').toLowerCase();
    if (event.army_size || gmeta.phase === 'jobfair') {
        if (gmeta.boardstate === 'gameover') {
            Board.clear();
        }
        else {
            Overlay.clear();
        }
        gamestatechange(state || 'jobfair');
        Jobfair.render(event.army_size);
    }
    else {
        Overlay.clear();
        if (event.dimensions) {
            Board.render(board, event.dimensions.x, event.dimensions.y);
        }
        gamestatechange(state || 'placement');
        if (state === 'placement' || state === 'gameover') {
            readyButton.display(state === 'placement' ? 'READY' : 'REMATCH');
        }
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
    const hand = document.getElementById('hand'), card = document.createElement('span'), unit = Unit.render(event.unit, event.index);
    card.dataset.index = event.index;
    card.className = 'card';
    Select.bind_hand(card, event.index, event.unit.player, event.unit.name);
    hand.appendChild(card);
    card.appendChild(unit);
    unitsbyindex[event.index] = unit;
}
export function unit_assigned(event) {
    const square = document.getElementById(`c${event.x}-${event.y}`), unit = unitsbyindex[event.index];
    square.appendChild(unit);
}
export function new_unit(event) {
    const square = Board.square(event.x, event.y), unit = square.firstElementChild;
    if (!unit) {
        const newunit = Unit.render(event.unit, 0);
        square.appendChild(newunit);
    }
    else {
        unit.innerHTML = '';
        Unit.render_into(event.unit, unit);
    }
}
export function unit_changed(event) {
    new_unit(event); // for now
}
export function unit_placed(event) {
    const square = document.getElementById(`c${event.x}-${event.y}`);
    if (!square.firstChild) {
        const unit = Unit.render(event, null);
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
    const to = Board.square(event.to.x, event.to.y), from = Board.square(event.from.x, event.from.y), thing = from.firstChild;
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
        thing_gone(event.from);
    }
}
export function thing_gone(event) {
    const square = Board.square(event.x, event.y), thing = square.firstChild;
    if (thing.className.includes('owned')) {
        thing.dataset.state = 'invisible';
    }
    else {
        thing.animate({ opacity: [1, 0] }, { duration: 1000, easing: "ease-in" });
        setTimeout(function () {
            thing.remove();
        }, 850);
    }
}
export function gameover(event) {
    const message = event.winner === gmeta.position ? 'you win!' : 'you lose';
    gamestatechange('gameover');
    document.getElementById('gamestate').innerHTML = `state: gameover, winner: ${event.winner}!`;
    Dialog.displayMessage(message);
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
    const jf = document.getElementById('jobfair'), existing = document.getElementById(`candidate-${event.index}`), cdd = document.createElement('div'), unitEl = Unit.render(event.unit, event.index);
    if (existing) {
        return;
    }
    cdd.className = 'candidate';
    cdd.id = `candidate-${event.index}`;
    cdd.appendChild(unitEl);
    Select.bind_candidate(cdd, event.index);
    jf.appendChild(cdd);
}
