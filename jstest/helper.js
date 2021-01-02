const JSDOM = require('jsdom').JSDOM,
  Keys = require('jsdom-global/keys.js');

export function setupJsdom(page) {
  return JSDOM.fromFile(`frontend/${page}`).then(({ window }) => {
    Keys.forEach(function (key) {
      global[key] = window[key];
    });

    global.document = window.document;
    global.window = window;
    global.localStorage = (() => {
      const db = {};
      return {
        getItem: (key) => {
          return db.hasOwnProperty(key) ? db[key] : null;
        },
        setItem: (key, value) => {
          db[key] = value;
        },
        deleteItem: (key) => {
          delete db[key];
        }
      };
    })();

    // Hack for animation since I can't figure how to import the polyfill
    Element.prototype.animate = (frames, opt_options) => {
      return { finished: Promise.resolve(true) };
    };
  });
}
