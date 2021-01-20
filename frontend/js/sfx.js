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
};
export const settings = {
    volume: 0.9,
    mute: false,
};
export function play(name) {
    if (settings.mute) {
        return Promise.resolve(true);
    }
    const audio = mapping[name];
    if (!audio) {
        console.error({ err: 'unmapped audio file', name });
        return;
    }
    audio.volume = settings.volume;
    return audio.play().catch((e) => {
        console.error(e);
        return false;
    });
}
