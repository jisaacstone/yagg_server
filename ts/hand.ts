import * as Unit from './unit.js';
import * as Select from './select.js';
import * as Element from './element.js';

export function createCard(unit: Unit.Unit, index: number): HTMLElement {
  const hand = document.getElementById('hand'),
    card = document.createElement('span'),
    unitEl = Unit.render(unit, index);
  card.dataset.index = `${index}`;
  card.className = 'card';
  Select.bind_hand(card, index, unit);
  hand.prepend(card);
  card.appendChild(unitEl);
  return unitEl;
}

export function clear() {
  const hand = document.getElementById('hand');
  while (hand.firstChild) {
    hand.firstChild.remove();
  }
}
