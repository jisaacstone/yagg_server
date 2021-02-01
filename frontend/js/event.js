import { gmeta, gamestatechange, turnchange } from './state.js';
import * as Select from './select.js';
import * as Unit from './unit.js';
import { SKULL } from './constants.js';
import * as Board from './board.js';
import * as Ready from './ready.js';
import * as Dialog from './dialog.js';
import * as Jobfair from './jobfair.js';
import * as Overlay from './overlay.js';
import * as Player from './player.js';
import * as Feature from './feature.js';
import * as Hand from './hand.js';
import * as AbilityEvent from './abilty_event.js';
import * as Element from './element.js';
import * as Timer from './timer.js';
import { leave } from './leaveButton.js';
import * as SFX from './sfx.js';
import * as Request from './request.js';
const unitsbyindex = {};
function noGrid(fn) {
    return {
        animation: () => Promise.resolve(fn()),
        squares: []
    };
}
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
    return noGrid(() => {
        const board = document.getElementById('board'), state = (event.state || '').toLowerCase();
        Hand.clear();
        Ready.hide();
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
                Ready.display(state === 'placement' ? 'ready' : 'rematch');
            }
        }
    });
}
export function timer(event) {
    return noGrid(() => {
        Timer.set(event.timer, event.player);
    });
}
export function battle_started() {
    return noGrid(() => {
        gamestatechange('battle');
    });
}
export function player_joined({ player, position }) {
    return noGrid(() => {
        const thisPlayer = Player.getLocal(), whois = thisPlayer.id == player.id ? 'player' : 'opponent', container = document.getElementById(whois), playerDetailsEl = Player.render(player);
        if (container.firstElementChild) {
            if (container.firstElementChild.className === 'playername') {
                return;
            }
            else {
                container.innerHTML = '';
            }
        }
        container.appendChild(playerDetailsEl);
        if (whois === 'player') {
            gmeta.position = position;
            document.getElementById('table').dataset.position = position;
        }
    });
}
export function player_left({ player }) {
    return noGrid(() => {
        const thisPlayer = Player.getLocal(), whois = thisPlayer.id == player.id ? 'player' : 'opponent', container = document.getElementById(whois);
        container.innerHTML = '';
        container.appendChild(Element.create({ className: 'invisible' }));
    });
}
export function add_to_hand({ unit, index }) {
    return noGrid(() => {
        const unitEl = Hand.createCard(unit, index);
        unitsbyindex[index] = unitEl;
        unitEl.scrollIntoView({ behavior: "smooth", block: "center" });
    });
}
export function unit_assigned({ x, y, index }) {
    return {
        animation: () => {
            const square = Board.square(x, y), unit = unitsbyindex[index];
            square.appendChild(unit);
            return SFX.play('place');
        },
        squares: [`${x},${y}`]
    };
}
export function new_unit({ x, y, unit }) {
    const animation = () => {
        const exist = Board.thingAt(x, y);
        let unitEl;
        if (!exist) {
            const square = Board.square(x, y);
            unitEl = Unit.render(unit, 0);
            square.appendChild(unitEl);
        }
        else {
            // don't overwrite existing data
            exist.innerHTML = '';
            Unit.render_into(unit, exist);
            unitEl = exist;
        }
        const a = unitEl.animate({ opacity: [0.5, 0.9, 1] }, { duration: 100 });
        return a.finished;
    };
    return { animation, squares: [`${x},${y}`] };
}
export function unit_changed(event) {
    return new_unit(event); // for now
}
export function unit_placed(event) {
    return {
        animation: () => {
            const square = Board.square(event.x, event.y);
            if (!square.firstChild) {
                const unit = Unit.render(event, null);
                square.appendChild(unit);
                return SFX.play('place');
            }
            else {
                console.log({ msg: `${event.x},${event.y} already occupied`, event });
                return Promise.resolve(false);
            }
        },
        squares: [`${event.x},${event.y}`]
    };
}
export function player_ready(event) {
    return noGrid(() => {
        if (event.player === gmeta.position) {
            document.querySelector('#player .playername').dataset.ready = 'true';
            Ready.hide();
        }
        else {
            SFX.play('playerready');
            document.querySelector('#opponent .playername').dataset.ready = 'true';
        }
    });
}
export function feature(event) {
    return {
        animation: () => {
            const square = Board.square(event.x, event.y), feature = Feature.render(event.feature);
            square.appendChild(feature);
            return Promise.resolve(true);
        },
        squares: [`${event.x},${event.y}`]
    };
}
export function unit_died(event) {
    const square = Board.square(event.x, event.y), animation = () => {
        const unit = square.firstChild;
        if (!unit) {
            return Promise.resolve(true);
        }
        unit.innerHTML = `<div class="death">${SKULL}</div>`;
        unit.dataset.dead = 'true';
        return SFX.play('death').then(() => {
            return unit.animate({ opacity: [1, 0] }, { duration: 500, easing: "ease-in" }).finished.then(() => {
                unit.remove();
            });
        });
    };
    return { animation, squares: [`${event.x},${event.y}`] };
}
export function thing_moved(event) {
    const from = Board.square(event.from.x, event.from.y);
    if (event.to.x !== undefined && event.to.y !== undefined) {
        const to = Board.square(event.to.x, event.to.y), fromRect = from.getBoundingClientRect(), toRect = to.getBoundingClientRect(), animation = () => {
            const thing = from.firstChild;
            return SFX.play('move').then(() => {
                const thingRect = thing.getBoundingClientRect(), xoffset = thingRect.left - fromRect.left, yoffset = thingRect.top - fromRect.top;
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
            });
        };
        return { animation, squares: [`${event.to.x},${event.to.y}`, `${event.from.x},${event.from.y}`] };
    }
    else if (event.direction) {
        // moved offscreen
        const animation = () => {
            const thing = from.firstChild, thingRect = thing.getBoundingClientRect(), xpos = thingRect.left, ypos = thingRect.top, { x, y } = Board.in_direction(event.direction, thingRect.width);
            const a = thing.animate([
                {
                    top: ypos + 'px',
                    left: xpos + 'px',
                    opacity: 1
                },
                {
                    top: ypos + y + 'px',
                    left: xpos + x + 'px',
                    opacity: 0.9
                },
                {
                    top: ypos + y + 'px',
                    left: xpos + x + 'px',
                    opacity: 0
                },
            ], { duration: 400, easing: 'ease-in-out' });
            Object.assign(thing.style, {
                position: 'fixed',
                width: thingRect.width + 'px',
                height: thingRect.height + 'px',
            });
            return a.finished.then(() => {
                thing.remove();
            });
        };
        return { animation, squares: [`${event.from.x},${event.from.y}`] };
    }
    else if (event.to === 'hand') {
        const animation = () => {
            const thing = from.firstChild, thingRect = thing.getBoundingClientRect(), handRect = document.getElementById('hand').getBoundingClientRect(), xpos = thingRect.left, ypos = thingRect.top, to_x = (handRect.left + handRect.right - thingRect.width) / 2, to_y = (handRect.top + handRect.bottom - thingRect.height) / 2, a = thing.animate({
                top: [ypos + 'px', to_y + 'px'],
                left: [xpos + 'px', to_x + 'px'],
                opacity: [1, 0]
            }, {
                duration: 500, easing: 'ease-out'
            });
            Object.assign(thing.style, {
                position: 'fixed',
                width: thingRect.width + 'px',
                height: thingRect.height + 'px',
            });
            return a.finished.then(() => {
                thing.remove();
            });
        };
        return { animation, squares: [`${event.from.x},${event.from.y}`] };
    }
    else {
        console.error({ err: 'unrecognized move', event });
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
export function battle({ from, to }) {
    // animation only, no lasting chages
    const animation = () => {
        return SFX.play('battle').then(() => {
            const attacker = Board.thingAt(from.x, from.y), defender = Board.thingAt(to.x, to.y), arect = attacker.getBoundingClientRect(), drect = defender.getBoundingClientRect(), xpos = arect.left, ypos = arect.top;
            let xdiff = 0, ydiff = 0;
            if (from.x !== to.x) {
                xdiff = (drect.left > arect.left ? drect.left - arect.right : drect.right - arect.left) * 1.8;
            }
            if (from.y !== to.y) {
                ydiff = (drect.top > arect.top ? drect.top - arect.bottom : drect.bottom - arect.top) * 1.8;
            }
            Object.assign(attacker.style, {
                position: 'fixed',
                width: arect.width + 'px',
                height: arect.height + 'px',
            });
            return attacker.animate({
                top: [ypos + 'px', ypos + ydiff + 'px'],
                left: [xpos + 'px', xpos + xdiff + 'px']
            }, { duration: 100, easing: 'ease-in' }).finished.then(() => {
                defender.animate({ opacity: [1, 0.5, 1] }, { duration: 80 });
                return attacker.animate({
                    top: [ypos + ydiff + 'px', ypos + 'px'],
                    left: [xpos + xdiff + 'px', xpos + 'px']
                }, { duration: 80, easing: 'ease-out' }).finished;
            }).then(() => {
                attacker.style.position = '';
                attacker.style.width = '';
                attacker.style.height = '';
            });
        });
    };
    return { animation, squares: [`${to.x},${to.y}`, `${from.x},${from.y}`] };
}
export function gameover({ winner, reason }) {
    return noGrid(() => {
        let message;
        const showRematch = !reason || !reason.toLowerCase().includes('opponent left'), choices = {
            ok: () => { if (showRematch) {
                Ready.display('rematch');
            } },
            leave,
        };
        gamestatechange('gameover');
        Timer.stop();
        turnchange(null);
        if (winner === gmeta.position) {
            SFX.play('go_win');
            message = 'you win!';
        }
        else if (winner === 'draw') {
            SFX.play('go_draw');
            message = 'draw game';
        }
        else {
            SFX.play('go_lose');
            message = 'you lose';
        }
        if (reason) {
            message = `<p>${reason}<p>${message}`;
        }
        if (showRematch) {
            choices['rematch'] = () => {
                return Request.gameaction('ready', {}, 'board').then(() => {
                    window.location.reload();
                });
            };
        }
        Dialog.choices(message, choices);
    });
}
export function turn({ player }) {
    return noGrid(() => {
        turnchange(player);
    });
}
export function candidate(event) {
    return noGrid(() => {
        const jf = document.getElementById('jobfair'), existing = document.getElementById(`candidate-${event.index}`);
        if (existing) {
            return;
        }
        const unitEl = Unit.render(event.unit, event.index), cdd = Element.create({
            className: 'candidate',
            id: `candidate-${event.index}`,
            children: [unitEl]
        }), qbutton = Element.create({
            tag: 'button',
            className: 'detailsButton uibutton',
        });
        qbutton.setAttribute('title', 'details');
        Select.bind_candidate(cdd, event.index, event.unit);
        unitEl.addEventListener('dblclick', Unit.detailViewFn(event.unit, unitEl.className));
        qbutton.addEventListener('click', Unit.detailViewFn(event.unit, unitEl.className));
        unitEl.appendChild(qbutton);
        jf.appendChild(cdd);
    });
}
export function ability_used(event) {
    if (!AbilityEvent[event.type]) {
        console.error({ error: 'no ability handler', event });
        return noGrid(() => {
            SFX.play('ability');
        });
    }
    return AbilityEvent[event.type](event);
}
export function table_shutdown() {
    return noGrid(() => {
        return Dialog.alert('table closed').then(() => {
            window.location.href = 'index.html';
        });
    });
}
