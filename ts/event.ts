import * as State from './state.js';
import * as Select from './select.js';
import * as Unit from './unit.js';
import { SKULL } from './constants.js';
import * as Board from './board.js';
import * as Ready from './ready.js';
import * as Dialog from './dialog.js';
import * as Jobfair from './jobfair.js';
import * as Overlay from './overlay.js';
import * as Player from './player.js';
import * as Feature from './feature.js';
import * as Hand from './hand.js';
import * as AbilityEvent from './abilty_event.js';
import * as Element from './element.js';
import * as Timer from './timer.js';
import { leave } from './leaveButton.js';
import * as SFX from './sfx.js';
import * as Request from './request.js';
import type { ServerEvent, EventHandler, EventHandlers, PayloadOf } from './protocol.js';

const unitsbyindex = {};

export type eventHandler = EventHandler;

function noGrid(fn: () => any): eventHandler {
  return () => Promise.resolve(fn());
}

function noOp() {
  return Promise.resolve(null);
}

export function multi({ events }: PayloadOf<'multi'>): eventHandler {
  const animations: eventHandler[] = [];
  for (const event of events) {
    const handler = handlers[event.event] as ((e: ServerEvent) => eventHandler) | undefined;
    if (handler) {
      animations.push(handler(event));
    }
  }
  if (animations.length > 0) {
    return () => Promise.all(animations.map((a) => a()));
  }
  return noOp;
}

export function game_started(event: PayloadOf<'game_started'>): eventHandler {
  return noGrid(() => {
    const board = document.getElementById('board'),
      state = (event.state || '').toLowerCase();
    Hand.clear();
    Ready.hide();
    if (event.army_size || State.gmeta.phase === 'jobfair') {
      if (State.gmeta.boardstate === 'gameover') {
        Board.clear();
      } else {
        Overlay.clear();
      }
      State.gamestatechange(state || 'jobfair');
      Jobfair.render(event.army_size);
    } else {
      Overlay.clear();
      Jobfair.clear();
      if (event.dimensions) {
        Board.render(board, event.dimensions);
      }
      State.gamestatechange(state || 'placement');
      if (state === 'placement' || state === 'gameover') {
        Ready.display(state === 'placement' ? 'ready' : 'rematch');
      }
    }
  });
}

export function timer(event: PayloadOf<'timer'>): eventHandler {
  return noGrid(() => {
    Timer.set(event.timer, event.player);
  });
}

export function battle_started(): eventHandler {
  return noGrid(() => {
    Ready.hide();
    State.gamestatechange('battle');
  });
}

export function player_joined({ player, position }: PayloadOf<'player_joined'>): eventHandler {
  return noGrid(() => {
    const thisPlayer = Player.getLocal(),
      whois = thisPlayer.id == player.id ? 'player' : 'opponent',
      container = document.getElementById(whois),
      playerDetailsEl = Player.render(player);

    if (container.firstElementChild) {
      if (container.firstElementChild.className === 'playername') {
        return;
      } else {
        container.innerHTML = '';
      }
    }
    container.appendChild(playerDetailsEl);
    if (whois === 'player') {
      State.gmeta.position = position;
      document.getElementById('table').dataset.position = position;
    }
  });
}

export function player_left({ player }: PayloadOf<'player_left'>): eventHandler {
  return noGrid(() => {
    const thisPlayer = Player.getLocal(),
      whois = thisPlayer.id == player.id ? 'player' : 'opponent',
      container = document.getElementById(whois);
    container.innerHTML = '';
    container.appendChild(Element.create({className: 'invisible'}));
  });
}

export function add_to_hand({ unit, index }: PayloadOf<'add_to_hand'>): eventHandler {
  return noGrid(() => {
    const unitEl = Hand.createCard(unit, index)
    unitsbyindex[index] = unitEl;
    unitEl.scrollIntoView({ behavior: "smooth", block: "center" });
  });
}

