import { gameaction } from './request.js';
import { SKULL, MOVE } from './constants.js';
import { gmeta, isYourTurn } from './state.js';
import { displayerror } from './err.js';
import { dismissable } from './overlay.js';

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

function ability_button(unit: Unit, el: HTMLElement) {
  const abilbut = document.createElement('button'),
    tt = document.createElement('span'),
    abilname = unit.ability.name;

  abilbut.className = 'unit-ability';
  abilbut.innerHTML = abilname;

  abilbut.onclick = (e) => {
    const square = el.parentNode as HTMLElement;
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
      const x = +square.id.charAt(1),
        y = +square.id.charAt(3);
      gameaction('ability', {x: x, y: y}, 'board').catch(({ request }) => {
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

function render_attrs(unit: Unit, el: HTMLElement) {
  for (const att of ['name', 'attack', 'defense']) {
    const subel = document.createElement('span');
    subel.className = `unit-${att}`;
    subel.innerHTML = unit[att];
    el.appendChild(subel);
  }
  if (unit.name === 'monarch') {
    el.className = `monarch ${el.className}`;
  }
}

function render_tile(unit: Unit, el: HTMLElement) {
  render_attrs(unit, el);
  el.style.backgroundImage = `url(img/${unit.name}.png)`;
  if (unit.ability) {
    ability_button(unit, el);
  }
  detailView(unit, el);
}

function detailView(unit: Unit, el: HTMLElement) {
  const details = document.createElement('div'),
    portrait = document.createElement('div'),
    displaybut = document.createElement('button');

  details.className = `${el.className} details`;
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
  }

  displaybut.className = 'details-button';
  displaybut.innerHTML = '?';
  displaybut.onclick = (e) => {
    e.preventDefault();
    e.stopPropagation();
    dismissable(details);
  }
  el.appendChild(displaybut);
}

export function render_into(unit: Unit, el: HTMLElement): void {
  return render_tile(unit, el);
}

export function render(unit: Unit, index): HTMLElement {
  const unitEl = document.createElement('span');
  let className = `unit ${unit.player}`;
  if (unit.player === gmeta.position) {
    className += ' owned';
  }
  unitEl.className = className;
  unitEl.dataset.index = index;
  render_into(unit, unitEl);
  return unitEl
}
