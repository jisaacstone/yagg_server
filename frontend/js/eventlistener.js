import { tableid, hostname } from './urlvars.js';
import * as Player from './player.js';
import * as Event from './event.js';
export const state = {
    eventListener: null,
    interval: null,
    timeout: null,
    queue: [],
    animations: {},
};
export function listen() {
    if (state.eventListener === null) {
        createWSEventListener();
        state.timeout = window.setTimeout(readEventQueu, 50);
    }
}
function handleEvent(event) {
    state.queue.push(event);
}
let waits = 0;
//function awaitAnimations(result: Event.animData | null): Promise<any> {
//  if (! result || !result.squares) {
//    console.log({ result });
//    return Promise.resolve(true);
//  }
//  waits ++;
//  console.log({ squares: result.squares, animations: state.animations, waits });
//  const runAnimation = () => {
//    const aniPromise = result.animation();
//    for (const k of result.squares) {
//      state.animations[k] = aniPromise;
//    }
//  };
//  if (result.squares.some((k) => state.animations[k])) {
//    // animations already happening in some squares, wait
//    const promises = [], keys = [];
//    for (const [k, v] of Object.entries(state.animations)) {
//      promises.push(v);
//      keys.push(k);
//    }
//    console.log(`waiting ${waits}`);
//    return Promise.all(promises).then(() => {
//      console.log(`finished ${waits}`);
//      for (const k of keys) {
//        delete state.animations[k];
//      }
//      runAnimation();
//    }).catch((e) => {
//      console.log(`errors ${waits}`);
//      console.error(e);
//      for (const k of keys) {
//        delete state.animations[k];
//      }
//      runAnimation();
//    });
//  } else {
//    // no animation conflicts, start animations and read next event
//    runAnimation();
//    return Promise.resolve(true);
//  }
//}
//
//function handleNextEvent(next): Promise<string> {
//  if (Event[next.event]) {
//    try {
//      console.log({ running: next });
//      const result = Event[next.event](next);
//      return awaitAnimations(result).then(() => {
//        return 'resolved';
//      }).catch((error) => {
//        console.error({error, next});
//        return 'rejected';
//      });
//    } catch (error) {
//      console.error({error, next});
//    }
//  } else {
//    console.log({msg: `no event handler for ${next.event}`, next});
//  }
//  return Promise.resolve('errored');
//}
function handleNextEventQ(next) {
    if (Event[next.event]) {
        try {
            const { animation } = Event[next.event](next);
            return animation().then(() => {
                return 'resolved';
            }).catch((error) => {
                console.error({ error, next });
                return 'rejected';
            });
        }
        catch (error) {
            console.error({ error, next });
        }
    }
    else {
        console.log({ msg: `no event handler for ${next.event}`, next });
    }
    return Promise.resolve('errored');
}
export function readEventQueu(delay = 50) {
    const next = state.queue.shift();
    if (next) {
        return handleNextEventQ(next).then(() => {
            return readEventQueu();
        });
    }
    else {
        state.timeout = window.setTimeout(readEventQueu, delay, Math.min(delay * 2, 300));
    }
}
function createWSEventListener() {
    const host = hostname(), wshost = host.replace('http', 'ws');
    Player.get().then(({ id }) => {
        state.eventListener = new WebSocket(`${wshost}/ws/${tableid()}/${id}`);
        state.eventListener.onmessage = (event) => {
            const evt = JSON.parse(event.data);
            handleEvent(evt);
        };
        state.eventListener.onopen = (event) => {
            state.interval = setInterval(() => state.eventListener.send('ping'), 10000);
        };
        state.eventListener.onclose = (event) => {
            console.log({ wscb: 'onclose', event });
            clearInterval(state.interval);
        };
        state.eventListener.onerror = (event) => {
            console.error({ wscb: 'onerror', event });
            clearInterval(state.interval);
        };
    });
}
