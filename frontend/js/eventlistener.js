import { tableid, hostname } from './urlvars.js';
import * as Player from './player.js';
import * as Event from './event.js';
export const state = {
    eventListener: null,
    interval: null,
    timeout: null,
    queue: [],
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
function handleNextEventQ(next) {
    if (Event[next.event]) {
        console.log(next);
        try {
            const animation = Event[next.event](next);
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
