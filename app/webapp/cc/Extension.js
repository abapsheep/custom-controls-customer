// z2ui5_ccc.cc.Extension - the bootstrap element of this extension BSP.
//
// THIS IS THE FILE YOU EDIT. Everything that has to happen once, before a
// view can use your artefacts, is declared in the four config blocks below:
// extra resource roots, UI5 reuse libraries, icon fonts and stylesheets.
//
// An abap2UI5 app pulls it into a view with one line of ABAP:
//
//     z2ui5_cl_ccc=>render( page ).
//
// It renders nothing (a hidden span) - it installs things. That is also why
// it is a control and not a plain module: a control can be named in the view
// XML, so it is the backend that decides when the extension is needed, and a
// system without this BSP simply never asks for it.
//
// Ordering: registration happens in init(), not in onAfterRendering, because
// another control in the SAME view may render before this one does - an
// sap.m.Button with icon="sap-icon://my-icons/Regal" would then look up a
// collection that is not registered yet and render a blank icon.
sap.ui.define(
  ["sap/ui/core/Control", "sap/ui/core/IconPool", "z2ui5_ccc/Util"],
  (Control, IconPool, Util) => {
    "use strict";

    // ------------------------------------------------------------------
    // 1. Resource roots of OTHER BSPs
    // ------------------------------------------------------------------
    // Only needed when a reuse library already lives in its own BSP and you
    // do not want to move it in here. Key is the UI5 module namespace, value
    // the URL its root maps to.
    //
    // This is what replaces hand-patching data-sap-ui-resourceroots in the
    // abap2UI5 index.html - that file is generated and force-overwritten on
    // every framework update, this one is yours.
    //
    // Artefacts that live in THIS BSP need no entry: abap2UI5 registers
    // z2ui5_ccc itself.
    const RESOURCE_ROOTS = {
       "com.myorg.reuselib": "/sap/bc/ui5_ui5/sap/zreuseicons/"
    };

    // ------------------------------------------------------------------
    // 2. UI5 libraries to load
    // ------------------------------------------------------------------
    // A library whose library.js must run even when no control of it appears
    // in the view - the usual case being a library that exists only to
    // register an icon font. Replaces the "libs" entry in the framework's
    // manifest.json.
    const LIBRARIES = [
       "com.myorg.reuselib"
    ];

    // ------------------------------------------------------------------
    // 3. Icon fonts
    // ------------------------------------------------------------------
    // Makes an icon font usable as sap-icon://<collectionName>/<iconName> in
    // any UI5 icon property. `fontURI` is the DIRECTORY holding the font file
    // and, unless you pass `metadata` yourself, the <fontFamily>.json that
    // maps icon names to code points.
    //
    // `metadata` is the way out when you cannot serve that JSON as a file:
    // give the mapping inline and the IconPool never fetches it. The name ->
    // code point pairs are exactly what the SAP reuse-library recipe puts
    // into its library.js as IconPool.addIcon() calls.
    const ICON_FONTS = [
       {
         fontFamily: "MyCustomFontFamily",
         collectionName: "my-icons",
         fontURI: Util.url("fonts"),
         metadata: { bestandsInfoHU: "e900", bestandsInfoLager: "e901" }
       }
    ];

    // ------------------------------------------------------------------
    // 4. Stylesheets
    // ------------------------------------------------------------------
    // Own CSS classes, @font-face rules, corporate colours. Served from this
    // BSP by default; an absolute URL works too.
    const STYLESHEETS = [Util.url("css/style.css")];

    // ------------------------------------------------------------------

    // Everything below is generic - it applies the four blocks above exactly
    // once per page, no matter how many views render the control.
    let installed = false;

    // sap/ui/core/Lib arrived in UI5 1.118 and is the only library API left
    // in UI5 2.x; abap2UI5 still supports OpenUI5 1.71, where the core
    // singleton is the only way. Resolve lazily so the module is never a hard
    // dependency - on 1.71 a hard dependency would 404 and take the whole
    // control down with it.
    function loadLibrary(name) {
      const Lib = sap.ui.require("sap/ui/core/Lib");
      if (Lib?.load) return Lib.load({ name });
      if (sap.ui.getCore) {
        return Promise.resolve(
          sap.ui.getCore().loadLibrary(name, { async: true }),
        );
      }
      return Promise.reject(new Error("no UI5 library loader available"));
    }

    function registerFont(font) {
      // registerFont throws on a collection the IconPool already knows, and
      // the registration is global - so this must not run twice. `installed`
      // guards it; the try/catch keeps a mistyped entry from stopping the
      // ones after it.
      try {
        IconPool.registerFont({
          lazy: !font.metadata,
          ...font,
        });
      } catch (e) {
        Util.logError(
          `Extension: could not register icon font '${font.collectionName}'`,
          e,
        );
      }
    }

    function install() {
      if (installed) return;
      installed = true;

      if (Object.keys(RESOURCE_ROOTS).length) {
        // sap.ui.loader.config takes slash-separated paths, while a UI5
        // namespace is written with dots - convert, so both spellings work
        // in the config block above.
        const paths = {};
        for (const [ns, target] of Object.entries(RESOURCE_ROOTS)) {
          paths[ns.replace(/\./g, "/")] = target;
        }
        sap.ui.loader.config({ paths });
      }

      ICON_FONTS.forEach(registerFont);

      STYLESHEETS.forEach((href) =>
        Util.loadStyle(href).catch((e) =>
          Util.logError(`Extension: stylesheet ${href} not available`, e),
        ),
      );

      // Libraries load asynchronously and nothing here waits for them: a
      // library that only registers icons has no control the view could
      // reference, and one that does have controls is awaited by the XML
      // template processor anyway when the view names its namespace.
      LIBRARIES.forEach((name) =>
        loadLibrary(name).catch((e) =>
          Util.logError(`Extension: library ${name} failed to load`, e),
        ),
      );
    }

    return Control.extend("z2ui5_ccc.cc.Extension", {
      metadata: {},

      // init must not return a value - UI5 2.x rejects a Promise here
      // (_enforceNoReturnValue). install() is synchronous on purpose; the
      // async work it kicks off is fire-and-forget with its own catch.
      init() {
        install();
      },

      // Nothing visible - the control installs artefacts, it does not draw.
      renderer: {
        apiVersion: 2,
        render(rm, control) {
          rm.openStart("span", control);
          rm.style("display", "none");
          rm.openEnd();
          rm.close("span");
        },
      },
    });
  },
);
