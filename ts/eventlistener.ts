import { getname, tableid, hostname } from './urlvars.js';
import * as Player from './player.js';
import { handlers } from './event.js';
import type { ServerEvent, EventHandler } from './protocol.js';

export const state: {
  eventListener: WebSocket | null;
  interval: number | null;
  timeout: number | null;
  queue: ServerEvent[];
} = {
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

function handleEvent(event: ServerEvent) {
  state.queue.push(event);
}

let waits = 0;

function handleNextEventQ(next: ServerEvent) {
  const handler = handlers[next.event] as ((e: ServerEvent) => EventHandler) | undefined;
  if (handler) {
    try {
      const animation = handler(next);
      return animation().then(() => {
        return 'resolved';
      }).catch((error) => {
        console.error({error, next});
        return 'rejected';
      });
    } catch (error) {
      console.error({error, next});
    }
  } else {
    console.warn({msg: `no event handler for ${next.event}`, next});
  }
  return Promise.resolve('errored');
}

export function readEventQueu(delay = 50) {
  const next = state.queue.shift();
  if (next) {
    return handleNextEventQ(next).then(() => {
      return readEventQueu();
    });
  } else {
    state.timeout = window.setTimeout(readEventQueu, delay, Math.min(delay * 2, 300));
  }
}

function createWSEventListener() {
  const host = hostname(),
    wshost = host.replace('http', 'ws');
  Player.get().then(({ id }) => {
    state.eventListener = new WebSocket(`${wshost}/ws/${tableid()}/${id}`);

    state.eventListener.onmessage = (event) => {
      const evt = JSON.parse(event.data) as ServerEvent;
      handleEvent(evt);
    };

    state.eventListener.onopen = (event) => {
      state.interval = setInterval(
        () => state.eventListener.send('ping'),
        10000
      );
    }
    state.eventListener.onclose = (event) => {
      clearInterval(state.interval);
    }
    state.eventListener.onerror = (event) => {
      console.error({ wscb: 'onerror', event });
      clearInterval(state.interval);
    }
  });
}
