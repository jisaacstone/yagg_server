import { request, post, gameaction } from './request.js';
import * as Player from './playerdata.js';
const displayedTables = {};
function fetchConfigs(sel_el) {
    request('configurations').then((configs) => {
        for (const config of Object.keys(configs)) {
            const opt = document.createElement('option');
            opt.innerHTML = config;
            sel_el.appendChild(opt);
        }
    });
}
function displayTableData(tablesEl, data) {
    if (!data.tables || !data.tables.length) {
        tablesEl.innerHTML = '<p>No open tables right now';
    }
    Player.get().then(({ name }) => {
        displayTables(tablesEl, data.tables, name);
    });
}
function renderTable(table, text) {
    const tblbtn = document.createElement('div'), dimensions = document.createElement('div'), module = document.createElement('div'), id = document.createElement('div'), txt = document.createElement('div');
    tblbtn.className = 'table';
    dimensions.className = 'dimensions';
    module.className = 'module';
    id.className = 'tableid';
    txt.className = 'tabletxt';
    dimensions.innerHTML = `${table.config.dimensions.x}x${table.config.dimensions.y}`;
    module.innerHTML = table.config.initial_module.split('.').pop();
    id.innerHTML = table.id;
    txt.innerHTML = text;
    tblbtn.append(id);
    tblbtn.append(dimensions);
    tblbtn.append(module);
    tblbtn.append(txt);
    return tblbtn;
}
function displayTables(tablesEl, tables, currentName) {
    const toRemove = new Set(Object.keys(displayedTables));
    for (const table of tables) {
        if (currentName && table.players.some(({ name }) => name === currentName)) {
            if (toRemove.has(table.id)) {
                toRemove.delete(table.id);
                continue;
            }
            const el = renderTable(table, 'REJOIN');
            el.onclick = () => {
                window.location.href = `board.html?table=${table.id}`;
            };
            tablesEl.appendChild(el);
            displayedTables[table.id] = el;
        }
        else if (table.players.length < 2) {
            if (toRemove.has(table.id)) {
                toRemove.delete(table.id);
                continue;
            }
            const el = renderTable(table, 'JOIN');
            table.players.forEach(({ name }) => {
                const nel = document.createElement('div');
                nel.className = 'playername';
                nel.innerHTML = name;
                el.appendChild(nel);
            });
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
window.onload = function () {
    const ct = document.getElementById('createtable'), sel_el = document.getElementById('config');
    Player.check();
    fetchConfigs(sel_el);
    fetchTableData();
    window.setInterval(fetchTableData, 2000);
    ct.onclick = () => {
        const conf = sel_el.value || 'random';
        post('table/new', { configuration: conf }).then(({ id }) => {
            gameaction('join', {}, 'table', id).then(() => {
                window.location.href = `board.html?table=${id}`;
            });
        });
    };
};
