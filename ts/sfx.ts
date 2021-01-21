const mapping = {
  select: new Audio('sfx/lego_click.wav'),
  move: new Audio('sfx/slide.wav'),
  death: new Audio('sfx/breath intake.wav'),
  hand: new Audio('sfx/buzz.wav'),
  hit: new Audio('sfx/drum_2.wav'),
  playerready: new Audio('sfx/banjo_C3_very-long.mp3'),
  go_lose: new Audio('sfx/Ooopsie.wav'),
  go_win: new Audio('sfx/wheeep.wav'),
  go_draw: new Audio('sfx/zenlaugh.wav'),
  place: new Audio('sfx/place.wav'),
  jump: new Audio('sfx/schlomp.wav'),
  fire: new Audio('sfx/ffffummmm.wav'),
  battle: new Audio('sfx/trashlid_openclose.wav'),
  spark: new Audio('sfx/ssssshop.wav'),
  horseshoe: new Audio('sfx/throw.wav'),
  monarch: new Audio('sfx/Bells_1.wav'),
  click: new Audio('sfx/click.wav'),
  tink: new Audio('sfx/tink.wav'),
  ability: new Audio('sfx/chocho.wav'),
}

export const soundtrack = (() => {
  const audio = new Audio('sfx/smugglesnore.wav'),
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

export function startMusic() {
  return; // disabling music...
  //soundtrack.play();
}

export function play(name: string) {
  if (settings.mute) {
    return Promise.resolve(true);
  }
  const audio = mapping[name];
  if (!audio) {
    console.error({ err: 'unmapped audio file', name });
    return;
  }
  audio.volume = settings.fxvolume;
  return audio.play().catch((e) => {
    console.error(e);
    return false;
  });
}
