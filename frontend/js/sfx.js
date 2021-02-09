import * as Storage from './storage.js';
const mapping = {
    select: 'lego_click',
    move: 'slide',
    death: 'breath intake',
    hand: 'buzz',
    hit: 'drum_2',
    playerready: 'banjo_C3_very-long',
    go_lose: 'Ooopsie',
    go_win: 'wheeep',
    go_draw: 'zenlaugh',
    place: 'place',
    jump: 'schlomp',
    fire: 'ffffummmm',
    battle: 'trashlid_openclose',
    spark: 'ssssshop',
    horseshoe: 'throw',
    bells: 'Bells_1',
    click: 'click',
    tink: 'tink',
    ability: 'chocho',
    undefined: 'buzz',
};
const loaded = {};
const state = {
    volume: 0.9,
    mute: false,
};
export function settings() {
    return {
        volume: state.volume,
        mute: state.mute,
    };
}
export function mute() {
    state.mute = true;
    Storage.setItem('sfx', 'mute', 'true');
}
export function unmute() {
    state.mute = false;
    Storage.setItem('sfx', 'mute', 'false');
}
export function setMute(muted) {
    muted ? mute() : unmute();
}
export function setVolume(volume) {
    state.volume = volume;
    Storage.setItem('sfx', 'volume', volume);
}
export function loadSettings() {
    const sv = Storage.getItem('sfx', 'volume'), sm = Storage.getItem('sfx', 'mute');
    if (sv) {
        setVolume(+sv);
    }
    if (sm) {
        setMute(sm === 'true');
    }
}
function getAudio(name) {
    const filename = mapping[name] || name;
    let audio = loaded[filename];
    if (!audio) {
        audio = new Audio(`sfx/${filename}.mp3`);
        loaded[filename] = audio;
    }
    return audio;
}
export function play(name) {
    if (state.mute || state.volume === 0) {
        return Promise.resolve(true);
    }
    const audio = getAudio(name);
    audio.volume = state.volume;
    return audio.play().catch((e) => {
        console.error({ name, e });
        return false;
    });
}
