import * as Event from './event.js';
const state = {
    min: 0,
    max: 0
};
export function render(min, max, units) {
    const jobfair = document.createElement('div'), board = document.getElementById('board');
    jobfair.id = 'jobfair';
    board.appendChild(jobfair);
    console.log({ step: 'jobfair', min, max, units });
    state.min = min;
    state.max = max;
    for (let [index, unit] of Object.entries(units)) {
        Event.candidate({ index, unit });
    }
}
export function unitdata(unitdata) {
    console.log({ unitdata });
}
