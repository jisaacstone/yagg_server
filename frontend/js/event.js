import { gmeta, gamestatechange, turnchange } from './state.js';
import * as Select from './select.js';
import * as Unit from './unit.js';
import { SKULL } from './constants.js';
import * as Board from './board.js';
import * as Ready from './ready.js';
import * as Dialog from './dialog.js';
import * as Jobfair from './jobfair.js';
import * as Overlay from './overlay.js';
import * as Player from './playerdata.js';
import * as Feature from './feature.js';
import * as Hand from './hand.js';
import * as AbilityEvent from './abilty_event.js';
const unitsbyindex = {};
export function multi({ events }) {
    let squares = [];
    const animations = [], module = this;
    for (const event of events) {
        const result = module[event.event](event);
        if (result && result.squares) {
            squares = squares.concat(result.squares);
            animations.push(result.animation);
        }
    }
    if (animations.length > 0) {
        const animation = () => {
            return Promise.all(animations.map((a) => a()));
        };
        return { animation, squares };
    }
}
export function game_started(event) {
    const board = document.getElementById('board'), state = (event.state || '').toLowerCase();
    console.log({ self: self, this: this });
    Hand.clear();
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
        Jobfair.clear();
        if (event.dimensions) {
            Board.render(board, event.dimensions.x, event.dimensions.y);
        }
        gamestatechange(state || 'placement');
        if (state === 'placement' || state === 'gameover') {
            Ready.display(state === 'placement' ? 'READY' : 'REMATCH');
        }
    }
}
export function battle_started() {
    gamestatechange('battle');
}
export function player_joined({ name, position }) {
    const nameEl = document.createElement('div'), player = Player.getLocal(), whois = name === player.name ? 'player' : 'opponent', container = document.getElementById(whois);
    if (container.firstElementChild && container.firstElementChild.className === 'playername') {
        return;
    }
    nameEl.className = 'playername';
    nameEl.innerHTML = name;
    container.appendChild(nameEl);
    if (whois === 'player') {
        gmeta.position = position;
    }
}
export function player_left({ player }) {
    document.getElementById(`${player}name`).innerHTML = '';
}
export function add_to_hand({ unit, index }) {
    const unitEl = Hand.createCard(unit, index);
    unitsbyindex[index] = unitEl;
}
export function unit_assigned({ x, y, index }) {
    const square = Board.square(x, y), unit = unitsbyindex[index];
    square.appendChild(unit);
}
export function new_unit({ x, y, unit }) {
    const exist = Board.thingAt(x, y);
    if (!exist) {
        const newunit = Unit.render(unit, 0), square = Board.square(x, y);
        square.appendChild(newunit);
    }
    else {
        // don't overwrite existing data
        exist.innerHTML = '';
        unit.render_into(exist, unit, true);
    }
}
export function unit_changed(event) {
    new_unit(event); // for now
}
export function unit_placed(event) {
    const square = Board.square(event.x, event.y);
    if (!square.firstChild) {
        const unit = Unit.render(event, null);
        square.appendChild(unit);
    }
    else {
        console.error({ msg: `${event.x},${event.y} already occupied`, event });
    }
}
export function player_ready(event) {
    if (event.player === gmeta.position) {
        document.querySelector('#player .playername').dataset.ready = 'true';
        Ready.hide();
    }
    else {
        document.querySelector('#opponent .playername').dataset.ready = 'true';
    }
}
export function feature(event) {
    const square = Board.square(event.x, event.y), feature = Feature.render(event.feature);
    square.appendChild(feature);
}
export function unit_died(event) {
    const square = Board.square(event.x, event.y), animation = () => {
        const unit = square.firstChild;
        unit.innerHTML = `<div class="death">${SKULL}</div>`;
        unit.dataset.dead = 'true';
        return unit.animate({ opacity: [1, 0] }, { duration: 500, easing: "ease-in" }).finished.then(() => {
            console.log({ unit });
            unit.remove();
        });
    };
    return { animation, squares: [`${event.x},${event.y}`] };
}
export function thing_moved(event) {
    const to = Board.square(event.to.x, event.to.y), from = Board.square(event.from.x, event.from.y), thing = from.firstChild;
    if (to) {
        const fromRect = from.getBoundingClientRect(), toRect = to.getBoundingClientRect(), animation = () => {
            const child = to.firstChild, thingRect = thing.getBoundingClientRect(), xoffset = thingRect.left - fromRect.left, yoffset = thingRect.top - fromRect.top;
            const a = thing.animate({
                top: [fromRect.top + yoffset + 'px', toRect.top + yoffset + 'px'],
                left: [fromRect.left + xoffset + 'px', toRect.left + xoffset + 'px'],
            }, { duration: 200, easing: 'ease-in-out' });
            Object.assign(thing.style, {
                position: 'fixed',
                width: thingRect.width + 'px',
                height: thingRect.height + 'px',
            });
            if (!thing.dataset.dead) {
                to.appendChild(thing);
            }
            return a.finished.then(() => {
                thing.style.position = '';
                thing.style.width = '';
                thing.style.height = '';
            });
        };
        return { animation, squares: [`${event.to.x},${event.to.y}`, `${event.from.x},${event.from.y}`] };
    }
    else {
        if (thing) {
            thing.className = thing.className.replace(' owned', '');
        }
        return thing_gone(event.from);
    }
}
export function thing_gone(event) {
    const thing = Board.thingAt(event.x, event.y);
    if (!thing) {
        console.error({ msg: `nothing at ${event.x},${event.y}`, event });
        return;
    }
    if (thing.className.includes('owned')) {
        thing.dataset.state = 'invisible';
    }
    else {
        const animation = () => {
            const a = thing.animate({ opacity: [1, 0] }, { duration: 1000, easing: "ease-in" });
            return a.finished.then(() => {
                thing.remove();
            });
        };
        return { animation, squares: [`${event.x},${event.y}`] };
    }
}
export function gameover({ winner }) {
    const message = winner === gmeta.position ? 'you win!' : 'you lose';
    gamestatechange('gameover');
    turnchange(null);
    Dialog.displayMessage(message);
    Ready.display('REMATCH');
}
export function turn({ player }) {
    turnchange(player);
}
export function candidate(event) {
    const jf = document.getElementById('jobfair'), existing = document.getElementById(`candidate-${event.index}`);
    if (existing) {
        return;
    }
    const cdd = document.createElement('div'), unitEl = Unit.render(event.unit, event.index, true);
    cdd.className = 'candidate';
    cdd.id = `candidate-${event.index}`;
    cdd.appendChild(unitEl);
    Select.bind_candidate(cdd, event.index);
    unitEl.addEventListener('dblclick', Unit.detailViewFn(event.unit, unitEl.className));
    jf.appendChild(cdd);
}
export function ability_used(event) {
    if (!AbilityEvent[event.type]) {
        console.error({ error: 'no ability handler', event });
        return null;
    }
    return AbilityEvent[event.type](event);
}
