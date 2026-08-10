# abap2UI5 customer frontend extension

A template repository for **your own** frontend artefacts — a UI5 reuse
library, an icon font, corporate CSS, a custom control — served to
[abap2UI5](https://github.com/abap2UI5/abap2UI5) from a BSP that belongs to
you.

Fork it (or copy it into your own git host), put your files under
`app/webapp/`, run `npm run app2bsp`, and install the result with abapGit.
Nothing in abap2UI5 or in its frontend BSP has to change, and no pull request
against the framework is needed.

## The problem this solves

Adding a UI5 reuse library to abap2UI5 used to mean patching the framework's
own BSP by hand, in four places:

| File | Patch |
|---|---|
| `index.html` | `data-sap-ui-resourceroots` → `"com.myorg.reuselib": "/sap/bc/ui5_ui5/sap/zreuseicons/"` |
| `manifest.json` | `sap.ui5.dependencies.libs` → `"com.myorg.reuselib": {}` |
| `View1.view.xml` | `xmlns:custom="com.myorg.reuselib"` |
| `View1.controller.js` | `sap.ui.define([… "com/myorg/reuselib/library"])` |

All four are **generated** from `app/webapp` in the abap2UI5 repository and
force-overwritten in [abap2UI5/frontend](https://github.com/abap2UI5/frontend)
on every framework update — so the patch survives exactly until the next
upgrade, and then the icons are gone with no error message.

This repository is the supported place for those artefacts instead. It is the
same mechanism [abap2UI5-addons/custom-controls](https://github.com/abap2UI5-addons/custom-controls)
uses for the community controls, with a second reserved namespace so the two
never collide.

## How it works

abap2UI5 reserves the resourceRoot **`z2ui5cci`** in its `manifest.json`:

```json
"sap.ui5": { "resourceRoots": { "z2ui5ccc": "../z2ui5ccc/", "z2ui5cci": "../z2ui5cci/" } }
```

so the module `z2ui5cci/cc/Example` is served from
`/sap/bc/ui5_ui5/sap/z2ui5cci/cc/Example.js` — the BSP `Z2UI5CCI` that this
repository builds. In the standalone HTTP service, where there is no sibling
BSP to resolve `../z2ui5cci/` against, `z2ui5_cl_http_handler` hands the
absolute path to the frontend instead. All three delivery modes (BSP,
launchpad, ICF service) therefore resolve it without configuration.

Registering the path costs nothing when this repository is not installed:
the browser requests nothing from `z2ui5cci` until a view actually names the
namespace.

```
your ABAP app  ──►  z2ui5_cl_ccc=>render( page )
                          │  emits <z2ui5cci:Extension/> into the view
                          ▼
abap2UI5 frontend  ──►  loads z2ui5cci/cc/Extension.js from YOUR BSP
                          │  which registers, at page level:
                          ├─ resource roots of other BSPs
                          ├─ UI5 reuse libraries
                          ├─ icon fonts (IconPool)
                          └─ stylesheets
```

## Install

1. Install this repository with abapGit. It brings the ABAP classes, the BSP
   application `Z2UI5CCI` and the two ICF nodes it is served from.
2. Start **`?app_start=z2ui5_cl_ccc_sample_00`** — the check app. If the badge
   renders, is styled and reacts to a click, the BSP is deployed and the
   frontend resolves `z2ui5cci`.

Requires an abap2UI5 version that reserves the `z2ui5cci` resourceRoot. On an
older framework the check app renders an empty page and the browser console
shows a failed request for `z2ui5cci/cc/Extension.js`.

## Putting your artefacts in

### 1. Drop the files under `app/webapp/`

```
app/webapp/
├── index.html          the BSP start page - a note, this BSP has no UI
├── Util.js             small helpers (url, loadStyle, loadScript, logError)
├── cc/
│   ├── Extension.js    THE FILE YOU EDIT - the four config blocks
│   └── Example.js      a template custom control
└── css/
    └── style.css       your CSS
```

Two limits come from the BSP page format and are checked by `app2bsp`, which
fails loudly rather than letting SAP reject the import:

* **at most one directory level** — `cc/Example.js` is fine, `cc/lib/x.js` is not
* **names from letters, digits, `_` and `.` only** — no hyphens

### 2. Declare what has to be registered

Everything that must happen once, before a view can use your artefacts, is
declared at the top of `app/webapp/cc/Extension.js`:

```js
const RESOURCE_ROOTS = {
  "com.myorg.reuselib": "/sap/bc/ui5_ui5/sap/zreuseicons/",
};

const LIBRARIES = ["com.myorg.reuselib"];

const ICON_FONTS = [{
  fontFamily: "MyCustomFontFamily",
  collectionName: "my-icons",
  fontURI: Util.url("fonts"),
  metadata: { Regal: "e910", Stapler: "e917" },
}];

const STYLESHEETS = [Util.url("css/style.css")];
```

Those four blocks are the replacement for the four framework patches in the
table above, one for one.

### 3. Regenerate and commit

```bash
npm run app2bsp        # app/webapp -> src/01 (BSP pages, page directory, ICF nodes)
npx abaplint abaplint.jsonc
```

CI runs both and fails on a diff, so a stale BSP page can never ship old
JavaScript unnoticed.

### 4. Use it from ABAP

```abap
DATA(view) = z2ui5_cl_ai_xml=>factory( ).

DATA(root) = view->open( n  = `View`
                         ns = `mvc`
    )->a( n = `xmlns`     v = `sap.m`
    )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc` ).

z2ui5_cl_ccc=>xmlns( root ).             " declares xmlns:z2ui5cci - once per view

DATA(page) = root->open( `Page` )->a( n = `title` v = `Warehouse` ).

z2ui5_cl_ccc=>render( page ).            " loads and installs the extension

page->leaf( `Button`
    )->a( n = `icon` v = `sap-icon://my-icons/Regal`   " your own icon font
    )->a( n = `text` v = `Rack` ).

client->view_display( view->stringify( ) ).
```

`render( )` is what pulls `Extension.js` into the page, so it belongs in every
view that relies on an icon font, a stylesheet or a registered library —
before the controls that use them. Calling it twice is harmless; the
installation runs once per page.

## Keeping an existing reuse-library BSP

You do not have to move an existing library into this BSP. Leave
`ZREUSEICONS` where it is and register it in `RESOURCE_ROOTS` plus
`LIBRARIES` — one entry each, in a file that no framework update overwrites.
The library keeps its own name (`com.myorg.reuselib`), and views address it
under their own prefix:

```abap
root->a( n = `xmlns:custom` v = `com.myorg.reuselib` ).
```

Moving it in here is still the tidier option when you can: one BSP, one
transport, one thing to install.

## Binary artefacts

BSP pages are **text**. A `.woff2`, `.ttf` or `.png` cannot be committed under
`app/webapp` — `app2bsp` would mangle it, so it rejects the name instead. Two
ways work:

* **base64 data URI in CSS** — for a single icon font this is the simplest
  path, because a data URI *is* text and rides along in `css/style.css`:

  ```css
  @font-face {
    font-family: "MyCustomFontFamily";
    src: url("data:font/woff2;base64,d09GMgABAAAAA...") format("woff2");
  }
  ```

  Note that the UI5 `IconPool` needs the font file itself at `fontURI`, so for
  `sap-icon://` icons use the MIME route below; a data URI covers the CSS-class
  usage (`<span class="my-icons">`).

* **MIME objects** — upload the font into the BSP with
  `/UI5/UI5_REPOSITORY_LOAD` (report `/UI5/UI5_REPOSITORY_LOAD` in `SE38`) or
  keep it as a `W3MI` object serialized by abapGit, then point `fontURI` at
  the URL it is served from. This is the right choice for anything large or
  for a font the IconPool has to read.

## Naming

ABAP objects here follow the scheme `z2ui5_<type>_<token>_<object>` the
abap2UI5 repositories share, with the token **`ccc`** — *custom control
customers* — reserved for this one, the way `smp` belongs to
[abap2UI5/samples](https://github.com/abap2UI5/samples) and `cc` to the
community add-on. So every class starts with `Z2UI5_CL_CCC` (`Z2UI5_CX_CCC`
for exceptions, `Z2UI5_IF_CCC` for interfaces) and is at most 25 characters
long — `object_naming` in `abaplint.jsonc` enforces both, and the comment
there explains where the 25 comes from.

The frontend side carries the same idea one level up: the BSP is `Z2UI5CCI`
and the resourceRoot it is served under is **`z2ui5cci`** — *custom control
customer individual* — next to the community `z2ui5ccc`, so the two roots can
never collide. That name is reserved in the abap2UI5 `manifest.json`, which
is what makes this BSP findable without patching anything downstream.

The two are deliberately not the same string: `ccc` names ABAP objects, where
`z2ui5cci` is not a legal prefix, and `z2ui5cci` names a UI5 module namespace,
where the underscores of an ABAP name have no place.

## Renaming

`Z2UI5CCI` and the `Z2UI5_CL_CCC*` classes are the defaults. To use your own
namespace, change `BSP` and `PREFIX` in `tools/app2bsp.mjs`, the
`resourceRoots` key the frontend registers, the class names, and the
`object_naming` patterns in `abaplint.jsonc` — all together.

Be aware that `z2ui5cci` is the namespace abap2UI5 registers out of the box.
Renaming it means registering the new one yourself, which puts you back in the
business of patching framework files — so rename the ABAP objects if your
system demands it, but keep the resourceRoot.

## What is in the box

| Artefact | Purpose |
|---|---|
| `app/webapp/cc/Extension.js` | the bootstrap element — resource roots, libraries, icon fonts, stylesheets |
| `app/webapp/cc/Example.js` | a template custom control (property, event, renderer) |
| `app/webapp/Util.js` | `url`, `loadStyle`, `loadScript`, `logError`, `isDestroyed` |
| `src/z2ui5_cl_ccc.clas.abap` | ABAP side — `xmlns( )`, `render( )`, `example( )`, `leaf( )` |
| `src/00/z2ui5_cl_ccc_sample_00.clas.abap` | installation check app |
| `tools/app2bsp.mjs` | `app/webapp` → the abapGit BSP artefacts under `src/01` |

## Dependencies

* [abap2UI5](https://github.com/abap2UI5/abap2UI5) — the framework, installed
  in the backend
* [abap2UI5/frontend](https://github.com/abap2UI5/frontend) — the frontend BSP,
  when running in BSP or launchpad mode

## Related

* [abap2UI5-addons/custom-controls](https://github.com/abap2UI5-addons/custom-controls)
  — the same mechanism under the reserved namespace `z2ui5ccc`, for controls
  shared with the community. If what you are building is generally useful,
  contribute it there instead.
