// Where the page gets Ruffle from.
//
// "local" is the copy in ./ruffle (nothing is downloaded from elsewhere). To use a Ruffle build you host yourself (for example a
// patched one), put the link to its ruffle.js under a name in SOURCES and make it the DEFAULT, or open the page with ?ruffle=<name>.
//
// - Only the names listed here can be chosen from the address, never a free link: a link someone sends you could otherwise run any
//   script on this page. ?ruffle=local always goes back to the bundled copy.
// - A Ruffle build finds its own core and .wasm next to the ruffle.js it was loaded from, so they have to be served from the same
//   folder, and the host has to allow the page to load them (CORS: Access-Control-Allow-Origin).
// - Inside a Discord Activity every outside host also has to be mapped in the Discord developer portal (URL Mappings), or Discord
//   blocks it; keep "local" as the default there.
(function () {
  "use strict";
  var SOURCES = {
    local: "ruffle/ruffle.js"
    // patched: "https://example.com/ruffle-aqw/ruffle.js"
  };
  var DEFAULT = "local";
  var want = "";
  try { want = new URLSearchParams(location.search).get("ruffle") || ""; } catch (e) {}
  var name = Object.prototype.hasOwnProperty.call(SOURCES, want) ? want : DEFAULT;
  window.RUFFLE_SOURCE = name;
  window.RUFFLE_SCRIPT = SOURCES[name];
  // the page that loads the script right after this one writes the tag, so the order of the scripts below does not change
  window.loadRuffleScript = function () {
    document.write('<script src="' + window.RUFFLE_SCRIPT + '"><\/script>');
  };
})();
