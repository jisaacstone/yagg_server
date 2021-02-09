import * as Storage from './storage.js';

const audio = new Audio();
audio.loop = true;

const state: {
  playing: boolean;
  volume: number;
  mute: boolean;
  track?: string;
} = {
  playing: false,
  volume: 0.5,
  mute: false,
}

const mapping = {
  menu: 'music/the_biggest_pile_of_leaves.mp3',
  waiting: 'music/trying_to_work.mp3',
  jobfair: 'music/race_against_the_sunset.mp3',
  placement: 'music/checking_things_off.mp3',
  battle: 'music/tool_belts_are_the_cool_belts.mp3',
  gameover: 'music/two_turntables_and_a_casiotone.mp3'
}

export function play(): void {
  if (state.playing) {
    return;
  }
  loadSettings();
  try {
    audio.volume = state.volume;
    audio.load();
    audio.play();
    state.playing = true;
  } catch (err) {
    console.warn({ msg: 'error playing soundtrack', err });
  }
}

export function settings(): { volume: number; mute: boolean } {
  return {
    volume: state.volume,
    mute: state.mute,
  }
}

export function mute(): void {
  state.mute = true;
  audio.muted = true;
  Storage.setItem('music', 'mute', 'true');
}

export function unmute(): void {
  state.mute = false;
  audio.muted = false;
  Storage.setItem('music', 'mute', 'false');
  audio.volume = 0;
  fadeTo(state.volume);
}

export function setMute(muted: boolean): void {
  muted ? mute() : unmute();
}

export function setVolume(volume: number): void {
  audio.volume = volume;
  Storage.setItem('music', 'volume', volume);
}

export function loadSettings() {
  const sv = Storage.getItem('music', 'volume'),
    sm = Storage.getItem('music', 'mute');
  if (sv) {
    setVolume(+sv);
  }
  if (sm) {
    setMute(sm === 'true');
  }
}

export function setSoundtrack(track: string): void {
  if (track === state.track) {
    return;
  }
  state.track = track;
  fadeTo(0).then(() => {
    audio.src = mapping[track];
    audio.load();
    audio.play();
  }).then(() => {
    fadeTo(state.volume);
  });
}

function fadeTo(volume: number): Promise<null> {
  const adjust = () => {
    try {
      if (audio.volume + 0.04 < volume) {
        audio.volume += 0.05;
        return false;
      }
      if (audio.volume - 0.04 > volume) {
        audio.volume -= 0.025;
        return false;
      }
      audio.volume = volume;
    } catch (err) {
      console.warn({ msg: 'error with fade', err });
    }
    return true;
  };
  return new Promise((resolve, reject) => {
    const loop = () => {
      if (adjust()) {
        resolve(null);
      } else {
        setTimeout(loop, 100)
      }
    };
    setTimeout(loop)
  });
}
