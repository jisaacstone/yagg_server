import { request, post, gameaction } from './request.js';
import * as Player from './playerdata.js';
import * as Element from './element.js';
import * as Err from './err.js';

const displayedTables = {};
const configurations = {};

function fetchConfigs(sel_el: HTMLInputElement) {
  request('configurations').then(
    (configs: any) => {
      for (const config of configs) {
        configurations[config.name] = config
        sel_el.appendChild(
          Element.create({ tag: 'option', innerHTML: config.name }));
      }
      sel_el.addEventListener('change', () => {
        const configName = sel_el.value,
          configuration = configurations[configName],
          descriptionEl = document.getElementById('config-description');
        descriptionEl.innerHTML = configuration.description;
      })
    }
  );
}

function displayTableData(tablesEl, data) {
  if (! data.tables || ! data.tables.length) {
    tablesEl.innerHTML = '<p>No open tables right now';
  }
  Player.get().then(({ name }) => {
    displayTables(tablesEl, data.tables, name);
  });
}

function renderTable({ config }, text: string): HTMLElement {
  return Element.create({
    className: 'table',
    children: [
      Element.create({
        className: 'config-name',
        innerHTML: config.name}),
      Element.create({
        className: 'dimensions',
        innerHTML: `${config.dimensions.x}x${config.dimensions.y}`}),
      Element.create({
        className: 'tabletxt',
        innerHTML: text})]});
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
      tablesEl.prepend(el);
      displayedTables[table.id] = el;
    } else if (table.players.length < 2) {
      if (toRemove.has(table.id)) {
        toRemove.delete(table.id);
        continue;
      }
      const el = renderTable(table, 'JOIN');
      table.players.forEach(({ name }) => {
        el.appendChild(Element.create({ className: 'playername', innerHTML: name }));
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

window.onload = function() {
  const ct = document.getElementById('createtable'),
    sel_el = document.getElementById('config') as HTMLInputElement;

  ct.style.display = 'hidden';
  sel_el.onchange = () => {
    if (sel_el.value) {
      sel_el.style.display = 'block';
    } else {
      sel_el.style.display = 'hidden';
    }
  }

  Player.check().then(() => {
    fetchConfigs(sel_el);
    fetchTableData();
    window.setInterval(fetchTableData, 2000);

    ct.onclick = () => {
      const conf = sel_el.value;
      if (! conf) {
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
