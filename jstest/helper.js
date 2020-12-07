const JSDOM = require('jsdom').JSDOM,
  Keys = require('jsdom-global/keys.js');

export function setupJsdom(page) {
  return JSDOM.fromFile(`frontend/${page}`).then(({ window }) => {
    Keys.forEach(function (key) {
      global[key] = window[key];
    })

    global.document = window.document;
    global.window = window;
  });
}
