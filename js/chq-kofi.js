(function (w) {
  var KOFI = "https://buymeacoffee.com/chopstickshq";
  var IMG = "/img/support-me-on-kofi.png";
  var UNTIL_KEY = "chq.csai.kofi.until";
  var WEEK_MS = 7 * 24 * 60 * 60 * 1000;
  var MAP = [
    { re: /\/macbar\//i, to: "/support/macbar/" },
    { re: /\/chopsticks-ai\//i, to: "/support/cs-ai/" },
    { re: /\/fathom-pro\/|\/fathom-plus\//i, to: "/support/fathom-pro/" },
    { re: /\/fathom\//i, to: "/support/fathom/" },
    { re: /\/csr\//i, to: "/support/csr/" },
    { re: /\/chopsticks-hq\//i, to: "/support/chopsticks-hq/" },
    { re: /\/upscaler\//i, to: "/support/upscaler/" },
    { re: /\/browser\//i, to: "/support/browser/" }
  ];

  function banner(href) {
    var a = document.createElement("a");
    a.className = "chq-kofi-link";
    a.href = href || KOFI;
    a.target = "_blank";
    a.rel = "noopener noreferrer";
    a.setAttribute("aria-label", "Support Chopsticks HQ on Ko-fi");
    var img = document.createElement("img");
    img.src = IMG;
    img.alt = "Support me on Ko-fi";
    img.width = 320;
    img.height = 76;
    a.appendChild(img);
    return a;
  }

  function go(path) {
    setTimeout(function () {
      w.location.href = path;
    }, 500);
  }

  function supportFor(href) {
    var s = String(href || "");
    for (var i = 0; i < MAP.length; i++) {
      if (MAP[i].re.test(s)) return MAP[i].to;
    }
    return "/support/";
  }

  function isDownloadHref(href) {
    var s = String(href || "");
    if (/^https?:\/\/(?!chopstickshq\.com)/i.test(s)) return false;
    return /\.(zip|sh|pkg|dmg|tar\.gz)(\?|#|$)/i.test(s) || /install[^/]*\.sh/i.test(s);
  }

  function watchDownloads() {
    document.addEventListener("click", function (e) {
      var a = e.target && e.target.closest ? e.target.closest("a[href]") : null;
      if (!a) return;
      var href = a.getAttribute("href") || "";
      if (!isDownloadHref(href)) return;
      if (/\/support\//i.test(location.pathname)) return;
      go(supportFor(a.href || href));
    }, true);
  }

  function corner() {
    if (document.querySelector(".chq-kofi-corner")) return;
    var wrap = document.createElement("div");
    wrap.className = "chq-kofi-corner";
    wrap.appendChild(banner());
    document.body.appendChild(wrap);
  }

  function noticeBlocked() {
    try {
      var until = parseInt(localStorage.getItem(UNTIL_KEY) || "0", 10) || 0;
      return Date.now() < until;
    } catch (e) {
      return false;
    }
  }

  function markNotice() {
    try { localStorage.setItem(UNTIL_KEY, String(Date.now() + WEEK_MS)); } catch (e) {}
  }

  function noteCsaiReply() {
    if (noticeBlocked()) return;
    if (document.querySelector(".chq-kofi-chat")) return;
    var wrap = document.createElement("div");
    wrap.className = "chq-kofi-chat";
    wrap.setAttribute("role", "status");
    wrap.setAttribute("aria-label", "Thanks for trying cs.AI");
    var copy = document.createElement("p");
    copy.className = "chq-kofi-copy";
    copy.appendChild(document.createTextNode("Thanks for trying cs.AI. "));
    var a = document.createElement("a");
    a.className = "chq-kofi-text";
    a.href = KOFI;
    a.target = "_blank";
    a.rel = "noopener noreferrer";
    a.textContent = "Support me on Ko-fi";
    copy.appendChild(a);
    wrap.appendChild(copy);
    var x = document.createElement("button");
    x.type = "button";
    x.className = "chq-kofi-x";
    x.setAttribute("aria-label", "Dismiss");
    x.textContent = "×";
    x.addEventListener("click", function () {
      markNotice();
      wrap.remove();
    });
    wrap.appendChild(x);
    document.body.appendChild(wrap);
    markNotice();
  }

  w.CHQKofi = {
    url: KOFI,
    banner: banner,
    go: go,
    corner: corner,
    watchDownloads: watchDownloads,
    noteCsaiReply: noteCsaiReply,
    supportFor: supportFor
  };

  function boot() {
    if (document.body && document.body.getAttribute("data-chq-kofi") === "corner") corner();
    if (!/\/support\//i.test(location.pathname) && !/\/chopsticks-ai\/web\//i.test(location.pathname)) {
      watchDownloads();
    }
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", boot);
  else boot();
})(window);
