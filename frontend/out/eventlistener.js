import { getname, tableid, hostname } from './urlvars.js';
import * as Player from './playerdata.js';
const state = {
    eventListener: null,
    interval: null
};
export function listen(eventHandlers, listener = 'websocket') {
    if (state.eventListener === null) {
        console.log('creating event listener');
        if (listener === 'websocket') {
            createWSEventListener(eventHandlers);
        }
        else {
            createSSEventListener(eventHandlers);
        }
    }
}
function createWSEventListener(eventHandlers) {
    const host = hostname();
    Player.get().then(({ id }) => {
        state.eventListener = new WebSocket(`ws://${host}/ws/${tableid()}/${id}`);
        state.eventListener.onmessage = (event) => {
            console.log({ event });
            const evt = JSON.parse(event.data);
            if (eventHandlers[evt.event]) {
                eventHandlers[evt.event](evt);
            }
            else {
                console.log({ msg: `no event handler for ${evt.event}`, evt });
            }
        };
        state.eventListener.onopen = (event) => {
            state.interval = setInterval(() => state.eventListener.send('ping'), 10000);
        };
        state.eventListener.onclose = (event) => {
            console.log({ wscb: 'onclose', event });
            clearInterval(state.interval);
        };
        state.eventListener.onerror = (event) => {
            console.log({ wscb: 'onerror', event });
            clearInterval(state.interval);
        };
    });
}
function createSSEventListener(eventHandlers) {
    const host = hostname();
    const playername = getname();
    state.eventListener = new EventSource(`http://${host}/sse/table/${tableid()}/events?player=${playername}`);
    state.eventListener.addEventListener('game_event', function (ssevent) {
        console.log({ ssevent });
        const evt = JSON.parse(ssevent.data);
        if (eventHandlers[evt.event]) {
            eventHandlers[evt.event](evt);
        }
        else {
            console.log({ msg: `no event handler for ${evt.event}`, evt });
        }
    });
}
