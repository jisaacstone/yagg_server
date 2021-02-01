const expect = require('chai').expect,
  Helper = require('./helper');
let Event, EventListener, Board;

describe('event', () => {
  before(function() {
    return Helper.setupJsdom('board.html').then(() => {
      Event = require('../frontend/js/event.js');
      EventListener = require('../frontend/js/eventlistener.js');
      Board = require('../frontend/js/board.js');
    });
  });

  it('electromouse', () => {
    const boardEl = document.getElementById('board');
    Board.render(boardEl, 5, 5);
    EventListener.state.queue = [
      {
        x: 3,
        y: 1,
        unit: {
          name: 'electromouse trap',
          attack: 3,
          defense: 4,
          player: 'north',
          ability: null,
          triggers: {}
        },
        event: "new_unit"
      },
      {
        to: {
          y: 1,
          x: 2
        },
        from: {
          y: 1,
          x: 3
        },
        event: "thing_moved"
      },
      {
        y: 1,
        x: 2,
        unit: {
          triggers: {},
          player: "south",
          name: "electromouse",
          defense: 4,
          attributes: [],
          attack: 3,
          ability: {
            name: "mousetrap",
            description: "Set an invisible trap in the current square that captures units\n",
            args: {}
          }
        },
        event: "unit_changed"
      },
      {
        y: 1,
        x: 3,
        unit: {
          triggers: {
            move: {
              name: "immobile",
              description: "Cannot move\n",
              args: {}
            },
            death: {
              name: "trap",
              description: "Invisible. Captures attacker, giving you control\n",
              args: {}
            }
          },
          player: "south",
          name: "electromousetrap",
          defense: 0,
          attributes: [
            "immobile",
            "invisible"
          ],
          attack: "immobile",
          ability: null
        },
        event: "new_unit"
      }
    ];

    window.setTimeout = () => null;

    return EventListener.readEventQueu().then(() => {
      const c21 = Board.thingAt(2, 1),
        c31 = Board.thingAt(3, 1);
      expect(c31.dataset.name).equal('electromousetrap');
      expect(c21.dataset.name).equal('electromouse');
    });
  });

  it('new_unit', () => {
    const boardEl = document.getElementById('board');
    const testEvent = {
      x: 2,
      y: 0,
      unit: {
        name,
        attack: 1,
        defense: 0,
        player: 'north',
        ability: null,
        triggers: {}
      }
    };
    Board.render(boardEl, 5, 5);
    return Event.new_unit(testEvent).animation().then(() => {
      const square = Board.square(2, 0);
      expect(square.firstChild.className).include('north');
    });
  });

  it('unit_changed', () => {
    const boardEl = document.getElementById('board');
    const testEvent = {
      x: 2,
      y: 0,
      unit: {
        name,
        attack: 1,
        defense: 0,
        player: 'north',
        ability: null,
        triggers: {}
      }
    };
    const updateEvent = {
      x: 2,
      y: 0,
      unit: {
        name: 'foo',
        attack: 5,
        defense: 0,
        player: 'north',
        ability: null,
        triggers: {}
      }
    };
    Board.render(boardEl, 5, 5);
    return Event.new_unit(testEvent).animation().then(() => {
      return Event.unit_changed(updateEvent).animation().then(() => {
        const unitName = document.querySelector('#c2-0 .unit-name');
        expect(unitName.firstChild.textContent).equal('foo');
      });
    });
  });
  it('moved offscreen', () => {
    const boardEl = document.getElementById('board');
    Board.render(boardEl, 5, 5);
    Event.feature({ x: 0, y: 1, feature: 'block' }).animation();
    const result = Event.thing_moved({ from: { x: 0, y: 1}, to: 'offscrean', direction: 'south' });
    expect(result.squares[0]).equal('0,1');
  });
  it('moved 0', () => {
    const boardEl = document.getElementById('board');
    Board.render(boardEl, 5, 5);
    return Event.feature({ x: 1, y: 1, feature: 'block' }).animation().then(() => {
      const result = Event.thing_moved({ from: { x: 1, y: 1}, to: { x: 0, y: 1 } });
      return result.animation().then(() => {
        expect(Board.thingAt(0, 1).className).include('block');
      });
    });
  });
  it('player joined', () => {
    localStorage.setItem('playerData.id', 1234);
    localStorage.setItem('playerData.name', 'testname');
    Event.player_joined({player: {id: 1234, name: 'testname'}, position: 'north'}).animation();
    Event.player_joined({player: {id: 5678, name: 'testname'}, position: 'south'}).animation();
    const pEl = document.querySelector('#player .playername'),
      oEl = document.querySelector('#opponent .playername');
    expect(pEl.innerHTML).include('testname');
    expect(oEl.innerHTML).include('testname');
  });
});
