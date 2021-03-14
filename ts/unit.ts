import { gameaction, action } from './request.js';
import * as Constants from './constants.js';
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

interface Ability {
  name: string;
  description: string;
}

interface Triggers {
  move?: Ability;
  attack?: Ability;
  death?: Ability;
}

export interface Unit {
  name: string;
  attack: number | "immobile";
  defense: number;
  player: null | string;
  ability?: Ability;
  triggers?: Triggers;
  attributes: string[];
}

const units: {[key: string]: Unit} = {};

export function showName(coord: Board.Coord, name: string): void {
  const squareId = Board.squareId(coord),
    unitEl = document.querySelector(`#${squareId} .unit`) as HTMLElement,
    nameEl = document.querySelector(`#${squareId} .unit-name`);
  if (unitEl && !nameEl) {
    units[unitEl.id].name = name;
    unitEl.appendChild(Element.create({
      className: 'unit-name',
      innerHTML: convertAttr('name', name)
    }));
    unitEl.style.backgroundImage = `url("img/${name}.png")`;
  }
}

export function showAbility(coord: Board.Coord, ability: Ability): void {
  const squareId = Board.squareId(coord),
    unitEl = document.querySelector(`#${squareId} .unit`) as HTMLElement,
    abilityEl = document.querySelector(`#${squareId} .unit-abiltiy`);
  if (unitEl && !abilityEl) {
    units[unitEl.id].ability = ability;
    abilityIcon(unitEl, ability);
  }
}

export function showTriggers(coord: Board.Coord, triggers: Triggers): void {
  const squareId = Board.squareId(coord),
    unitEl = document.querySelector(`#${squareId} .unit`) as HTMLElement,
    triggerEl = document.querySelector(`#${squareId} .unit-abiltiy`);
  if (unitEl && !triggerEl) {
    // immobile, invisible, etc should never be revealed so we should be OK
    // with this type coercion
    units[unitEl.id].triggers = triggers;
    shortTriggers(unitEl, units[unitEl.id]);
  }
}

export function hilight(coord: Board.Coord, className: string): Promise<any> {
  const el = document.querySelector(`#${Board.squareId(coord)} .${className}`) as HTMLElement;
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
    }, 600);
  });
}

function bindAbility(abilityButton: HTMLElement, square: HTMLElement | null, unit: Unit, cb = null) {
  abilityButton.onclick = (e) => {
    if (! owned(unit)) {
      return;
    }
    SFX.play('ability');
    if (square === null) {
      square = abilityButton.parentNode.parentNode as HTMLElement;
    }
    if (
      gmeta.boardstate !== 'battle' ||
      !isYourTurn() ||
      !square ||
      !square.className.includes('boardsquare')
    ) {
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
      const x = +square.id.charAt(1),
        y = +square.id.charAt(3);
      gameaction('ability', {x: x, y: y}, 'board').catch(({ request }) => {
        if (request.status === 400) {
          displayerror(request.responseText);
        }
      });
    });
  };
}

function abilityButton(unit: Unit, el: HTMLElement, unitSquare: HTMLElement = null) {
  const abilbut = Element.create({
      tag: 'button',
      className: 'unit-ability',
      innerHTML: unit.ability.name,
    }),
    square = unitSquare ? unitSquare : el.parentNode as HTMLElement;

  if (owned(unit)) {
    bindAbility(abilbut, square, unit);
  }
  el.appendChild(abilbut);
}

function owned({ player }) {
  return player === gmeta.position;
}

function abilityIcon(el: HTMLElement, ability: Ability): void {
  const abil = Element.create({
    className: 'unit-ability',
    innerHTML: ability.name,
  });

  Tooltip.addTooltip(abil, ability.description);
  el.appendChild(abil);
}

function convertAttr(att, value) {
  if (att === 'attack' && value === 'immobile') {
    return '-';
  }
  return `${value}`;
}

