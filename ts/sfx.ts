import * as Settings from './settings.js';

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
}

const loaded = {
};

export const soundtrack = (() => {
  const audio = new Audio('sfx/smugglesnore.mp3'),
    rv: any = {
      playing: false
    };
  audio.loop = true;
  rv.play = () => {
    if (!rv.playing) {
      console.log({l: 'starting audio', audio});
      audio.play();
      rv.playing = true;
    }
  };
  rv.setVolume = (volume: number) => {
    audio.volume = settings.musicvolume;
  };
  rv.audio = audio;
  return rv;
})();

export const settings = {
  fxvolume: 0.9,
  musicvolume: 0,
  mute: false,
}

export function loadSettings() {
  const lsv = localStorage.getItem('fxvolume'),
    lsm = localStorage.getItem('mute');
  if (lsv) {
    settings.fxvolume = +lsv;
  }
  if (lsm) {
    settings.mute = (lsm === 'true');
  }
}

export function setVolume(value: number) {
  settings.fxvolume = value;
  localStorage.setItem('fxvolume', '' + value);
}

export function mute() {
  settings.mute = true;
  localStorage.setItem('mute', 'true');
}

export function unmute() {
  settings.mute = false;
  localStorage.setItem('mute', 'false');
}

export function startMusic() {
  return; // disabling music...
  //soundtrack.play();
}

function getAudio(name) {
  const filename = mapping[name] || name;
  let audio = loaded[filename];
  if (! audio) {
    audio = new Audio(`sfx/${filename}.mp3`);
    loaded[filename] = audio;
  }
  return audio;
}


export function play(name: string): Promise<any> {
  if (settings.mute || settings.fxvolume === 0) {
    return Promise.resolve(true);
  }
  const audio = getAudio(name);
  audio.volume = settings.fxvolume;
  return audio.play().catch((e) => {
    console.error({ name, e });
    return false;
  });
}
