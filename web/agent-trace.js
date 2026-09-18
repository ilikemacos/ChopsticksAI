(function (w) {
  function isGreeting(text) {
    return /^(hi|hello|hey|thanks|ok|yes|no)[\s!.]*$/i.test(String(text || "").trim())
      && String(text || "").trim().length < 24;
  }

  function isComplicatedAsk(text, opts) {
    opts = opts || {};
    var t = String(text || "").trim();
    if (isGreeting(t) && !opts.attach) return false;
    if (opts.attach) return true;
    var plate = String(opts.plate || "");
    if (plate === "chopcode" || plate === "kaji" || plate === "max" || plate === "csai47flash") return true;
    if (opts.searchOn) return true;
    if (/https?:\/\//i.test(t) || /^\/search\b/i.test(t)) return true;
    if (t.length > 72) return true;
    if (/\b(how|why|explain|compare|latest|today|research|write|code|what is)\b/i.test(t)) return true;
    return false;
  }

  function workLabels(searchOn) {
    var steps = ["Understanding request"];
    if (searchOn) {
      steps.push("Searching the web");
      steps.push("Reading 4 sources");
    }
    steps.push("Forming answer");
    return steps;
  }

  function paintRow(row, kind) {
    row.li.className = "agent-trace-step is-" + kind;
    row.mark.textContent = kind === "done" ? "✓" : kind === "run" ? "→" : "○";
  }

  function mount(host, opts) {
    opts = opts || {};
    var labels = opts.steps || workLabels(opts.searchOn);
    var wrap = document.createElement("div");
    wrap.className = "agent-trace";
    wrap.setAttribute("role", "status");
    wrap.setAttribute("aria-live", "polite");
    var title = document.createElement("div");
    title.className = "agent-trace-title";
    title.textContent = opts.title || "cs.AI is working";
    var ol = document.createElement("ol");
    ol.className = "agent-trace-steps";
    wrap.appendChild(title);
    wrap.appendChild(ol);
    var rows = labels.map(function (label) {
      var li = document.createElement("li");
      li.className = "agent-trace-step is-wait";
      var mark = document.createElement("span");
      mark.className = "agent-trace-mark";
      mark.textContent = "○";
      var lab = document.createElement("span");
      lab.className = "agent-trace-label";
      lab.textContent = label;
      li.appendChild(mark);
      li.appendChild(lab);
      ol.appendChild(li);
      return { li: li, mark: mark, lab: lab };
    });
    if (host) host.appendChild(wrap);
    var timers = [];
    var idx = 0;
    var reduce = w.matchMedia && w.matchMedia("(prefers-reduced-motion: reduce)").matches;
    function show(i) {
      rows.forEach(function (row, n) {
        paintRow(row, n < i ? "done" : n === i ? "run" : "wait");
      });
    }
    function tick() {
      if (idx >= rows.length) return;
      show(idx);
      var wait = reduce ? 0 : (idx === 0 ? 380 : idx === 1 ? 720 : idx === 2 ? 980 : 1200);
      timers.push(setTimeout(function () {
        idx += 1;
        if (idx < rows.length) tick();
        else show(rows.length - 1);
      }, wait));
    }
    tick();
    return {
      el: wrap,
      setLabel: function (i, text) {
        if (rows[i]) rows[i].lab.textContent = text;
      },
      setReadingCount: function (n) {
        var i = labels.indexOf("Reading 4 sources");
        if (i < 0) {
          for (var k = 0; k < labels.length; k++) {
            if (/^Reading /.test(labels[k])) { i = k; break; }
          }
        }
        if (i >= 0 && n > 0) {
          rows[i].lab.textContent = "Reading " + n + " source" + (n === 1 ? "" : "s");
        }
      },
      finish: function () {
        timers.forEach(clearTimeout);
        rows.forEach(function (row) { paintRow(row, "done"); });
      },
      stop: function () {
        timers.forEach(clearTimeout);
      }
    };
  }

  function computer(stage) {
    if (!stage) return { finish: function () {} };
    var existing = stage.querySelector(".web-computer-trace");
    if (existing) existing.remove();
    var box = document.createElement("div");
    box.className = "web-computer-trace";
    stage.appendChild(box);
    var run = mount(box, {
      title: "Web Computer",
      steps: ["Opening website", "Navigating", "Reading page", "Done"]
    });
    var hideTimer = null;
    return {
      finish: function () {
        run.finish();
        clearTimeout(hideTimer);
        hideTimer = setTimeout(function () {
          if (box.parentNode) box.remove();
        }, 900);
      },
      stop: function () {
        run.stop();
        clearTimeout(hideTimer);
        if (box.parentNode) box.remove();
      }
    };
  }

  w.CHQAgentTrace = {
    isComplicatedAsk: isComplicatedAsk,
    workLabels: workLabels,
    mount: mount,
    computer: computer
  };
})(window);
