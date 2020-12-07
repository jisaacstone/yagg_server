const expect = require('chai').expect,
  Unit = require('../frontend/js/unit.js'),
  Helper = require('./helper');

describe('unit', () => {
  before(function() {
    return Helper.setupJsdom('board.html');
  });
  it('create unit', () => {
    const testUnit = {
        name,
        attack: 1,
        defense: 0,
        player: 'north',
        ability: null,
        triggers: {}
      },
      index = 3,
      unitEl = Unit.render(testUnit, index);
    expect(unitEl.className).include('north');
  });
  it('sidebar', () => {
    const testUnit = {
        name,
        attack: 1,
        defense: 0,
        player: 'north',
        ability: { name: 'fake', description: 'A.Fake.Ability' },
        triggers: {}
      },
      index = 3,
      unitEl = Unit.render(testUnit, index);
    unitEl.dispatchEvent(new Event('sidebar'));
    expect(document.querySelector('#infobox .unit')).a('HTMLDivElement');
    expect(document.querySelector('#infobox .unit-ability').firstChild.textContent).equal('fake');
  });
});

