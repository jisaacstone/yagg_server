import { request, gameaction } from './request.js';
import * as Player from './player.js';
import * as Element from './element.js';
import * as Settings from './settings.js';
import * as Dialog from './dialog.js';
import * as Soundtrack from './soundtrack.js';
import * as SFX from './sfx.js';
import * as CreateTable from './createTable.js';
const displayedTables = {};
const configurations = {};
function render() {
    const howto = Element.create({
        tag: 'a',
        className: 'uibutton',
        innerHTML: 'how to play'
    });
    howto.setAttribute('href', 'howto.html');
    document.body.appendChild(Element.create({ id: 'howto', children: [howto] }));
    document.body.appendChild(Element.create({ id: 'settings' }));
    document.body.appendChild(Element.create({ id: 'player' }));
    document.body.appendChild(Element.create({
        id: 'createdialog',
        children: [
            Element.create({ id: 'createtable', tag: 'button', className: 'uibutton', innerHTML: 'create new table' })
        ]
    }));
    document.body.appendChild(Element.create({
        id: 'tables',
        children: [
            Element.create({ tag: 'p', innerHTML: 'join a table' })
        ]
    }));
}
function displayTableData(tablesEl, data) {
    if (!data.tables || !data.tables.length) {
        tablesEl.innerHTML = '<p>No open tables right now';
    }
    Player.get().then(({ id }) => {
        displayTables(tablesEl, data.tables, +id);
    });
}
function renderTable({ configuration }, child) {
    return Element.create({
        className: 'table',
        children: [
            Element.create({
                className: 'config-name',
                innerHTML: configuration.name
            }),
            child
        ]
    });
}
function displayTables(tablesEl, tables, currentId) {
    const toRemove = new Set(Object.keys(displayedTables));
    for (const table of tables) {
        if (table.state === "gameover") {
            continue;
        }
        if (table.opts.type === "private") {
            continue;
        }
        if (currentId && table.players.some(({ player }) => player.id === currentId)) {
            if (toRemove.has(table.id)) {
                toRemove.delete(table.id);
                continue;
            }
            const el = renderTable(table, Element.create({ innerHTML: 'REJOIN' }));
            el.onclick = () => {
                window.location.href = `board.html?table=${table.id}`;
            };
            tablesEl.prepend(el);
            displayedTables[table.id] = el;
        }
        else if (table.players.length === 1 && !table.state) {
            if (toRemove.has(table.id)) {
                toRemove.delete(table.id);
                continue;
            }
            const el = renderTable(table, renderPlayer(table.players[0].player));
            el.onclick = () => {
                gameaction('join', {}, 'table', table.id).then(() => {
                    window.location.href = `board.html?table=${table.id}`;
                }).catch((e) => {
                    Dialog.alert('join failed, unknown error, please try again').then(() => {
                        //reload
                        window.location = window.location;
                    });
                });
            };
            tablesEl.appendChild(el);
            displayedTables[table.id] = el;
        }
    }
    toRemove.forEach((id) => {
        displayedTables[id].remove();
        delete displayTables[id];
    });
}
function fetchTableData() {
    const tables = document.getElementById('tables');
    request('table').then(tabledata => {
        console.log({ tabledata });
        displayTableData(tables, tabledata);
    }).catch((e) => console.log({ e }));
}
function renderPlayer({ id, name }) {
    const nameEl = Element.create({ className: 'playername', innerHTML: name }), avatarEl = Player.avatar({ id, name }), playerDetailsEl = Element.create({ className: 'playerdetails', children: [avatarEl, nameEl] });
    return playerDetailsEl;
}
window.onload = function () {
    render();
    const ct = document.getElementById('createtable');
    SFX.loadSettings();
    Soundtrack.loadSettings();
    Soundtrack.setSoundtrack('menu');
    const mml = () => {
        console.log('mml');
        Soundtrack.play();
        document.removeEventListener('click', mml);
    };
    document.addEventListener('click', mml);
    document.getElementById('settings').appendChild(Settings.button());
    Player.check().then((player) => {
        fetchTableData();
        window.setInterval(fetchTableData, 2000);
        document.getElementById('player').appendChild(renderPlayer(player));
        ct.onclick = () => {
            CreateTable.dialog();
        };
    });
};
