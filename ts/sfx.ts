import * as Settings from './settings.js';

const mapping = {
  select: new Audio('sfx/lego_click.mp3'),
  move: new Audio('sfx/slide.mp3'),
  death: new Audio('sfx/breath intake.mp3'),
  hand: new Audio('sfx/buzz.mp3'),
  hit: new Audio('sfx/drum_2.mp3'),
  playerready: new Audio('sfx/banjo_C3_very-long.mp3'),
  go_lose: new Audio('sfx/Ooopsie.mp3'),
  go_win: new Audio('sfx/wheeep.mp3'),
  go_draw: new Audio('sfx/zenlaugh.mp3'),
  place: new Audio('sfx/place.mp3'),
  jump: new Audio('sfx/schlomp.mp3'),
  fire: new Audio('sfx/ffffummmm.mp3'),
  battle: new Audio('sfx/trashlid_openclose.mp3'),
  spark: new Audio('sfx/ssssshop.mp3'),
  horseshoe: new Audio('sfx/throw.mp3'),
  monarch: new Audio('sfx/Bells_1.mp3'),
  click: new Audio('sfx/click.mp3'),
  tink: new Audio('sfx/tink.mp3'),
  ability: new Audio('sfx/chocho.mp3'),
  undefined: new Audio('sfx/buzz.mp3'),
}

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

export function play(name: string) {
  if (settings.mute || settings.fxvolume === 0) {
    return Promise.resolve(true);
  }
  let audio = mapping[name];
  if (!audio) {
    audio = new Audio(`sfx/${name}.mp3`);
    mapping[name] = audio;
    //console.error({ err: 'unmapped audio file', name });
    //return;
  }
  audio.volume = settings.fxvolume;
  return audio.play().catch((e) => {
    console.error(e);
    return false;
  });
}
