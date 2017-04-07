// Pull in desired CSS/SASS files
require('./styles/main.css');

// Inject bundled Elm app into div#main
var Elm = require('../elm/Main');
Elm.Main.embed(document.getElementById('main'));
