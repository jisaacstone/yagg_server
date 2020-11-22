import * as Event from './event.js';
import { displayerror } from './err.js';
import { gameaction } from './request.js';
import * as readyButton from './ready.js';
import * as Instructions from './instructions.js';
const state = {
    selected: new Set(),
    ready: 'not',
    armySize: 0
};
export function render(armySize) {
    const jfel = document.getElementById('jobfair'), jobfair = jfel || document.createElement('div'), instructions = document.createElement('div'), table = document.getElementById('table');
    jobfair.innerHTML = '';
    jobfair.id = 'jobfair';
    table.appendChild(jobfair);
    if (!armySize) {
        if (state.armySize) {
            armySize = state.armySize;
        }
        else {
            console.log({ err: 'noarmysize', state, armySize });
        }
    }
    else {
        state.armySize = armySize;
    }
    Instructions.dropdown('jobfair', `recruit ${armySize} units for your army`);
    state.ready = 'not';
    state.selected = new Set();
}
export function clear() {
    const jobfair = document.getElementById('jobfair');
    if (jobfair) {
        jobfair.remove();
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
    if (state.ready === 'not' && state.selected.size == state.armySize) {
        readyButton.display('RECRUIT', () => {
            state.ready = 'ready';
            gameaction('recruit', { units: Array.from(state.selected) }, 'table').then(() => {
                readyButton.hide();
            }).catch(({ request }) => {
                state.ready = 'not';
                if (request.status === 400) {
                    displayerror(request.responseText);
                }
            });
        });
        state.ready = 'displayed';
    }
    return true;
}
export function deselect(index) {
    if (state.ready === 'ready') {
        return false;
    }
    state.selected.delete(index);
    if (state.ready === 'displayed' && state.selected.size < state.armySize) {
        readyButton.hide();
        state.ready = 'not';
    }
    return true;
}
export function unitdata(unitdata) {
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
