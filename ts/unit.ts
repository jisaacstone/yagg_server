import { gameaction } from './request.js';
import * as Constants from './constants.js';
import { gmeta, isYourTurn } from './state.js';
import { displayerror } from './err.js';
import { dismissable, clear } from './overlay.js';
import * as Select from './select.js';

interface Ability {
  name: string;
  description: string;
}

export interface Unit {
  name: string;
  attack: number | "immobile";
  defense: number;
  player: null | string;
  ability: null | Ability;
  triggers: null | {
    move?: Ability;
    death?: Ability;
  };
}

function bindAbility(abilityButton: HTMLElement, square: HTMLElement, unit: Unit, cb = null) {
  abilityButton.onclick = (e) => {
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
    if (window.confirm(unit.ability.description)) {
      Select.deselect();
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
    }
  };
}

function ability_button(unit: Unit, el: HTMLElement, unitSquare: HTMLElement = null) {
  const abilbut = document.createElement('button'),
    tt = document.createElement('span'),
    abilname = unit.ability.name,
    square = unitSquare ? unitSquare : el.parentNode as HTMLElement;

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

function renderAttrs(unit: Unit, el: HTMLElement) {
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

function renderTile(unit: Unit, el: HTMLElement, attrs=false) {
  if (attrs) {
    renderAttrs(unit, el);
  }
  el.style.backgroundImage = `url("img/${unit.name}.png")`;
  // @ts-ignore
  if (el.sidebar) { // @ts-ignore
    el.removeEventListener('sidebar', el.sidebar, false);
  } // @ts-ignore
  el.sidebar = () => {
    const infobox = document.getElementById('infobox'),
      unitInfo = document.createElement('div');
    unitInfo.className = el.className + ' info';
    infoview(unit, unitInfo, el.parentNode as HTMLElement);
    infobox.innerHTML = '';
    infobox.appendChild(unitInfo);
    if (! anyDetails(unit)) {
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

function infoview(unit: Unit, el: HTMLElement, squareEl: HTMLElement) {
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
      const trigSym = document.createElement('div'),
        tt = document.createElement('span');
      trigSym.className = 'trigger-symbol';
      trigSym.innerHTML = symbolFor(name);
      triggers.appendChild(trigSym);
      tt.className = 'tooltip';
      tt.innerHTML = trigger.description;
      trigSym.appendChild(tt);
    }
    el.appendChild(triggers);
  }
}

function symbolFor(trigger: string): string {
  if (trigger === 'move') {
    return Constants.MOVE;
  }
  if (trigger === 'death') {
    return Constants.SKULL;
  }
  if (trigger === 'attack') {
    return Constants.ATTACK;
  }
  console.log({warn: 'unknown trigger', trigger});
  return '?';
}

export function detailViewFn(unit: Unit, className: string, square: HTMLElement = null) {
  const details = document.createElement('div'),
    portrait = document.createElement('div'),
    descriptions = document.createElement('div');

  details.className = `${className} details`;
  renderAttrs(unit, details);

  portrait.className = 'unit-portrait';
  portrait.style.backgroundImage = `url("img/${unit.name}.png")`;
  details.appendChild(portrait);

  descriptions.className = 'descriptions';
  details.appendChild(descriptions);

  if (unit.ability) {
    const ability = document.createElement('div'),
      abildesc = document.createElement('div'),
      abilname = document.createElement('div');
    ability.className = 'unit-ability';
    abilname.className = 'ability-name uibutton';
    abilname.innerHTML = unit.ability.name;
    abildesc.className = 'ability-description';
    ability.appendChild(abilname);
    abildesc.innerHTML = unit.ability.description;
    ability.appendChild(abildesc);
    descriptions.appendChild(ability);
    if (square) {
      bindAbility(abilname, square, unit, clear);
    }
  }

  if (unit.triggers) {
    const triggers = document.createElement('div');
    triggers.className = 'triggers';
    for (const [name, trigger] of Object.entries(unit.triggers)) {
      const triggerel = document.createElement('div'),
        tsym = document.createElement('div'),
        tdes = document.createElement('div');
      triggerel.className = 'trigger';
      triggers.appendChild(triggerel);
      triggerel.className = `unit-trigger ${name}-trigger`;
      tsym.className = 'trigger-symbol';
      tsym.innerHTML = symbolFor(name);
      triggerel.appendChild(tsym);
      tdes.className = 'trigger-description';
      tdes.innerHTML = `${trigger.description}`;
      triggerel.appendChild(tdes);
    }
    descriptions.appendChild(triggers);
  }

  return (e) => {
    e.preventDefault();
    e.stopPropagation();
    dismissable(details);
  }
}

function detailView(unit: Unit, el: HTMLElement) {
  el.onclick = detailViewFn(unit, el.className);
}

export function isImmobile(square: HTMLElement) {
  const child = square.firstChild as HTMLElement;
  return containsOwnedUnit(square) && child.className.includes('immobile');
}

export function containsEnemyUnit(square: HTMLElement) {
  const child = square.firstChild as HTMLElement,
    position = gmeta.position === 'north' ? 'south' : 'north';
  if (child && child.className.includes(position)) {
    console.log('isenemy');
    return true;
  }
  return false;
}

export function containsOwnedUnit(square: HTMLElement) {
  const child = square.firstChild as HTMLElement;
  if (child && child.className.includes(gmeta.position)) {
    console.log('isowned');
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
    detailViewFn(unit, el.className, square)(e);
  }; // @ts-ignore
  if (el.detailsEvent) {  // @ts-ignore
    el.removeEventListener('details', el.detailsEvent);
  } // @ts-ignore
  el.detailsEvent = eventListener;
  el.addEventListener('details', eventListener);
}

function setClassName(unit: Unit, el: HTMLElement) {
  let className = `unit ${unit.player}`;
  if (unit.player === gmeta.position) {
    className += ' owned';
  }
  if (unit.attack === 'immobile') {
    className += ' immobile';
  }
  el.className = className;
}

export function render_into(unit: Unit, el: HTMLElement, attrs=false): void {
  bindDetailsEvenet(unit, el);
  setClassName(unit, el);
  return renderTile(unit, el, attrs);
}

export function render(unit: Unit, index, attrs=false): HTMLElement {
  const unitEl = document.createElement('span');
  unitEl.dataset.index = index;
  render_into(unit, unitEl, attrs);
  return unitEl
}
