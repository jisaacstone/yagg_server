import { getname, tableid, hostname } from './urlvars.js';
import * as Player from './player.js';
import * as Event from './event.js';

export const state = {
  eventListener: null,
  interval: null,
  timeout: null,
  queue: [],
  animations: {},
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

function awaitAnimations(result: Event.animData | null): Promise<any> {
  if (! result || !result.squares) {
    return Promise.resolve(true);
  }
  const runAnimation = () => {
    const aniPromise = result.animation();
    for (const k of result.squares) {
      state.animations[k] = aniPromise;
    }
  };
  if (result.squares.some((k) => state.animations[k])) {
    // animations already happening in some squares, wait
    const promises = [];
    for (const [k, v] of Object.entries(state.animations)) {
      promises.push(v);
    }
    return Promise.all(promises).then(() => {
      state.animations = {};
      runAnimation();
    }).catch((e) => {
      console.error(e);
      state.animations = {};
      runAnimation();
    });
  } else {
    // no animation conflicts, start animations and read next event
    runAnimation();
    return Promise.resolve(true);
  }
}

function handleNextEvent(next): Promise<string> {
  if (Event[next.event]) {
    try {
      const result = Event[next.event](next);
      return awaitAnimations(result).then(() => {
        return 'resolved';
      }).catch((error) => {
        console.error({error, next});
        return 'rejected';
      });
    } catch (error) {
      console.error({error, next});
    }
  } else {
    console.log({msg: `no event handler for ${next.event}`, next});
  }
  return Promise.resolve('errored');
}

export function readEventQueu(delay = 50) {
  const next = state.queue.shift();
  if (next) {
    return handleNextEvent(next).then(() => {
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
      console.error({ wscb: 'onerror', event });
      clearInterval(state.interval);
    }
  });
}
