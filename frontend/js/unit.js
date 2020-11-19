import { gameaction } from './request.js';
import * as Constants from './constants.js';
import { gmeta, isYourTurn } from './state.js';
import { displayerror } from './err.js';
import { dismissable, clear } from './overlay.js';
import * as Select from './select.js';
function bindAbility(abilityButton, square, unit, cb = null) {
    abilityButton.onclick = (e) => {
        if (gmeta.boardstate !== 'battle' ||
            !isYourTurn() ||
            !square ||
            !square.className.includes('boardsquare')) {
            return;
        }
        e.preventDefault();
        e.stopPropagation();
        if (window.confirm(unit.ability.description)) {
            Select.deselect();
            if (cb) {
                cb();
            }
            const x = +square.id.charAt(1), y = +square.id.charAt(3);
            gameaction('ability', { x: x, y: y }, 'board').catch(({ request }) => {
                if (request.status === 400) {
                    displayerror(request.responseText);
                }
            });
        }
    };
}
function ability_button(unit, el, unitSquare = null) {
    const abilbut = document.createElement('button'), tt = document.createElement('span'), abilname = unit.ability.name, square = unitSquare ? unitSquare : el.parentNode;
    abilbut.className = 'unit-ability';
    abilbut.innerHTML = abilname;
    bindAbility(abilbut, square, unit);
    el.appendChild(abilbut);
    tt.className = 'tooltip';
    tt.innerHTML = unit.ability.description;
    abilbut.appendChild(tt);
}
function convertAttr(att, value) {
    if (att === 'attack' && value === 'immobile') {
        return '-';
    }
    return value;
}
function renderAttrs(unit, el) {
    for (const att of ['name', 'attack', 'defense']) {
        if (unit[att] !== null && unit[att] !== undefined) {
            const subel = document.createElement('span');
            subel.className = `unit-${att}`;
            subel.innerHTML = convertAttr(att, unit[att]);
            el.appendChild(subel);
        }
    }
    if (unit.name === 'monarch') {
        el.className = `monarch ${el.className}`;
    }
}
function renderTile(unit, el, attrs = false) {
    if (attrs) {
        renderAttrs(unit, el);
    }
    el.style.backgroundImage = `url("img/${unit.name}.png")`;
    // @ts-ignore
    if (el.sidebar) { // @ts-ignore
        el.removeEventListener('sidebar', el.sidebar, false);
    } // @ts-ignore
    el.sidebar = () => {
        const infobox = document.getElementById('infobox'), unitInfo = document.createElement('div');
        unitInfo.className = el.className + ' info';
        infoview(unit, unitInfo, el.parentNode);
        infobox.innerHTML = '';
        infobox.appendChild(unitInfo);
        if (!anyDetails(unit)) {
            const noInfo = document.createElement('div');
            noInfo.className = 'no-info';
            noInfo.innerHTML = 'no information';
            unitInfo.appendChild(noInfo);
        }
    }; // @ts-ignore
    el.addEventListener('sidebar', el.sidebar, false);
}
function anyDetails(unit) {
    return unit.name || unit.attack || unit.defense || unit.ability || unit.triggers;
}
function infoview(unit, el, squareEl) {
    renderAttrs(unit, el);
    console.log(unit);
    el.style.backgroundImage = `url("img/${unit.name}.png")`;
    detailView(unit, el);
    if (unit.ability) {
        ability_button(unit, el, squareEl);
    }
    if (unit.triggers && Object.keys(unit.triggers).length !== 0) {
        const triggers = document.createElement('div');
        triggers.className = 'triggers';
        for (const [name, trigger] of Object.entries(unit.triggers)) {
            const trigSym = document.createElement('div');
            trigSym.className = 'trigger-symbol';
            trigSym.innerHTML = symbolFor(name);
            triggers.appendChild(trigSym);
        }
        el.appendChild(triggers);
    }
}
function symbolFor(trigger) {
    if (trigger === 'move') {
        return Constants.MOVE;
    }
    if (trigger === 'death') {
        return Constants.SKULL;
    }
    if (trigger === 'attack') {
        return Constants.ATTACK;
    }
    console.log({ warn: 'unknown trigger', trigger });
    return '?';
}
export function detailViewFn(unit, className, square = null) {
    const details = document.createElement('div'), portrait = document.createElement('div');
    details.className = `${className} details`;
    renderAttrs(unit, details);
    portrait.className = 'unit-portrait';
    portrait.style.backgroundImage = `url("img/${unit.name}.png")`;
    details.appendChild(portrait);
    if (unit.triggers) {
        const triggers = document.createElement('div');
        triggers.className = 'triggers';
        for (const [name, trigger] of Object.entries(unit.triggers)) {
            const triggerel = document.createElement('div');
            triggerel.className = 'trigger';
            triggers.appendChild(triggerel);
            triggerel.className = `unit-trigger ${name}-trigger`;
            triggerel.innerHTML = `${symbolFor(name)} ${name} trigger: ${trigger.description}`;
        }
        details.appendChild(triggers);
    }
    if (unit.ability) {
        const ability = document.createElement('div'), abildesc = document.createElement('div'), abilname = document.createElement('div');
        ability.className = 'unit-ability';
        abilname.className = 'ability-name';
        abilname.innerHTML = unit.ability.name;
        ability.appendChild(abilname);
        abildesc.innerHTML = unit.ability.description;
        ability.appendChild(abildesc);
        details.appendChild(ability);
        if (square) {
            bindAbility(abilname, square, unit, clear);
        }
    }
    return (e) => {
        e.preventDefault();
        e.stopPropagation();
        dismissable(details);
    };
}
function detailView(unit, el) {
    const displaybut = document.createElement('button');
    displaybut.className = 'details-button';
    displaybut.innerHTML = '?';
    displaybut.onclick = detailViewFn(unit, el.className);
    el.appendChild(displaybut);
}
export function isImmobile(square) {
    const child = square.firstChild;
    return containsOwnedUnit(square) && child.className.includes('immobile');
}
export function containsEnemyUnit(square) {
    const child = square.firstChild, position = gmeta.position === 'north' ? 'south' : 'north';
    if (child && child.className.includes(position)) {
        console.log('isenemy');
        return true;
    }
    return false;
}
export function containsOwnedUnit(square) {
    const child = square.firstChild;
    if (child && child.className.includes(gmeta.position)) {
        console.log('isowned');
        return true;
    }
    return false;
}
export function indexOf(square) {
    const child = square.firstChild;
    return child && +child.dataset.index;
}
function bindDetailsEvenet(unit, el) {
    const eventListener = (e) => {
        const parent = el.parentNode, square = parent.className.includes('boardsquare') ? parent : null;
        detailViewFn(unit, el.className, square)(e);
    }; // @ts-ignore
    if (el.detailsEvent) { // @ts-ignore
        el.removeEventListener('details', el.detailsEvent);
    } // @ts-ignore
    el.detailsEvent = eventListener;
    el.addEventListener('details', eventListener);
}
function setClassName(unit, el) {
    let className = `unit ${unit.player}`;
    if (unit.player === gmeta.position) {
        className += ' owned';
    }
    if (unit.attack === 'immobile') {
        className += ' immobile';
    }
    el.className = className;
}
export function render_into(unit, el, attrs = false) {
    bindDetailsEvenet(unit, el);
    setClassName(unit, el);
    return renderTile(unit, el, attrs);
}
export function render(unit, index, attrs = false) {
    const unitEl = document.createElement('span');
    unitEl.dataset.index = index;
    render_into(unit, unitEl, attrs);
    return unitEl;
}
