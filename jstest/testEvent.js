const expect = require('chai').expect,
  Event = require('../frontend/js/event.js'),
  Board = require('../frontend/js/board.js'),
  Helper = require('./helper');

describe('event', () => {
  before(function() {
    return Helper.setupJsdom('board.html');
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
    Event.new_unit(testEvent);
    const square = Board.square(2, 0);
    expect(square.firstChild.className).include('north');
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
    Event.new_unit(testEvent);
    Event.unit_changed(updateEvent);
    const unitName = document.querySelector('#c2-0 .unit-name');
    expect(unitName.firstChild.textContent).equal('foo');
  });
  it('moved offscreen', () => {
    const boardEl = document.getElementById('board');
    Board.render(boardEl, 5, 5);
    Event.feature({ x: 0, y: 1, feature: 'block' });
    const result = Event.thing_moved({ from: { x: 0, y: 1}, to: 'offscrean' });
    expect(result.squares[0]).equal('0,1');
  });
  it('moved 0', () => {
    const boardEl = document.getElementById('board');
    Board.render(boardEl, 5, 5);
    Event.feature({ x: 1, y: 1, feature: 'block' });
    const result = Event.thing_moved({ from: { x: 1, y: 1}, to: { x: 0, y: 1 } });
    return result.animation().then(() => {
      expect(Board.thingAt(0, 1).className).include('block');
    });
  });
});
