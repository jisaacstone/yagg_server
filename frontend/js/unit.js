import { gameaction } from './request.js';
import { gmeta, isYourTurn } from './state.js';
import { displayerror } from './err.js';
import { dismissable, clear } from './overlay.js';
import * as Select from './select.js';
import * as Dialog from './dialog.js';
import * as Element from './element.js';
import * as Triggers from './triggers.js';
import * as Tooltip from './tooltip.js';
import * as SFX from './sfx.js';
import * as Board from './board.js';
export function showName(coord, name) {
    const squareId = Board.squareId(coord), unitEl = document.querySelector(`#${squareId} .unit`), nameEl = document.querySelector(`#${squareId} .unit-name`);
    if (unitEl && !nameEl) {
        unitEl.appendChild(Element.create({
            className: 'unit-name',
            innerHTML: convertAttr('name', name)
        }));
        unitEl.style.backgroundImage = `url("img/${name}.png")`;
    }
}
export function showAbility(coord, ability) {
    const squareId = Board.squareId(coord), unitEl = document.querySelector(`#${squareId} .unit`), abilityEl = document.querySelector(`#${squareId} .unit-abiltiy`);
    if (unitEl && !abilityEl) {
        abilityIcon(unitEl, ability);
    }
}
export function showTriggers(coord, triggers) {
    const squareId = Board.squareId(coord), unitEl = document.querySelector(`#${squareId} .unit`), triggerEl = document.querySelector(`#${squareId} .unit-abiltiy`);
    if (unitEl && !triggerEl) {
        // immobile, invisible, etc should never be revealed so we should be OK
        // with this type coercion
        shortTriggers(unitEl, { triggers });
    }
}
export function hilight(coord, className) {
    const el = document.querySelector(`#${Board.squareId(coord)} .${className}`);
    if (!el) {
        console.log({ coord, className });
        return Promise.resolve(false);
    }
    //SFX.play('hilight');
    el.dataset.hilighted = 'true';
    el.classList.add('hilight');
    console.log(el);
    return new Promise((resolve) => {
        setTimeout(() => {
            delete el.dataset.hilighted;
            el.classList.remove('hilight');
            resolve(true);
        }, 500);
    });
}
function bindAbility(abilityButton, square, unit, cb = null) {
    abilityButton.onclick = (e) => {
        if (!owned(unit)) {
            return;
        }
        SFX.play('ability');
        if (square === null) {
            square = abilityButton.parentNode.parentNode;
        }
        if (gmeta.boardstate !== 'battle' ||
            !isYourTurn() ||
            !square ||
            !square.className.includes('boardsquare')) {
            return;
        }
        e.preventDefault();
        e.stopPropagation();
        return Dialog.confirm(unit.ability.description, 'use').then((confirmed) => {
            Select.deselect();
            if (!confirmed) {
                return;
            }
            if (cb) {
                cb();
            }
            const x = +square.id.charAt(1), y = +square.id.charAt(3);
            gameaction('ability', { x: x, y: y }, 'board').catch(({ request }) => {
                if (request.status === 400) {
                    displayerror(request.responseText);
                }
            });
        });
    };
}
function abilityButton(unit, el, unitSquare = null) {
    const abilbut = Element.create({
        tag: 'button',
        className: 'unit-ability',
        innerHTML: unit.ability.name,
    }), square = unitSquare ? unitSquare : el.parentNode;
    if (owned(unit)) {
        bindAbility(abilbut, square, unit);
    }
    el.appendChild(abilbut);
}
function owned({ player }) {
    return player === gmeta.position;
}
function abilityIcon(el, ability, unit) {
    const abil = Element.create({
        className: 'unit-ability',
        innerHTML: ability.name,
        tag: 'button',
        title: 'ability',
    });
    Tooltip.addTooltip(abil, ability.description);
    el.appendChild(abil);
    if (unit) {
        console.log({ binding: abil });
        bindAbility(abil, null, unit);
    }
}
function convertAttr(att, value) {
    if (att === 'attack' && value === 'immobile') {
        return '-';
    }
    return `${value}`;
}
function renderAttrs(unit, el) {
    for (const att of ['name', 'attack', 'defense']) {
        if (unit[att] !== null && unit[att] !== undefined) {
            el.appendChild(Element.create({
                className: `unit-${att}`,
                innerHTML: convertAttr(att, unit[att])
            }));
        }
    }
    if (unit.name === 'monarch') {
        el.className = `monarch ${el.className}`;
    }
}
function renderTile(unit, el) {
    // if we have no name we have nothing else
    if (unit.name) {
        renderAttrs(unit, el);
        shortTriggers(el, unit);
        el.style.backgroundImage = `url("img/${unit.name}.png")`;
        const qbutton = Element.create({
            tag: 'button',
            className: 'detailsButton',
            title: 'details',
        });
        qbutton.addEventListener('click', detailViewFn(unit, el.className));
        el.appendChild(qbutton);
    }
    if (unit.ability) {
        abilityIcon(el, unit.ability, unit);
    }
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
            unitInfo.appendChild(Element.create({
                className: 'no-info',
                innerHTML: 'no information'
            }));
        }
    }; // @ts-ignore
    el.addEventListener('sidebar', el.sidebar, false);
}
function anyDetails(unit) {
    return unit.name || unit.attack || unit.defense || unit.ability || unit.triggers;
}
function shortTriggers(el, unit) {
    const triggers = Triggers.get(unit), triggerEls = [];
    if (triggers.length === 0) {
        return;
    }
    for (const { name, description, timing } of triggers) {
        const tttext = timing ? `${timing}: ${description}` : description, ts = Element.create({ className: `trigger-symbol ${name}-t` });
        Tooltip.addTooltip(ts, tttext);
        triggerEls.push(ts);
    }
    el.appendChild(Element.create({
        className: 'triggers',
        children: triggerEls
    }));
}
function infoview(unit, el, squareEl) {
    renderAttrs(unit, el);
    if (unit.name) {
        const qbutton = Element.create({
            tag: 'button',
            className: 'detailsButton uibutton',
            title: 'details',
        });
        el.appendChild(qbutton);
        el.style.backgroundImage = `url("img/${unit.name}.png")`;
    }
    el.onclick = detailViewFn(unit, el.className, squareEl);
    if (unit.ability) {
        abilityButton(unit, el, squareEl);
    }
    shortTriggers(el, unit);
}
const fakeDescriptions = [
    'Listens to smooth jazz',
    'Loves action movies',
    'Smiles at inappropriate times',
    'Donates to public radio',
    'Makes excellent chili',
    'Snacks constantly',
    'Believes the moon does not exist',
    'Former child',
    'Collects viynl',
    'Aspiring hipster',
    'Community college graduate',
    'Good at remembering names',
    'Never learned to drive',
    'Taking flute lessons',
    'Craft beer nerd',
    'Loves crosswords, hates sudoku',
    'Amateur BMX racer',
    'Competitive salsa dancer',
    'Watches TV until 2am every night',
    "Has a tattoo, but won't say where",
    'Once won $2,000 in Vegas',
    'Went to clown school',
    'Failed pacifist',
    'Believes everything that happens was fated to happen',
    'Pastafarian',
    'Whistles off key',
];
function describe(unit, square = null) {
    const descriptions = [], triggers = Triggers.get(unit);
    if (unit.ability) {
        const abilname = Element.create({
            className: 'ability-name uibutton',
            innerHTML: unit.ability.name,
        }), abildesc = Element.create({
            className: 'ability-description',
            innerHTML: unit.ability.description
        }), ability = Element.create({
            className: 'unit-ability',
            children: [abilname, abildesc]
        });
        if (square) {
            bindAbility(abilname, square, unit, clear);
        }
        descriptions.push(ability);
    }
    if (triggers.length > 0) {
        const triggersEl = Element.create({ className: 'triggers' });
        for (const { name, description, timing } of triggers) {
            const ts = Element.create({ className: `trigger-symbol ${name}-t` });
            Tooltip.addTooltip(ts, timing ? timing : name);
            triggersEl.appendChild(Element.create({
                className: `unit-trigger ${name}-trigger`,
                children: [
                    ts,
                    Element.create({
                        className: 'trigger-description',
                        innerHTML: `${description}`
                    })
                ]
            }));
        }
        descriptions.push(triggersEl);
    }
    if (descriptions.length === 0 && unit.name) {
        const seed = unit.name.charCodeAt(0) + unit.name.charCodeAt(1) + unit.name.charCodeAt(2) + (gmeta.position || 'e').charCodeAt(0), desc = fakeDescriptions[seed % fakeDescriptions.length];
        descriptions.push(Element.create({ className: 'bio', innerHTML: desc }));
    }
    return Element.create({
        className: 'descriptions',
        children: descriptions
    });
}
export function detailViewFn(unit, className, square = null) {
    SFX.play('click');
    const descriptions = describe(unit, square), portrait = Element.create({ className: 'unit-portrait' }), details = Element.create({
        className: `${className} details`,
        children: [descriptions, portrait]
    });
    renderAttrs(unit, details);
    portrait.style.backgroundImage = `url("img/${unit.name}.png")`;
    return (e) => {
        e.preventDefault();
        e.stopPropagation();
        dismissable(details);
    };
}
export function isImmobile(square) {
    const child = square.firstChild;
    return containsOwnedUnit(square) && child.className.includes('immobile');
}
export function containsEnemyUnit(square) {
    const child = square.firstChild, position = gmeta.position === 'north' ? 'south' : 'north';
    if (child && child.className.includes(position)) {
        return true;
    }
    return false;
}
export function containsOwnedUnit(square) {
    const child = square.firstChild;
    if (child && child.className.includes(gmeta.position)) {
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
    for (const attr of unit.attributes || []) {
        className += ` ${attr}`;
    }
    el.className = className;
    if (unit.name) {
        el.dataset.name = unit.name;
    }
}
export function render_into(unit, el) {
    bindDetailsEvenet(unit, el);
    setClassName(unit, el);
    return renderTile(unit, el);
}
export function render(unit, index) {
    const unitEl = document.createElement('div');
    unitEl.dataset.index = index;
    render_into(unit, unitEl);
    return unitEl;
}
