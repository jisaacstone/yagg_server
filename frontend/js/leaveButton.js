import * as Dialog from './dialog.js';
import * as Element from './element.js';
import * as Request from './request.js';
import * as State from './state.js';
export function ensureCreated() {
    const existing = document.getElementById('leavebutton');
    if (existing) {
        existing.remove();
    }
    if (State.gmeta.boardstate === 'jobfair') {
        const leavebutton = Element.create({
            tag: 'button',
            id: 'leavebutton',
            innerHTML: 'leave',
            className: 'uibutton'
        });
        leavebutton.onclick = () => {
            Dialog.choices('You will lose this game. Return to lobby?', {
                leave,
                cancel: () => null
            });
        };
        document.getElementById('buttons').appendChild(leavebutton);
    }
    else if (['battle', 'placement'].includes(State.gmeta.boardstate)) {
        const leavebutton = Element.create({
            tag: 'button',
            id: 'leavebutton',
            innerHTML: 'concede',
            className: 'uibutton',
        });
        leavebutton.onclick = () => {
            Dialog.choices('You will lose this game. Return to lobby or propose rematch?', {
                leave,
                rematch: () => {
                    return Request.gameaction('concede', {}, 'board').then(() => {
                        return Request.gameaction('ready', {}, 'board');
                    });
                },
                cancel: () => null
            });
        };
        document.getElementById('buttons').appendChild(leavebutton);
    }
}
export function leave() {
    Request.gameaction('leave', {}, 'table').then(() => {
        window.location.href = 'index.html';
    }).catch((e) => {
        console.log({ error: e });
        window.location.href = 'index.html';
    });
}
