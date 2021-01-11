import * as Constants from './constants.js';

export function symbolFor(trigger: string): string {
  if (trigger === 'move') {
    return Constants.MOVE;
  }
  if (trigger === 'death') {
    return Constants.SKULL;
  }
  if (trigger === 'attack') {
    return Constants.ATTACK;
  }
  console.log({warn: 'unknown trigger', trigger});
  return '?';
}

export function timingOf(trigger: string): string {
  if (trigger === 'move') {
    return 'After move';
  }
  if (trigger === 'death') {
    return 'After death';
  }
  if (trigger === 'attack') {
    return 'Before attack';
  }
  console.log({warn: 'unknown trigger', trigger});
  return '?';
}
