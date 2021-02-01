const expect = require('chai').expect,
  Helper = require('./helper');
let Event, State, Board, Select;

describe('select', () => {
  before(function() {
    return Helper.setupJsdom('board.html').then(() => {
      Event = require('../frontend/js/event.js');
      State = require('../frontend/js/state.js');
      Board = require('../frontend/js/board.js');
      Select = require('../frontend/js/select.js');
    });
  });

  it('return to hand', () => {
    const event1 = {
      "unit": {
        "triggers": {
          "move": {
            "name": "immobile",
            "description": "Cannot move\n",
            "args": {}
          },
          "death": {
            "name": "concede",
            "description": "Lose the game",
            "args": {}
          }
        },
        "player": "north",
        "name": "northern colors",
        "defense": 0,
        "attributes": [
          "immobile",
          "monarch"
        ],
        "attack": "immobile",
        "ability": null
      },
      "index": 0,
      "event": "add_to_hand"
    };
    const event2 = {
      "unit": {
        "triggers": {},
        "player": "north",
        "name": "marshal",
        "defense": 6,
        "attributes": [],
        "attack": 9,
        "ability": null
      },
      "index": 6,
      "event": "add_to_hand"
    };
    const boardEl = document.getElementById('board');
    Board.render(boardEl, 5, 5);
    State.gmeta.boardstate = 'placement';
    State.gmeta.position = 'north';
    return Event.add_to_hand(event1).animation().then(() => {
      return Event.add_to_hand(event2).animation();
    }).then(() => {
      return Event.unit_assigned({y: 0, x: 2, index: 6, event: "unit_assigned"}).animation();
    }).then(() => {
      Board.thingAt(2, 0).click();
      let rb = document.getElementById('returnbutton');
      expect(rb.className).include('uibutton');

      // immobile object
      rb.remove();
      return Event.unit_assigned({y: 0, x: 3, index: 0, event: "unit_assigned"}).animation();
    }).then(() => {
      Board.thingAt(3, 0).click();
      rb = document.getElementById('returnbutton');
      expect(rb.className).include('uibutton');
    });
  });
});