export function unit_assigned({ x, y, index }: PayloadOf<'unit_assigned'>): eventHandler {
  return () => {
      const square = Board.square(x, y),
        unit = unitsbyindex[index];
      square.appendChild(unit);
      return SFX.play('place');
  };
}

export function new_unit({ x, y, unit }: PayloadOf<'new_unit'>): eventHandler {
  const animation = () => {
    const exist = Board.thingAt(x, y);
    let unitEl;
    if (!exist) {
      const square = Board.square(x, y);
      unitEl = Unit.render(unit, 0);
      square.appendChild(unitEl);
    } else {
      // don't overwrite existing data
      exist.innerHTML = '';
      Unit.render_into(unit, exist);
      unitEl = exist;
    }
    const a = unitEl.animate({ opacity: [0.5, 0.9, 1] }, { duration: 100 });
    return a.finished;
  };
  return animation;
}

export function unit_changed(event: PayloadOf<'unit_changed'>): eventHandler {
  return new_unit({ ...event, event: 'new_unit' });  // for now
}

export function unit_placed(event: PayloadOf<'unit_placed'>): eventHandler {
  return () => {
    const square = Board.square(event.x, event.y);
    if (! square.firstChild) {
      // The wire payload is { x, y, player } (an opponent's face-down unit); the
      // reload path also passes revealed stats. Either is a valid BoardUnit, and
      // render draws whatever fields are present.
      const unit = Unit.render(event, null)
      square.appendChild(unit);
      return SFX.play('place');
    } else {
      return Promise.resolve(false);
    }
  };
}

export function player_ready(event: PayloadOf<'player_ready'>): eventHandler {
  return noGrid(() => {
    if ( event.player === State.gmeta.position ) {
      (document.querySelector('#player .playername') as HTMLElement).dataset.ready = 'true';
      Ready.waiting();
    } else {
      SFX.play('playerready');
      (document.querySelector('#opponent .playername') as HTMLElement).dataset.ready = 'true';
      Ready.hideIfWaiting();
    }
  });
}

export function feature(event: PayloadOf<'feature'>): eventHandler {
  return () => {
    const square = Board.square(event.x, event.y),
      feature = Feature.render(event.feature);
    square.appendChild(feature);
    return Promise.resolve(true);
  }
}

export function unit_died(event: PayloadOf<'unit_died'>): eventHandler {
  const square = Board.square(event.x, event.y),
    animation = () => {
      const unit = square.firstChild as HTMLElement;
      if (! unit) {
        return Promise.resolve(true);
      }
      unit.innerHTML = `<div class="death">${SKULL}</div>`;
      unit.dataset.dead = 'true';
      return SFX.play('death').then(() => {
        return unit.animate(
          { opacity: [1, 0] },
          { duration: 500, easing: "ease-in" }
        ).finished.then(() => {
          unit.remove();
        });
      });
    };
  return animation;
}

