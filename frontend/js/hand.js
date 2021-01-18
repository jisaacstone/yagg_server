import * as Unit from './unit.js';
import * as Select from './select.js';
export function createCard(unit, index) {
    const hand = document.getElementById('hand'), card = document.createElement('span'), unitEl = Unit.render(unit, index, true, true);
    card.dataset.index = `${index}`;
    card.className = 'card';
    Select.bind_hand(card, index, unit.player, unit.attributes);
    hand.appendChild(card);
    card.appendChild(unitEl);
    return unitEl;
}
export function clear() {
    const hand = document.getElementById('hand');
    while (hand.firstChild) {
        hand.firstChild.remove();
    }
}
