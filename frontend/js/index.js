import { request, post, gameaction } from './request.js';
import * as Player from './player.js';
import * as Element from './element.js';
import * as Err from './err.js';
const displayedTables = {};
const configurations = {};
function fetchConfigs(sel_el) {
    request('configurations').then((configs) => {
        for (const config of configs) {
            configurations[config.name] = config;
            sel_el.appendChild(Element.create({ tag: 'option', innerHTML: config.name }));
        }
        sel_el.addEventListener('change', () => {
            const configName = sel_el.value, configuration = configurations[configName], descriptionEl = document.getElementById('config-description');
            descriptionEl.innerHTML = configuration.description;
        });
    });
}
function displayTableData(tablesEl, data) {
    if (!data.tables || !data.tables.length) {
        tablesEl.innerHTML = '<p>No open tables right now';
    }
    Player.get().then(({ id }) => {
        displayTables(tablesEl, data.tables, +id);
    });
}
function renderTable({ config }, child) {
    return Element.create({
        className: 'table',
        children: [
            Element.create({
                className: 'config-name',
                innerHTML: config.name
            }),
            child
        ]
    });
}
function displayTables(tablesEl, tables, currentId) {
    const toRemove = new Set(Object.keys(displayedTables));
    for (const table of tables) {
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
        displayTableData(tables, tabledata);
    }).catch((e) => console.log({ e }));
}
function renderPlayer({ id, name }) {
    const nameEl = Element.create({ className: 'playername', innerHTML: name }), avatarEl = Player.avatar({ id, name }), playerDetailsEl = Element.create({ className: 'playerdetails', children: [avatarEl, nameEl] });
    return playerDetailsEl;
}
window.onload = function () {
    const ct = document.getElementById('createtable'), sel_el = document.getElementById('config');
    ct.style.display = 'hidden';
    sel_el.onchange = () => {
        if (sel_el.value) {
            sel_el.style.display = 'block';
        }
        else {
            sel_el.style.display = 'hidden';
        }
    };
    Player.get().then((player) => {
        fetchConfigs(sel_el);
        fetchTableData();
        window.setInterval(fetchTableData, 2000);
        document.getElementById('player').appendChild(renderPlayer(player));
        ct.onclick = () => {
            const conf = sel_el.value;
            if (!conf) {
                Err.displayerror('select a game type');
                return;
            }
            Player.check().then(() => {
                post('table/new', { configuration: conf }).then(({ id }) => {
                    gameaction('join', {}, 'table', id).then(() => {
                        window.location.href = `board.html?table=${id}`;
                    });
                });
            });
        };
    });
};
