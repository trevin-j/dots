// ==UserScript==
// @name         Local Material Theme Injector
// @namespace    local-mat-theme
// @version      0.2.0
// @author       DevTrev
// @license      MIT
// @description  Fetch CSS from local materialized-web server and inject into current page
// @homepageURL  https://github.com/trevin-j/dots
// @match        *://github.com/*
// @match        *://chatgpt.com/*
// @match        *://www.reddit.com/*
// @match        *://www.youtube.com/*
// @match        *://monkeytype.com/*
// @updateURL    https://raw.githubusercontent.com/trevin-j/dots/master/theming/.config/matugen/materialized-web/userscript/material-theme-injector.user.js
// @downloadURL  https://raw.githubusercontent.com/trevin-j/dots/master/theming/.config/matugen/materialized-web/userscript/material-theme-injector.user.js
// @grant        GM_xmlhttpRequest
// @connect      127.0.0.1
// ==/UserScript==

(() => {
  const SERVER = "http://127.0.0.1:8787";
  const STYLE_ID = "mat-site-theme";
  const POLL_MS = 5000;

  let lastEtag = null;
  let lastUrl = location.href;
  let inFlight = false;
  let pollTimer = null;
  let urlWatchTimer = null;

  function ensureStyleTag() {
    let el = document.getElementById(STYLE_ID);
    if (!el) {
      el = document.createElement("style");
      el.id = STYLE_ID;
      document.documentElement.appendChild(el);
    }
    return el;
  }

  function fetchAndApply() {
    if (inFlight) return;
    if (document.visibilityState !== "visible") return;

    inFlight = true;
    const url = `${SERVER}/css?url=${encodeURIComponent(location.href)}`;
    const headers = {};
    if (lastEtag) headers["If-None-Match"] = lastEtag;

    GM_xmlhttpRequest({
      method: "GET",
      url: url,
      headers: headers,
      onload: function (res) {
        if (res.status === 304) {
          inFlight = false;
          return;
        }
        if (res.status !== 200) {
          inFlight = false;
          return;
        }

        const etag = res.responseHeaders.match(/ETag:\s*"?([^"\r\n]+)/i);
        const css = res.responseText;

        const styleEl = ensureStyleTag();
        styleEl.textContent = css;

        if (etag) lastEtag = '"' + etag[1] + '"';
        inFlight = false;
      },
      onerror: function () {
        inFlight = false;
      },
    });
  }

  function startPolling() {
    if (pollTimer) return;
    fetchAndApply();
    pollTimer = setInterval(fetchAndApply, POLL_MS);
  }

  function stopPolling() {
    if (!pollTimer) return;
    clearInterval(pollTimer);
    pollTimer = null;
  }

  function startUrlWatcher() {
    if (urlWatchTimer) return;
    urlWatchTimer = setInterval(() => {
      if (location.href !== lastUrl) {
        lastUrl = location.href;
        fetchAndApply();
      }
    }, 300);
  }

  function stopUrlWatcher() {
    if (!urlWatchTimer) return;
    clearInterval(urlWatchTimer);
    urlWatchTimer = null;
  }

  function onVisibilityChange() {
    if (document.visibilityState === "visible") {
      startPolling();
      startUrlWatcher();
      fetchAndApply();
    } else {
      stopPolling();
      stopUrlWatcher();
    }
  }

  startUrlWatcher();
  document.addEventListener("visibilitychange", onVisibilityChange);
  onVisibilityChange();
})();
