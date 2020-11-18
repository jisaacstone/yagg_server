import { select } from './select.js';
import { gmeta } from './state.js';
import * as Event from './event.js';

export function render(el: HTMLElement, width=5, height=5) {
  console.log('b2h');
  el.innerHTML = '';
  function makerow(y: number) {
    let row = document.createElement('div'),
      className = 'boardrow';
    if (y === 0 || y === 1) {
      className += ' southrow startrow';
    } else if (y === height - 1 || y === height - 2) {
      className += ' northrow startrow';
    }
    row.className = className;
    el.appendChild(row);

    function makesquare(x: number) {
      let square = document.createElement('div')
      square.className = 'boardsquare';
      square.id = `c${x}-${y}`;
      square.onclick = select(square, {x, y, ongrid: true});
      row.appendChild(square);
    }

    if (gmeta.position === 'north') {
      for (let x=width - 1; x >= 0; x--) {
        makesquare(x);
      }
    } else {
      for (let x=0; x < width; x++) {
        makesquare(x);
      }
    }
  }

  if (gmeta.position === 'south') {
    // reverse order
    for (let y=height - 1; y >= 0; y--) {
      makerow(y);
    }
  } else {
    for (let y=0; y < height; y++) {
      makerow(y);
    }
  }
}

export function square(x: number, y: number) {
  return document.getElementById(`c${x}-${y}`);
}

export function unitdata(unitdata) {
  for (const ob of unitdata.grid) {
    Event.new_unit(ob);
  }
  Array.prototype.forEach.call(
    Object.entries(unitdata.hand),
    ([index, card]: [string, any]) => {
      Event.add_to_hand({index: +index, unit: card.unit});
      if (card.assigned) {
        Event.unit_assigned({index: +index, x: card.assigned.x, y: card.assigned.y});
      }
    }
  );
}

export function clear() {
  const board = document.getElementById('board'),
    hand = document.getElementById('hand');
  board.innerHTML = '';
  hand.innerHTML = '';
}