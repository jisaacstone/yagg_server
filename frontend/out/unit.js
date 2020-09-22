import { gameaction } from './request.js';
import { gmeta, isYourTurn } from './state.js';
import { displayerror } from './err.js';
import { dismissable } from './overlay.js';
function ability_button(unit, el) {
    const abilbut = document.createElement('button'), tt = document.createElement('span'), abilname = unit.ability.name;
    abilbut.className = 'unit-ability';
    abilbut.innerHTML = abilname;
    abilbut.onclick = (e) => {
        const square = el.parentNode;
        if (gmeta.boardstate !== 'battle' ||
            !isYourTurn() ||
            !square ||
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
function render_attrs(unit, el) {
    for (const att of ['name', 'attack', 'defense']) {
        const subel = document.createElement('span');
        subel.className = `unit-${att}`;
        subel.innerHTML = unit[att];
        el.appendChild(subel);
    }
    el.style.backgroundImage = `url(img/${unit.name}.png)`;
    if (unit.name === 'monarch') {
        el.className = `monarch ${el.className}`;
    }
}
function render_tile(unit, el) {
    render_attrs(unit, el);
    if (unit.ability) {
        ability_button(unit, el);
    }
    detailView(unit, el);
}
function detailView(unit, el) {
    const details = document.createElement('div'), displaybut = document.createElement('button');
    details.className = `${el.className} details`;
    render_attrs(unit, details);
    details.style.backgroundImage = `url(img/${unit.name}.png)`;
    if (unit.triggers) {
        const triggers = document.createElement('div');
        triggers.className = 'triggers';
        for (const [name, trigger] of Object.entries(unit.triggers)) {
            const triggerel = document.createElement('div');
            triggerel.className = 'trigger';
            triggers.appendChild(triggerel);
            triggerel.className = `unit-trigger ${name}-trigger`;
            triggerel.innerHTML = `{name} trigger: {trigger.description}`;
        }
        details.appendChild(triggers);
    }
    if (unit.ability) {
        const ability = document.createElement('div'), abildesc = document.createElement('div'), abilname = document.createElement('div');
        ability.className = 'unit-ability';
        abilname.innerHTML = unit.ability.name;
        ability.appendChild(abilname);
        abildesc.innerHTML = unit.ability.description;
        ability.appendChild(abildesc);
        details.appendChild(ability);
    }
    displaybut.className = 'details-button';
    displaybut.innerHTML = '?';
    displaybut.onclick = () => {
        dismissable(details);
    };
    el.appendChild(displaybut);
}
export function render_into(unit, el) {
    return render_tile(unit, el);
}
export function render(unit, index) {
    const unitEl = document.createElement('span');
    let className = `unit ${unit.player}`;
    if (unit.player === gmeta.position) {
        className += ' owned';
    }
    unitEl.className = className;
    unitEl.dataset.index = index;
    render_into(unit, unitEl);
    return unitEl;
}