export function thing_moved(event: PayloadOf<'thing_moved'>): eventHandler {
  const from = Board.square(event.from.x, event.from.y);
  // `to` is a coordinate, unless it's the 'offscreen' / 'hand' sentinel
  if (typeof event.to !== 'string') {
    const to = Board.square(event.to.x, event.to.y),
      fromRect = from.getBoundingClientRect(),
      toRect = to.getBoundingClientRect(),
      animation = () => {
        const thing = from.firstChild as HTMLElement;
        return SFX.play('move').then(() => {
          const thingRect = thing.getBoundingClientRect(),
            xoffset = thingRect.left - fromRect.left,
            yoffset = thingRect.top - fromRect.top;
          const a = thing.animate({ 
            top: [fromRect.top + yoffset + 'px', toRect.top + yoffset + 'px'],
            left: [fromRect.left + xoffset + 'px', toRect.left + xoffset + 'px'],
          }, { duration: 200, easing: 'ease-in-out' });
          Object.assign(thing.style, {
            position: 'fixed',
            width: thingRect.width + 'px',
            height: thingRect.height + 'px',
          });
          if (! thing.dataset.dead) {
            to.appendChild(thing);
          }
          return a.finished.then(() => {
            thing.style.position = '';
            thing.style.width = '';
            thing.style.height = '';
          });
        });
      };
    return animation;
  } else if (event.direction) {
    // moved offscreen
    const animation = () => {
      const thing = from.firstChild as HTMLElement,
        thingRect = thing.getBoundingClientRect(),
        xpos = thingRect.left,
        ypos = thingRect.top,
        { x, y } = Board.in_direction(event.direction, thingRect.width);
      const a = thing.animate([
        { 
          top: ypos + 'px',
          left: xpos + 'px',
          opacity: 1
        },
        {
          top: ypos + y + 'px',
          left: xpos + x + 'px',
          opacity: 0.9
        },
        {
          top: ypos + y + 'px',
          left: xpos + x + 'px',
          opacity: 0
        },
        ],
        { duration: 400, easing: 'ease-in-out' });
      Object.assign(thing.style, {
        position: 'fixed',
        width: thingRect.width + 'px',
        height: thingRect.height + 'px',
      });
      return a.finished.then(() => {
        thing.remove();
      });
    };
    return animation;
  } else if (event.to === 'hand') {
    const animation = () => {
      const thing = from.firstChild as HTMLElement,
        thingRect = thing.getBoundingClientRect(),
        handRect = document.getElementById('hand').getBoundingClientRect(),
        xpos = thingRect.left,
        ypos = thingRect.top,
        to_x = (handRect.left + handRect.right - thingRect.width) / 2,
        to_y = (handRect.top + handRect.bottom - thingRect.height) / 2,
        a = thing.animate({
          top: [ypos + 'px', to_y + 'px'],
          left: [xpos + 'px', to_x + 'px'],
          opacity: [1, 0]
        }, {
          duration: 500, easing: 'ease-out'
        });
      Object.assign(thing.style, {
        position: 'fixed',
        width: thingRect.width + 'px',
        height: thingRect.height + 'px',
      });
      return a.finished.then(() => {
        thing.remove();
      });
    }
    return animation;
  }
}

export function thing_gone(event: PayloadOf<'thing_gone'>): eventHandler {
  return () => {
    const thing = Board.thingAt(event.x, event.y);
    if (!thing) {
      console.error({ msg: `nothing at ${event.x},${event.y}`, event});
      return noOp();
    }
    if (thing.className.includes('owned')) {
      thing.dataset.state = 'invisible';
      return noOp();
    } else {
      const a = thing.animate({ opacity: [1, 0] }, { duration: 1000, easing: "ease-in" });
      return a.finished.then(() => {
        thing.remove();
      });
    }
  }
}

export function battle({ from, to }: PayloadOf<'battle'>): eventHandler {
  // animation only, no lasting chages
  const animation = () => {
    return SFX.play('battle').then(() => {
      Unit.hilight(from, 'unit-attack');
      Unit.hilight(to, 'unit-defense');
      const attacker = Board.thingAt(from.x, from.y),
        defender = Board.thingAt(to.x, to.y),
        arect = attacker.getBoundingClientRect(),
        drect = defender.getBoundingClientRect(),
        xpos = arect.left,
        ypos = arect.top;
      let xdiff = 0, ydiff = 0;

      if (from.x !== to.x) {
        xdiff = (drect.left > arect.left ? drect.left - arect.right : drect.right - arect.left) * 1.8;
      }

      if (from.y !== to.y) {
        ydiff = (drect.top > arect.top ? drect.top - arect.bottom : drect.bottom - arect.top) * 1.8;
      }

      Object.assign(attacker.style, {
        position: 'fixed',
        width: arect.width + 'px',
        height: arect.height + 'px',
      });
      return attacker.animate(
        { 
          top: [ypos + 'px', ypos + ydiff + 'px'],
          left: [xpos + 'px', xpos + xdiff + 'px']
        },
        { duration: 100, easing: 'ease-in' }
      ).finished.then(() => {
        defender.animate(
          { opacity: [1, 0.5, 1] },
          { duration: 80 }
        );
        return attacker.animate(
          { 
            top: [ypos + ydiff + 'px', ypos + 'px'],
            left: [xpos + xdiff + 'px', xpos + 'px']
          },
          { duration: 80, easing: 'ease-out' }
        ).finished;
      }).then(() => {
        attacker.style.position = '';
        attacker.style.width = '';
        attacker.style.height = '';
      });
    });
    };
  return animation;
}