function renderAttrs(unit: Unit, el: HTMLElement) {
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

// Overlay Buttons

export function clearButtonOverlay() {
  const overlay = document.getElementById('overlayButtons');
  if ( overlay ) {
    overlay.remove();
  }
}

export function overlayInfo(el: HTMLElement) {
  const unit = units[el.id];
  console.log(unit);
  const qbutton = Element.create({
      tag: 'button',
      className: 'details-button uibutton',
      title: 'details',
    }),
    allButtons = [qbutton];
  qbutton.addEventListener('click', detailViewFn(el));
  if (owned(unit)) {
    if (unit.ability) {
      const abutton = Element.create({
        tag: 'button',
        className: 'ability-button uibutton',
        title: 'use ability',
      });
      bindAbility(abutton, el.parentNode as HTMLElement, unit, Select.deselect);
      allButtons.push(abutton);
    }
    if (gmeta.boardstate === 'placement') {
      const rbutton = Element.create({
        tag: 'button',
        className: 'return-button uibutton',
        title: 'return to hand',
      });
      rbutton.onclick = () => {
        SFX.play('click');
        action(
          'return',
          {index: +el.dataset.index},
          Select.deselect,
        )
      }
      allButtons.push(rbutton);
    }
  }

  el.appendChild(Element.create({ id: 'overlayButtons', children: allButtons }));
}

function renderTile(unit: Unit, el: HTMLElement) {
  // if we have no name we have nothing else
  if (unit.name) {
    renderAttrs(unit, el);
    shortTriggers(el, unit);
    el.style.backgroundImage = `url("img/${unit.name}.png")`;
    if (owned(unit)) {
      const qbutton = Element.create({
          tag: 'button',
          className: 'details-button',
          title: 'details',
        });
      qbutton.addEventListener('click', detailViewFn(el));
      el.appendChild(qbutton);
    }
  }
  if (unit.ability) {
    abilityIcon(el, unit.ability);
  }
}

function anyDetails(unit) {
  return unit.name || unit.attack || unit.defense || unit.ability || unit.triggers;
}

function shortTriggers(el: HTMLElement, unit: Unit) {
  const triggers = Triggers.get(unit),
    triggerEls = [];
  if ( triggers.length === 0 ) {
    return;
  }
  for ( const { name, description, timing } of triggers ) {
    const tttext = timing ? `${timing}: ${description}` : description,
      ts = Element.create({className: `trigger-symbol ${name}-t`});
    Tooltip.addTooltip(ts, tttext);
    triggerEls.push(ts);
  }
  el.appendChild(Element.create({
    className: 'triggers',
    children: triggerEls
  }));
}

function infoview(unit: Unit, el: HTMLElement, squareEl: HTMLElement) {
  renderAttrs(unit, el);
  if (unit.name) {
    const qbutton = Element.create({
        tag: 'button',
        className: 'details-button uibutton',
        title: 'details',
      });
    el.appendChild(qbutton);
    el.style.backgroundImage = `url("img/${unit.name}.png")`;
  }
  el.onclick = detailViewFn(el, squareEl, unit);
  if (unit.ability) {
    abilityButton(unit, el, squareEl);
  }
  shortTriggers(el, unit);
}

function describe(unit: Unit, square: HTMLElement = null): HTMLElement {
  const descriptions = [],
    triggers = Triggers.get(unit);
  if (unit.ability) {
    const abilname = Element.create({
        className: 'ability-name uibutton',
        innerHTML: unit.ability.name,
      }),
      abildesc = Element.create({
        className: 'ability-description',
        innerHTML: unit.ability.description
      }),
      ability = Element.create({
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
    for ( const { name, description, timing } of triggers ) {
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
    descriptions.push(Element.create({ className: 'bio', innerHTML: 'No ability or triggers' }));
  }

  return Element.create({
    className: 'descriptions',
    children: descriptions
  });
}

export function detailViewFn(el: HTMLElement, square: HTMLElement = null, unit = null) {
  if (unit === null) {
    unit = units[el.id];
  }

  return (e) => {
    e.preventDefault();
    e.stopPropagation();
    console.log({ unit, s: units[el.id], id: el.id, units });

    SFX.play('click');
    const descriptions = describe(unit, square),
      portrait = Element.create({ className: 'unit-portrait' }),
      details = Element.create({
        className: `${el.className} details`,
        children: [descriptions, portrait]
      });

    renderAttrs(unit, details);
    portrait.style.backgroundImage = `url("img/${unit.name}.png")`;

    dismissable(details);
  }
}

export function isImmobile(square: HTMLElement) {
  const child = square.firstChild as HTMLElement;
  return containsOwnedUnit(square) && child.className.includes('immobile');
}

export function containsEnemyUnit(square: HTMLElement) {
  const child = square.firstChild as HTMLElement,
    position = gmeta.position === 'north' ? 'south' : 'north';
  if (child && child.className.includes(position)) {
    return true;
  }
  return false;
}

export function containsOwnedUnit(square: HTMLElement) {
  const child = square.firstChild as HTMLElement;
  if (child && child.className.includes(gmeta.position)) {
    return true;
  }
  return false;
}

export function indexOf(square: HTMLElement) {
  const child = square.firstChild as HTMLElement;
  return child && +child.dataset.index;
}

function bindDetailsEvenet(unit: Unit, el: HTMLElement) {
  const eventListener = (e) => {
    const parent = el.parentNode as HTMLElement,
      square = parent.className.includes('boardsquare') ? parent : null;
    detailViewFn(el, square)(e);
  }; // @ts-ignore
  if (el.detailsEvent) {  // @ts-ignore
    el.removeEventListener('details', el.detailsEvent); // @ts-ignore
    el.removeEventListener('dblclick', el.detailsEvent);
  } // @ts-ignore
  el.detailsEvent = eventListener;
  el.addEventListener('details', eventListener);
  el.addEventListener('dblclick', eventListener);
}

function setClassName(unit: Unit, el: HTMLElement) {
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

const addId = (() => {
  let nextId = 1;
  return (unit: Unit, el: HTMLElement): void => {
    if (! el.id) {
      el.id = `unit${nextId}`;
      nextId++;
      units[el.id] = unit;
    } else {
      Object.assign(units[el.id], unit);
    }
  }
})();

export function render_into(unit: Unit, el: HTMLElement): void {
  addId(unit, el);
  bindDetailsEvenet(unit, el);
  setClassName(unit, el);
  return renderTile(unit, el);
}

export function render(unit: Unit, index): HTMLElement {
  const unitEl = document.createElement('div');
  unitEl.dataset.index = index;
  render_into(unit, unitEl);
  return unitEl
}
