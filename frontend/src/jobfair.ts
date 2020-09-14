import * as Unit from './unit.js';
import * as Event from './event.js';
import { displayerror } from './err.js';
import { gameaction } from './request.js';
import * as readyButton from './ready.js';

const state = {
  selected: new Set(),
  ready: 'not',
  min: 0,
  max: 0
}

export function render(min: number, max: number) {
  const jobfair = document.createElement('div'),
    board = document.getElementById('board');

  jobfair.id = 'jobfair';
  board.appendChild(jobfair);

  state.min = min;
  state.max = max;
}

export function select(index) {
  console.log({action: 'select', state});
  if (state.ready === 'ready') {
    return false;
  }
  if (state.selected.size === state.max) {
    displayerror(`you may only select up to ${state.max}`);
    return false;
  }
  state.selected.add(index);
  console.log({r: state.ready, s: state.selected.size, m: state.min});
  if (state.ready === 'not' && state.selected.size > state.min) {
    readyButton.display(
      'RECRUIT',
      () => {
        state.ready = 'ready';
        gameaction(
          'recruit',
          {units: Array.from(state.selected)},
          'table'
        ).then(() => {
          readyButton.hide();
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
  return true;
}

export function deselect(index) {
  console.log({action: 'deselect', state});
  if (state.ready === 'ready') {
    return false;
  }
  state.selected.delete(index);
  if (state.ready === 'displayed' && state.selected.size < state.min) {
    readyButton.hide();
  }
  return true;
}

export function unitdata(unitdata) {
  console.log({ unitdata });
  for (let [index, unit] of Object.entries(unitdata.choices)) {
    Event.candidate({ index, unit });
  }
  for (let index of unitdata.chosen) {
    document.getElementById(`candidate-${index}`).dataset.uistate = 'selected';
    select(index);
  }
  if (unitdata.ready) {
    state.ready = 'ready';
  }
}
