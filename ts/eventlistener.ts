import { getname, tableid, hostname } from './urlvars.js';
import * as Player from './playerdata.js';
import * as Event from './event.js';

const state = {
  eventListener: null,
  interval: null,
  timeout: null,
  queue: [],
}

export function listen() {
  if (state.eventListener === null) {
    createWSEventListener();
    state.timeout = window.setTimeout(readEventQueu, 50);
  }
}

function handleEvent(event) {
  state.queue.push(event);
}

function readEventQueu(delay = 50) {
  const next = state.queue.shift();
  if (next) {
    if (Event[next.event]) {
      try {
        Event[next.event](next);
      } catch (error) {
        console.error({error, next});
      }
    } else {
      console.log({msg: `no event handler for ${next.event}`, next});
    }
    readEventQueu();
  } else {
    state.timeout = window.setTimeout(readEventQueu, delay, Math.min(delay * 2, 300));
  }
}

function createWSEventListener() {
  const host = hostname();
  Player.get().then(({ id }) => {
    state.eventListener = new WebSocket(`ws://${host}/ws/${tableid()}/${id}`);

    state.eventListener.onmessage = (event) => {
      const evt = JSON.parse(event.data);
      console.log(evt);
      handleEvent(evt);
    };

    state.eventListener.onopen = (event) => {
      state.interval = setInterval(
        () => state.eventListener.send('ping'),
        10000
      );
    }
    state.eventListener.onclose = (event) => {
      console.log({ wscb: 'onclose', event });
      clearInterval(state.interval);
    }
    state.eventListener.onerror = (event) => {
      console.log({ wscb: 'onerror', event });
      clearInterval(state.interval);
    }
  });
}
