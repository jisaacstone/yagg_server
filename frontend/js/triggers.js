import * as Constants from './constants.js';
export function symbolFor(trigger) {
    if (trigger === 'move') {
        return Constants.MOVE;
    }
    if (trigger === 'death') {
        return Constants.SKULL;
    }
    if (trigger === 'attack') {
        return Constants.ATTACK;
    }
    console.log({ warn: 'unknown trigger', trigger });
    return '?';
}
export function timingOf(trigger) {
    if (trigger === 'move') {
        return 'After move';
    }
    if (trigger === 'death') {
        return 'After death';
    }
    if (trigger === 'attack') {
        return 'Before attack';
    }
    console.log({ warn: 'unknown trigger', trigger });
    return '?';
}
export function get(unit) {
    const triggers = [];
    if (unit.triggers && Object.keys(unit.triggers).length !== 0) {
        let tttext;
        for (const [name, trigger] of Object.entries(unit.triggers)) {
            if (name === 'move' && unit.attributes.includes('immobile')) {
                triggers.push({ name: 'immobile', description: 'immobile' });
            }
            else {
                triggers.push({ name, description: trigger.description, timing: timingOf(name) });
            }
        }
    }
    if (unit.attributes.includes('invisible')) {
        triggers.push({ name: 'invisible', description: 'invisible to opponent' });
    }
    return triggers;
}