export function gameover({ winner, reason }: PayloadOf<'gameover'>): eventHandler {
  return noGrid(() => {
    let message;
    const showRematch = ! reason || ! reason.toLowerCase().includes('opponent left'),
      choices = {
        ok: () => { if (showRematch) { Ready.display('rematch'); } },
        leave,
      };

    State.gamestatechange('gameover');
    Ready.hide();
    Timer.stop();
    State.turnchange(null);

    if (winner === State.gmeta.position) {
      SFX.play('go_win');
      message = 'you win!';
    } else if (winner === 'draw') {
      SFX.play('go_draw');
      message = 'draw game';
    } else {
      SFX.play('go_lose');
      message = 'you lose';
    }
    if (reason) {
      message = `<p>${reason}<p>${message}`;
    }

    if ( showRematch ) {
      choices['rematch'] = () => {
        return Request.gameaction('ready', {}, 'board').then(() => {
          window.location.reload();
        });
      };
    }
    Dialog.choices(message, choices);
  });
}

export function turn({ player }: PayloadOf<'turn'>): eventHandler {
  return noGrid(() => {
    State.turnchange(player);
  });
}

export function candidate(event: PayloadOf<'candidate'>): eventHandler {
  return noGrid(() => {
    const jf = document.getElementById('jobfair'),
      existing = document.getElementById(`candidate-${event.index}`);
    if (existing) {
      return;
    }
    const unitEl = Unit.render(event.unit, event.index),
      cdd = Element.create({
        className: 'candidate',
        id: `candidate-${event.index}`,
        children: [unitEl]
      });
    Select.bind_candidate(cdd, event.index, event.unit);
    unitEl.addEventListener('dblclick', Unit.detailViewFn(unitEl));
    jf.appendChild(cdd);
  });
}

export function show_ability({ x, y, type, reveal }: PayloadOf<'show_ability'>): eventHandler {
  return noGrid(() => {
    Unit.showName({ x, y }, reveal.name);
    if (type === 'ability') {
      Unit.showAbility({ x, y }, reveal.ability);
      return Unit.hilight({ x, y }, 'unit-ability');
    } else {
      Unit.showTriggers({ x, y }, reveal.triggers);
      return Unit.hilight({ x, y }, `${type}-t`);
    }
  });
}

export function ability_used(event: PayloadOf<'ability_used'>): eventHandler {
  if (!AbilityEvent[event.type]) {
    console.error({error: 'no ability handler', event});
    return noGrid(() => {
      SFX.play('ability');
    });
  }
  return AbilityEvent[event.type](event);
}

export function table_shutdown(): eventHandler {
  return noGrid(() => {
    return Dialog.alert('table closed').then(() => {
      window.location.href = 'index.html';
    });
  });
}

// Contract conformance: each value must match HandlerFor<its key>. This is what
// lets multi() (above) and the dispatcher (eventlistener.ts) look a handler up
// by event name and know its payload. `config_change` is intentionally absent
// — the backend emits it but there is no client handler yet.
export const handlers: EventHandlers = {
  multi,
  game_started,
  battle_started,
  timer,
  player_joined,
  player_left,
  player_ready,
  add_to_hand,
  unit_assigned,
  unit_placed,
  new_unit,
  unit_changed,
  unit_died,
  feature,
  thing_moved,
  thing_gone,
  battle,
  candidate,
  show_ability,
  ability_used,
  gameover,
  turn,
  table_shutdown,
};
