import { gmeta } from './state.js';
const state = {
    timeout: null,
    el: null,
    interval: null,
};
export function set(time_in_ms, kind) {
    console.log({ timer: kind });
    if (state.el) {
        state.el.innerHTML = '';
    }
    state.el = getTimerEl(kind);
    state.timeout = Date.now() + time_in_ms;
    if (!state.interval) {
        state.interval = createInterval();
    }
}
export function stop() {
    if (state.el) {
        state.el.innerHTML = '';
    }
    if (state.interval) {
        window.clearTimeout(state.interval);
    }
    state.timeout = null;
    state.el = null;
    state.interval = null;
}
function getTimerEl(kind) {
    if (kind === gmeta.position) {
        return document.querySelector('#player .timer');
    }
    else if (kind === 'north' || kind === 'south') {
        return document.querySelector('#opponent .timer');
    }
    else {
        return document.querySelector('#timer');
    }
}
function createInterval() {
    return window.setInterval(() => {
        if (!state.el || !state.timeout) {
            return;
        }
        const now = Date.now(), diff = state.timeout - now;
        if (diff > 0) {
            const sec_rem = Math.round(diff / 1000);
            if (sec_rem < 20) {
                state.el.className = 'timer urgent';
            }
            else if (sec_rem > 100) {
                state.el.className = 'timer relaxed';
            }
            else {
                state.el.className = 'timer';
            }
            state.el.innerHTML = `${sec_rem}`;
        }
        else {
            state.el.innerHTML = '';
            state.el = null;
        }
    }, 1000);
}
