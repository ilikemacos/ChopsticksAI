(function () {
  function el(tag, cls, text) {
    var n = document.createElement(tag);
    if (cls) n.className = cls;
    if (text != null) n.textContent = text;
    return n;
  }

  function paintChart(host, chart) {
    host.innerHTML = "";
    host.appendChild(el("h3", "bench-chart-title", chart.title));
    if (chart.note) host.appendChild(el("p", "bench-note", chart.note));
    var max = 100;
    chart.bars.forEach(function (b) {
      if (typeof b.value === "number" && b.value > max) max = b.value;
    });
    var list = el("div", "bench-bars");
    chart.bars.forEach(function (b) {
      var row = el("div", "bench-row" + (b.highlight ? " is-hq" : ""));
      var name = el("div", "bench-name", b.label);
      var track = el("div", "bench-track");
      var fill = el("div", "bench-fill");
      var pct = Math.max(0, Math.min(100, (b.value / max) * 100));
      fill.style.width = pct.toFixed(1) + "%";
      var val = el("div", "bench-val", b.value.toFixed(1) + (chart.unit || "%"));
      track.appendChild(fill);
      var right = el("div", "bench-right");
      right.appendChild(track);
      right.appendChild(val);
      row.appendChild(name);
      row.appendChild(right);
      if (b.cite) {
        var cite = el("div", "bench-cite");
        if (b.href) {
          var a = document.createElement("a");
          a.href = b.href;
          a.target = "_blank";
          a.rel = "noopener noreferrer";
          a.textContent = b.cite;
          cite.appendChild(a);
        } else {
          cite.textContent = b.cite;
        }
        row.appendChild(cite);
      }
      list.appendChild(row);
    });
    host.appendChild(list);
  }

  function mount(root, data) {
    var tabs = root.querySelector("[data-bench-tabs]");
    var panel = root.querySelector("[data-bench-panel]");
    if (!panel || !data || !data.charts) return;
    var active = (data.charts[0] && data.charts[0].id) || "";
    function show(id) {
      active = id;
      var chart = data.charts.filter(function (c) { return c.id === id; })[0] || data.charts[0];
      paintChart(panel, chart);
      if (tabs) {
        Array.prototype.forEach.call(tabs.querySelectorAll("[data-bench]"), function (btn) {
          btn.classList.toggle("is-on", btn.getAttribute("data-bench") === chart.id);
        });
      }
    }
    if (tabs) {
      tabs.innerHTML = "";
      data.charts.forEach(function (c) {
        var btn = el("button", "bench-tab", c.title);
        btn.type = "button";
        btn.setAttribute("data-bench", c.id);
        btn.addEventListener("click", function () { show(c.id); });
        tabs.appendChild(btn);
      });
    }
    show(active);
  }

  window.CsAiBenchmark = {
    load: function (root) {
      if (!root) return;
      fetch("/chopsticks-ai/benchmark/scores.json")
        .then(function (r) { return r.json(); })
        .then(function (data) {
          var disc = root.querySelector("[data-bench-disclaimer]");
          if (disc && data.disclaimer) disc.textContent = data.disclaimer;
          var asof = root.querySelector("[data-bench-asof]");
          if (asof && data.asOf) asof.textContent = "Figures compiled " + data.asOf + " from the cited lab cards.";
          mount(root, data);
        })
        .catch(function () {
          var panel = root.querySelector("[data-bench-panel]");
          if (panel) panel.textContent = "Could not load scores.json.";
        });
    }
  };
})();
