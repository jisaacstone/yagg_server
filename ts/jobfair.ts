import * as Unit from './unit.js';
import * as Event from './event.js';
import * as Element from './element.js';
import { displayerror } from './err.js';
import { gameaction } from './request.js';
import * as Ready from './ready.js';
import { gmeta } from './state.js';
import * as Instructions from './instructions.js';

const state = {
  selected: new Set(),
  ready: 'not',
  armySize: 0
}

export function render(armySize: number) {
  const jfel = Element.getElement('jobfair'),
    jobfair = jfel || document.createElement('div'),
    counter = getCounter(),
    table = Element.getElement('table');

  jobfair.innerHTML = '';

  jobfair.id = 'jobfair';
  table.appendChild(jobfair);

  if (!armySize) {
    if (state.armySize) {
      armySize = state.armySize;
    } else {
      console.warn({err: 'noarmysize', state, armySize});
    }
  } else {
    state.armySize = armySize;
  }
  Instructions.dropdown('jobfair', `recruit ${armySize} units for your army`);
  counter.innerHTML = `${armySize}`;
  state.ready = 'not';
  state.selected = new Set();
}

export function clear() {
  const jobfair = Element.getElement('jobfair');
  if (jobfair) {
    jobfair.remove();
  }
}

function getCounter(): HTMLElement {
  const counter = Element.getElement('counter');
  if (counter) {
    return counter;
  }
  const c = document.createElement('div');
  c.id = 'counter';
  Element.getElement('buttons').appendChild(c);
  return c;
}

function countDown() {
  const counter = Element.getElement('counter');
  counter.innerHTML = `${state.armySize - state.selected.size}`;
  if (state.selected.size == state.armySize) {
    Ready.display(
      'recruit',
      () => {
        state.ready = 'READY';
        counter.remove();
        gameaction(
          'recruit',
          {units: Array.from(state.selected)},
          'table'
        ).then(() => {
          Ready.waiting();
        }).catch(({ request }) => {
          state.ready = 'not';
          if (request.status === 400) {
            displayerror(request.responseText);
          }
        });
      }
    );
    state.ready = 'displayed';
  }
}

export function select(index) {
  if (state.ready === 'ready') {
    return false;
  }
  if (state.selected.size >= state.armySize) {
    displayerror(`you may only recruit ${state.armySize}`);
    return false;
  }
  state.selected.add(index);
  if (state.ready === 'not') {
    countDown();
  }
  return true;
}

export function deselect(index) {
  if (state.ready === 'ready') {
    return false;
  }
  const counter = Element.getElement('counter');
  state.selected.delete(index);
  counter.innerHTML = `${state.armySize - state.selected.size}`;
  if (state.ready === 'displayed' && state.selected.size < state.armySize) {
    Ready.hide();
    state.ready = 'not';
  }
  return true;
}

export function unitdata(unitdata) {
  for (let [index, unit] of Object.entries(unitdata.choices) as [string, Unit.KnownUnit][]) {
    Event.candidate({ event: 'candidate', index: +index, unit })();
  }
  for (let index of unitdata.chosen) {
    Element.getElement(`candidate-${index}`).dataset.uistate = 'selected';
    select(index);
  }
  if (unitdata.ready) {
    state.ready = 'ready';
  }
}
