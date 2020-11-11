import { expect } from 'chai';
import * as Select from '../ts/select.js';

describe('this', () => {
  it('is a test', () => {
    const el = document.createElement('div');
    expect(el).equal(2);
  });
});
