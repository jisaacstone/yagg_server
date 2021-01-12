import { gameaction } from './request.js';
import * as Constants from './constants.js';
import { gmeta, isYourTurn } from './state.js';
import { displayerror } from './err.js';
import { dismissable, clear } from './overlay.js';
import * as Select from './select.js';
import * as Dialog from './dialog.js';
import * as Element from './element.js';
import * as Triggers from './triggers.js';

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
  attributes: string[];
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

function ability_button(unit: Unit, el: HTMLElement, unitSquare: HTMLElement = null) {
  const abilbut = Element.create({
    tag: 'button',
    className: 'unit-ability',
    innerHTML: unit.ability.name,
    children: [
      Element.create({
        className: 'tooltip',
        innerHTML: unit.ability.description})
    ]}),
    square = unitSquare ? unitSquare : el.parentNode as HTMLElement;

  bindAbility(abilbut, square, unit);
  el.appendChild(abilbut);
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
    } else {
      console.error({ att, val: unit[att]});
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

function infoview(unit: Unit, el: HTMLElement, squareEl: HTMLElement) {
  renderAttrs(unit, el);
  el.style.backgroundImage = `url("img/${unit.name}.png")`;
  el.onclick = detailViewFn(unit, el.className, squareEl);
  if (unit.ability) {
    ability_button(unit, el, squareEl);
  }
  if (unit.triggers && Object.keys(unit.triggers).length !== 0) {
    const triggers = Element.create({ className: 'triggers' });
    for (const [name, trigger] of Object.entries(unit.triggers)) {
      triggers.appendChild(Element.create({
        className: 'trigger-symbol',
        innerHTML: Triggers.symbolFor(name),
        children: [
          Element.create({
            className: 'tooltip',
            innerHTML: `${Triggers.timingOf(name)}: ${trigger.description}`
          })
        ]})
      );
    }
    el.appendChild(triggers);
  }
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
]

function describe(unit: Unit, square: HTMLElement = null): HTMLElement {
  const descriptions = [];
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

  if (unit.triggers && Object.keys(unit.triggers).length > 0) {
    const triggers = Element.create({ className: 'triggers' });
    for (const [name, trigger] of Object.entries(unit.triggers)) {
      triggers.appendChild(Element.create({
        className: `unit-trigger ${name}-trigger`,
        children: [
          Element.create({
            className: 'trigger-symbol',
            innerHTML: Triggers.symbolFor(name),
            children: [
              Element.create({
                className: 'tooltip',
                innerHTML: Triggers.timingOf(name)
              })
            ]
          }),
          Element.create({
            className: 'trigger-description',
            innerHTML: `${trigger.description}`
          })
        ]
      }));
    }
    descriptions.push(triggers);
  }

  if (descriptions.length === 0) {
    const seed = unit.name.charCodeAt(0) + unit.name.charCodeAt(1) + unit.name.charCodeAt(2) + (gmeta.position || 'e').charCodeAt(0),
      desc = fakeDescriptions[seed % fakeDescriptions.length];
    descriptions.push(Element.create({ className: 'bio', innerHTML: desc }));
  }
  
  return Element.create({
    className: 'descriptions',
    children: descriptions
  });
}

export function detailViewFn(unit: Unit, className: string, square: HTMLElement = null) {
  console.log('dvf');
  const descriptions = describe(unit, square),
    portrait = Element.create({ className: 'unit-portrait' }),
    details = Element.create({
      className: `${className} details`,
      children: [descriptions, portrait]
    });
  
  renderAttrs(unit, details);
  portrait.style.backgroundImage = `url("img/${unit.name}.png")`;

  return (e) => {
    console.log('deets');
    e.preventDefault();
    e.stopPropagation();
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
  for (const attr of unit.attributes || []) {
    className += ` ${attr}`;
  }
  el.className = className;
}

export function render_into(unit: Unit, el: HTMLElement, attrs=false): void {
  bindDetailsEvenet(unit, el);
  setClassName(unit, el);
  return renderTile(unit, el, attrs);
}

export function render(unit: Unit, index, attrs=false): HTMLElement {
  const unitEl = document.createElement('div');
  unitEl.dataset.index = index;
  render_into(unit, unitEl, attrs);
  return unitEl
}
