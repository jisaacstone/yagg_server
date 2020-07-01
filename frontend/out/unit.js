import { gameaction } from './request.js';
import { SKULL, MOVE } from './constants.js';
import { gmeta } from './state.js';
import { displayerror } from './err.js';
function unit_el(unit, el) {
    for (const att of ['name', 'attack', 'defense']) {
        const subel = document.createElement('span');
        subel.className = `unit-${att}`;
        subel.innerHTML = unit[att];
        el.appendChild(subel);
    }
    el.style.backgroundImage = `url(img/${unit.name}.png)`;
    if (unit.triggers) {
        const triggerel = document.createElement('div');
        triggerel.className = 'triggers';
        el.appendChild(triggerel);
        if (unit.triggers.death) {
            const subel = document.createElement('div'), tt = document.createElement('span');
            subel.className = 'unit-trigger death-trigger';
            subel.innerHTML = SKULL;
            triggerel.appendChild(subel);
            tt.className = 'tooltip';
            tt.innerHTML = `When this unit dies: ${unit.triggers.death.description}`;
            subel.appendChild(tt);
        }
        if (unit.triggers.move) {
            const subel = document.createElement('div'), tt = document.createElement('span');
            subel.className = 'unit-trigger move-trigger';
            subel.innerHTML = MOVE;
            triggerel.appendChild(subel);
            tt.className = 'tooltip';
            tt.innerHTML = `When this unit moves: ${unit.triggers.move.description}`;
            subel.appendChild(tt);
        }
    }
    if (unit.ability) {
        const abilbut = document.createElement('button'), tt = document.createElement('span'), abilname = unit.ability.name, square = el.parentNode;
        abilbut.className = 'unit-ability';
        abilbut.innerHTML = abilname;
        abilbut.onclick = function (e) {
            if (gmeta.boardstate !== 'battle' ||
                gmeta.position !== gmeta.turn ||
                !square.className.includes('boardsquare')) {
                return;
            }
            e.preventDefault();
            e.stopPropagation();
            if (window.confirm(unit.ability.description)) {
                const x = +square.id.charAt(1), y = +square.id.charAt(3);
                gameaction('ability', { x: x, y: y }, 'board').catch(({ request }) => {
                    if (request.status === 400) {
                        displayerror(request.responseText);
                    }
                });
            }
        };
        el.appendChild(abilbut);
        tt.className = 'tooltip';
        tt.innerHTML = unit.ability.description;
        abilbut.appendChild(tt);
    }
    if (unit.name === 'monarch') {
        el.className = `monarch ${el.className}`;
    }
}
export function render_unit(unit, el) {
    return unit_el(unit, el);
}
