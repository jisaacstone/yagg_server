import { gmeta } from './state.js';
import * as Element from './element.js';

const state = {
  timeout: null,
  el: null,
  interval: null,
}

export function set(time_in_ms: number, kind: string) {
  if (state.el) {
    state.el.remove();
  }
  state.el = getTimerEl(kind);
  state.timeout = Date.now() + time_in_ms;
  if (! state.interval ) {
    state.interval = createInterval();
  }
}

export function stop() {
  if (state.el) {
    state.el.remove();
  }
  if (state.interval) {
    window.clearTimeout(state.interval);
  }
  state.timeout = null;
  state.el = null;
  state.interval = null;
}

function getTimerEl(kind: string) {
  const el = Element.create({ className: 'timer' });
  if (kind === gmeta.position) {
    document.getElementById('player').appendChild(el);
  } else if (kind === 'north' || kind === 'south') {
    document.getElementById('opponent').appendChild(el);
  } else {
    el.className = `${el.className} ${kind}timer`;
    document.getElementById('table').appendChild(el);
  }
  return el;
}

function createInterval() {
  return window.setInterval(() => {
      if ( ! state.el || ! state.timeout ) {
        return;
      }
      const now = Date.now(),
        diff = state.timeout - now;
      if (diff > 0) {
        state.el.innerHTML = `${Math.round(diff / 1000)}`;
      } else {
        state.el.remove()
        state.el = null;
      }
    },
    1000
  );
}
