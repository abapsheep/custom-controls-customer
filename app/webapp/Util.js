// z2ui5cci.Util - the few helpers the artefacts in this BSP need.
//
// Deliberately NOT a dependency on z2ui5/core/Lib: that module is
// frontend-internal and not part of abap2UI5's public contract, so artefacts
// shipped from their own BSP must not reach into it - a refactor there would
// break this extension silently.
sap.ui.define([], () => {
  "use strict";

  // one promise per URL, so five controls asking for the same stylesheet
  // load it once
  const styles = new Map();
  const scripts = new Map();

  const logError = (message, error) =>
    console.error(error === undefined ? message : `${message}:`, error ?? "");

  // Guards async continuations against a control torn down in the meantime.
  const isDestroyed = (obj) => Boolean(obj?.isDestroyed && obj.isDestroyed());

  // Absolute URL of a file inside THIS BSP. Never hardcode
  // "/sap/bc/ui5_ui5/sap/z2ui5cci/..." - the abap2UI5 frontend registers the
  // z2ui5cci resource root for its delivery mode (sibling BSP, launchpad or
  // standalone ICF service), and only the loader knows which one applied.
  const url = (path) => sap.ui.require.toUrl(`z2ui5cci/${path}`);

  // Adds a <link rel="stylesheet"> once and resolves when it is applied.
  function loadStyle(href) {
    if (!href) return Promise.reject(new Error("no stylesheet URL"));
    if (styles.has(href)) return styles.get(href);

    const pending = new Promise((resolve, reject) => {
      const tag = document.createElement("link");
      tag.rel = "stylesheet";
      tag.href = href;
      tag.addEventListener("load", () => resolve());
      tag.addEventListener("error", () =>
        reject(new Error(`could not load ${href}`)),
      );
      document.head.appendChild(tag);
    });

    // A failed load must not be cached as failed forever - a later render
    // (or a corrected URL) has to be able to try again.
    pending.catch(() => styles.delete(href));
    styles.set(href, pending);
    return pending;
  }

  // Adds a <script> once and resolves when it is ready. `isReady` lets a
  // caller skip the whole thing when the library is already on the page.
  function loadScript(src, isReady) {
    if (typeof isReady === "function" && isReady()) return Promise.resolve();
    if (!src) return Promise.reject(new Error("no script URL"));
    if (scripts.has(src)) return scripts.get(src);

    const pending = new Promise((resolve, reject) => {
      const tag = document.createElement("script");
      tag.src = src;
      tag.async = true;
      tag.addEventListener("load", () => resolve());
      tag.addEventListener("error", () =>
        reject(new Error(`could not load ${src}`)),
      );
      document.head.appendChild(tag);
    });

    pending.catch(() => scripts.delete(src));
    scripts.set(src, pending);
    return pending;
  }

  return { logError, isDestroyed, url, loadStyle, loadScript };
});
