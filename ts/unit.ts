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
  attack: number;
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

function render_attrs(unit: Unit, el: HTMLElement) {
  for (const att of ['name', 'attack', 'defense']) {
    if (unit[att] !== null && unit[att] !== undefined) {
      const subel = document.createElement('span');
      subel.className = `unit-${att}`;
      subel.innerHTML = unit[att];
      el.appendChild(subel);
    }
  }
  if (unit.name === 'monarch') {
    el.className = `monarch ${el.className}`;
  }
}

function render_tile(unit: Unit, el: HTMLElement, attrs=false) {
  if (attrs) {
    render_attrs(unit, el);
  }
  el.style.backgroundImage = `url(img/${unit.name}.png)`;
  if (anyDetails(unit)) {
    el.addEventListener('sidebar', () => {
      const infobox = document.getElementById('infobox'),
        unitInfo = document.createElement('div');
      unitInfo.className = el.className + ' info';
      infoview(unit, unitInfo, el.parentNode as HTMLElement);
      infobox.innerHTML = '';
      infobox.appendChild(unitInfo);
    }, false);
  }
}

function anyDetails(unit) {
  return unit.name || unit.attack || unit.defense || unit.ability || unit.triggers;
}

function infoview(unit: Unit, el: HTMLElement, squareEl: HTMLElement) {
  render_attrs(unit, el);
  el.style.backgroundImage = `url(img/${unit.name}.png)`;
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
      if (name === 'move') {
        trigSym.innerHTML = Constants.MOVE;
      } else if (name === 'death') {
        trigSym.innerHTML = Constants.SKULL;
      } else if (name === 'attack') {
        trigSym.innerHTML = Constants.ATTACK;
      } else {
        console.log({warn: 'unknown trigger', name, trigger});
        trigSym.innerHTML = '?';
      }
      triggers.appendChild(trigSym);
    }
    el.appendChild(triggers);
  }
}

export function detailViewFn(unit: Unit, className: string, square: HTMLElement = null) {
  const details = document.createElement('div'),
    portrait = document.createElement('div');

  details.className = `${className} details`;
  render_attrs(unit, details);

  portrait.className = 'unit-portrait';
  portrait.style.backgroundImage = `url(img/${unit.name}.png)`;
  details.appendChild(portrait);

  if (unit.triggers) {
    const triggers = document.createElement('div');
    triggers.className = 'triggers';
    for (const [name, trigger] of Object.entries(unit.triggers)) {
      const triggerel = document.createElement('div');
      triggerel.className = 'trigger';
      triggers.appendChild(triggerel);
      triggerel.className = `unit-trigger ${name}-trigger`;
      triggerel.innerHTML = `${name} trigger: ${trigger.description}`;
    }
    details.appendChild(triggers);
  }

  if (unit.ability) {
    const ability = document.createElement('div'),
      abildesc = document.createElement('div'),
      abilname = document.createElement('div');
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
  }
}

function detailView(unit: Unit, el: HTMLElement) {
  const displaybut = document.createElement('button');

  displaybut.className = 'details-button';
  displaybut.innerHTML = '?';
  displaybut.onclick = detailViewFn(unit, el.className);
  el.appendChild(displaybut);
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
    detailViewFn(unit, el.className, square)(e);
  }; // @ts-ignore
  if (el.detailsEvent) {  // @ts-ignore
    el.removeEventListener('details', el.detailsEvent);
  } // @ts-ignore
  el.detailsEvent = eventListener;
  el.addEventListener('details', eventListener);
}

export function render_into(unit: Unit, el: HTMLElement, attrs=false): void {
  bindDetailsEvenet(unit, el);
  return render_tile(unit, el, attrs);
}

export function render(unit: Unit, index, attrs=false): HTMLElement {
  const unitEl = document.createElement('span');
  let className = `unit ${unit.player}`;
  if (unit.player === gmeta.position) {
    className += ' owned';
  }
  unitEl.className = className;
  unitEl.dataset.index = index;
  render_into(unit, unitEl, attrs);
  return unitEl
}
