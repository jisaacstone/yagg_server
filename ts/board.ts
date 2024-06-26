import { select } from './select.js';
import { gmeta } from './state.js';
import * as Event from './event.js';
import * as Element from './element.js';

export interface Coord {
  x: number;
  y: number;
}

interface Dimensions {
  width: number;
  height: number;
}

export interface Config {
  dimensions: Dimensions;
  name: string;
}

export function squareId(coord: Coord): string {
  return `c${coord.x}-${coord.y}`;
}

export function render(el: HTMLElement, dimensions: Dimensions) {
  el.innerHTML = '';
  function makerow(y: number) {
    let row = document.createElement('div'),
      className = 'boardrow';
    if (y === 0 || y === 1) {
      className += ' southrow';
    } else if (y === dimensions.height - 1 || y === dimensions.height - 2) {
      className += ' northrow';
    }
    row.className = className;
    el.appendChild(row);

    function makesquare(x: number) {
      const square = Element.create({
        className: 'boardsquare',
        id: squareId({ x, y }),
      });
      square.onclick = select(square, {x, y, ongrid: true});
      row.appendChild(square);
    }

    if (gmeta.position === 'north') {
      for (let x=dimensions.width - 1; x >= 0; x--) {
        makesquare(x);
      }
    } else {
      for (let x=0; x < dimensions.width; x++) {
        makesquare(x);
      }
    }
  }

  if (gmeta.position === 'south') {
    // reverse order
    for (let y=dimensions.height - 1; y >= 0; y--) {
      makerow(y);
    }
  } else {
    for (let y=0; y < dimensions.height; y++) {
      makerow(y);
    }
  }

  el.style.backgroundImage = `url(img/grid_${dimensions.width}x${dimensions.height}_${gmeta.position}.png)`;
}

export function square(x: number, y: number): HTMLElement {
  const el = document.getElementById(squareId({ x, y }));
  if (!el) {
    throw new Error(`square ${x},${y} not found`)
  }
  return el;
}

export function thingAt(x: number, y: number, objType?: string): HTMLElement | null {
  const el = square(x, y),
    child = el.firstElementChild as HTMLElement;
  if (child) {
    if (objType && !child.className.includes(objType)) {
      throw new Error(`expected ${objType}, found ${child.className}`)
    }
    return child;
  }
  if (objType) {
    throw new Error(`expected ${objType}, found nothing`)
  }
  return null;
}

export function in_direction(direction: string, distance: number): {x: number, y: number} {
  if ((direction === 'north' && gmeta.position === 'south')  || (direction === 'south' && gmeta.position === 'north')) {
    return {x: 0, y: -distance};
  }
  if ((direction === 'south' && gmeta.position === 'south') || (direction === 'north' && gmeta.position === 'north')) {
    return {x: 0, y: distance};
  }
  if ((direction === 'east' && gmeta.position === 'south') || (direction === 'west' && gmeta.position === 'north')) {
    return {x: distance, y: 0};
  }
  if ((direction === 'west' && gmeta.position === 'south') || (direction === 'east' && gmeta.position === 'north')) {
    return {x: -distance, y: 0};
  }
  if ((direction === 'northeast' && gmeta.position === 'south')  || (direction === 'southwest' && gmeta.position === 'north')) {
    return {x: distance, y: -distance};
  }
  if ((direction === 'southeast' && gmeta.position === 'south') || (direction === 'northwest' && gmeta.position === 'north')) {
    return {x: distance, y: distance};
  }
  if ((direction === 'northwest' && gmeta.position === 'south') || (direction === 'southeast' && gmeta.position === 'north')) {
    return {x: -distance, y: -distance};
  }
  if ((direction === 'southwest' && gmeta.position === 'south') || (direction === 'northeast' && gmeta.position === 'north')) {
    return {x: -distance, y: distance};
  }
  throw new Error(`direction ${direction} unknown`)
}

// simulate events from unit state
export function unitdata({ grid, hand }) {
  for (const ob of grid) {
    Event.new_unit(ob)();
  }
  Array.prototype.forEach.call(
    Object.entries(hand),
    ([index, card]: [string, any]) => {
      Event.add_to_hand({index: +index, unit: card.unit})();
      if (card.assigned) {
        Event.unit_assigned({index: +index, x: card.assigned.x, y: card.assigned.y})();
      }
    }
  );
}

// clear board and hand
export function clear() {
  const board = document.getElementById('board');
  board.innerHTML = '';
}
