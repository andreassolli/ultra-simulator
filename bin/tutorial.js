// The Tutorial row of the main screen plays a video. Put its address in TUTORIAL_URL:
//  - a YouTube link (https://www.youtube.com/watch?v=... or https://youtu.be/...), shown in a frame,
//  - or a video file next to this page (e.g. "tutorial.mp4"), shown in a player.
// Empty: the game says that no video has been added yet. Inside a Discord Activity an outside address also has to be mapped
// in the Discord developer portal (URL Mappings); a file on this site needs nothing.
(function () {
  "use strict";
  var TUTORIAL_URL = "";

  var box = null;
  function close() { if (box) { box.remove(); box = null; try { window.player.focus(); } catch (e) {} } }
  window.gameTutorial = function () {
    if (!TUTORIAL_URL) return false;
    var u = TUTORIAL_URL, src = u, frame = false;
    var m = /(?:youtube\.com\/watch\?(?:.*&)?v=|youtu\.be\/)([\w-]{6,})/.exec(u);
    if (m) { src = "https://www.youtube.com/embed/" + m[1] + "?autoplay=1&rel=0"; frame = true; }
    else if (/^https?:\/\/[^/]*youtube\.com\/embed\//.test(u)) frame = true;
    close();
    box = document.createElement("div");
    box.style.cssText = "position:fixed;inset:0;background:rgba(0,0,0,.82);z-index:10;display:flex;align-items:center;justify-content:center";
    var media = document.createElement(frame ? "iframe" : "video");
    media.src = src;
    media.style.cssText = "width:min(92vw,160vh*0.9);height:min(52vw,90vh);border:2px solid #b48a2c;border-radius:6px;background:#000";
    if (frame) { media.allow = "autoplay; fullscreen"; media.allowFullscreen = true; } else { media.controls = true; media.autoplay = true; }
    var x = document.createElement("button");
    x.textContent = "Close";
    x.style.cssText = "position:absolute;top:14px;right:18px;padding:8px 18px;font:bold 15px Arial;color:#fff;background:#a00f12;border:2px solid #d9a93a;border-radius:6px;cursor:pointer";
    x.onclick = close;
    box.appendChild(media);
    box.appendChild(x);
    box.addEventListener("keydown", function (e) { if (e.key === "Escape") close(); });
    document.body.appendChild(box);
    return true;
  };
})();
