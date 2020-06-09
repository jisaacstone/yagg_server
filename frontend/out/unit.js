import { gameaction } from './request.js';
import { SKULL } from './constants.js';
function unit_el(unit, el) {
    for (const att of ['name', 'attack', 'defense']) {
        const subel = document.createElement('span');
        subel.className = `unit-${att}`;
        subel.innerHTML = unit[att];
        el.appendChild(subel);
    }
    if (unit.triggers && unit.triggers.death) {
        const subel = document.createElement('span'), tt = document.createElement('span');
        subel.className = 'unit-deathrattle';
        subel.innerHTML = SKULL;
        el.firstChild.prepend(subel); // firstChild should be the name
        tt.className = 'tooltip';
        tt.innerHTML = `When this unit dies: ${unit.triggers.death.description}`;
        subel.appendChild(tt);
    }
    if (unit.ability) {
        const abilbut = document.createElement('button'), tt = document.createElement('span'), abilname = unit.ability.name;
        console.log({ unit: unit, abilname });
        abilbut.className = 'unit-ability';
        abilbut.innerHTML = abilname;
        abilbut.onclick = function (e) {
            if (el.parentNode.tagName === 'TD') {
                e.preventDefault();
                e.stopPropagation();
                if (window.confirm(unit.ability.description)) {
                    const square = el.parentNode, x = +square.id.charAt(1), y = +square.id.charAt(3);
                    gameaction('ability', { name: abilname, x: x, y: y }, 'board');
                }
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
    return el;
}
export function render_unit(unit, el) {
    return unit_el(unit, el);
}
