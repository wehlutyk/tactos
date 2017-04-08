// Pull in desired CSS/SASS files
require('./styles/main.css');

// Inject bundled Elm app into div#main
var App = require('../elm/Main');
var main = document.getElementById('main');
var app = App.Main.embed(main);

// Setup ports. FIXME: make into effect managers
document.addEventListener("pointerlockchange", function() {
  var id = document.pointerLockElement ? document.pointerLockElement.id : "";
  app.ports.pointerLockChange.send(document.pointerLockElement === main);
});
document.addEventListener("pointerlockerror", function() {
  app.ports.pointerLockError.send(null);
});

// Initial pointer lock goes here in JS, as trying to do it from Elm requires
// us to add another port, producing a command onClick, which makes us leave
// the onClick event handler, and rejects the requestPointerLock on Firefox.
main.onclick = function() {
  main.requestPointerLock();
};
