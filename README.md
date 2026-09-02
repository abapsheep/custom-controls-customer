[![abap version](https://img.shields.io/badge/abap%20version-standard%20%28%E2%89%A5%207.50%29-blue)](#install)
[![namespace](https://img.shields.io/badge/namespace-z2ui5__cl__ccc-blue)](abaplint.jsonc)
[![bsp](https://img.shields.io/badge/bsp-Z2UI5__CCC-blue)](#how-it-works)
[![dependency](https://img.shields.io/badge/dependency-abap2UI5-blue)](https://github.com/abap2UI5/abap2UI5)
<br>
<br>
[![check](https://github.com/abap2UI5/custom-controls-customer/actions/workflows/check.yml/badge.svg)](https://github.com/abap2UI5/custom-controls-customer/actions/workflows/check.yml)

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

abap2UI5 reserves the resourceRoot **`z2ui5_ccc`** in its `manifest.json`:

```json
"sap.ui5": { "resourceRoots": { "z2ui5_cci": "../z2ui5_cci/", "z2ui5_ccc": "../z2ui5_ccc/" } }
```

so the module `z2ui5_ccc/cc/Example` is served from
`/sap/bc/ui5_ui5/sap/z2ui5_ccc/cc/Example.js` — the BSP `Z2UI5_CCC` that this
repository builds. In the standalone HTTP service, where there is no sibling
BSP to resolve `../z2ui5_ccc/` against, `z2ui5_cl_http_handler` hands the
absolute path to the frontend instead. All three delivery modes (BSP,
launchpad, ICF service) therefore resolve it without configuration.

Registering the path costs nothing when this repository is not installed:
the browser requests nothing from `z2ui5_ccc` until a view actually names the
namespace.

```
your ABAP app  ──►  z2ui5_cl_ccc=>render( page )
                          │  emits <z2ui5_ccc:Extension/> into the view
                          ▼
abap2UI5 frontend  ──►  loads z2ui5_ccc/cc/Extension.js from YOUR BSP
                          │  which registers, at page level:
                          ├─ resource roots of other BSPs
                          ├─ UI5 reuse libraries
                          ├─ icon fonts (IconPool)
                          └─ stylesheets
```

## Install

1. Install this repository with abapGit. It brings the ABAP classes, the BSP
   application `Z2UI5_CCC` and the two ICF nodes it is served from.
2. Start **`?app_start=z2ui5_cl_ccc_sample_00`** — the check app. If the badge
   renders, is styled and reacts to a click, the BSP is deployed and the
   frontend resolves `z2ui5_ccc`.
3. Start **`?app_start=z2ui5_cl_ccc_sample_01`** — the icon gallery. It lists
   every icon of the font this repository ships. Glyphs next to the names mean
   the font travelled into the browser and the IconPool resolved the
   collection; names with *empty* icons next to them mean it did not.

Requires an abap2UI5 version that reserves the `z2ui5_ccc` resourceRoot. On an
older framework the check app renders an empty page and the browser console
shows a failed request for `z2ui5_ccc/cc/Extension.js`.

## Putting your artefacts in

### 1. Drop the files under `app/webapp/`

```
app/webapp/
├── index.html          the BSP start page - a note, this BSP has no UI
├── Util.js             small helpers (url, loadStyle, loadScript, logError)
├── cc/
│   ├── Extension.js    THE FILE YOU EDIT - the four config blocks
│   └── Example.js      a template custom control
├── css/
│   └── style.css       your CSS
└── fonts/
    └── MyCustomFontFamily.js   GENERATED - the font, base64, + its name map
```

`fonts/` is written by `npm run font2js` from the font sources in `fonts/` at
the repository root, which are **not** part of the BSP — see
[Binary artefacts](#binary-artefacts) for why the font has to travel as
JavaScript at all.

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

const ICON_FONTS = [MyCustomFontFamily];   // the generated module - see below

const STYLESHEETS = [Util.url("css/style.css")];
```

Those four blocks are the replacement for the four framework patches in the
table above, one for one.

### 3. Regenerate and commit

```bash
npm run font2js        # fonts/ -> app/webapp/fonts + src/z2ui5_if_ccc_icon.intf.abap
npm run app2bsp        # app/webapp -> src/01 (BSP pages, page directory, ICF nodes)
npx abaplint abaplint.jsonc
```

CI runs all three and fails on a diff, so a stale BSP page can never ship old
JavaScript unnoticed, and a font swapped in without regenerating fails there
rather than on a system, where the only symptom is a blank icon.

### 4. Use it from ABAP

```abap
DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).

DATA(root) = view->ele( n  = `View`
                        ns = `mvc`
    )->a( n = `xmlns`     v = `sap.m`
    )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc` ).

z2ui5_cl_ccc=>xmlns( root ).             " declares xmlns:z2ui5_ccc - once per view

DATA(page) = root->ele( `Page` )->a( n = `title` v = `Warehouse` ).

z2ui5_cl_ccc=>render( page ).            " loads and installs the extension

page->tag( `Button`
    )->a( n = `icon` v = z2ui5_if_ccc_icon=>regal     " your own icon font
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
`app/webapp` — `app2bsp` would mangle it, so it rejects the name instead.

The obvious way out is a base64 `data:` URI, because a data URI *is* text. It
works — but **not from `css/style.css`**, where it is the first thing anyone
tries. A BSP page stores its source as fixed 255-character lines, so `app2bsp`
wraps a longer line into chunks and the system serves those chunks back as
separate lines. CSS has no line continuation and the base64 of a real icon font
is tens of thousands of characters, so the `@font-face` arrives split across a
hundred lines and the rule is dead. Nothing reports it: the page is served, the
CSS parses to nothing, the icons are simply blank. (`app2bsp` now fails on any
source line over 255 characters rather than wrapping it, so this cannot ship
quietly any more.)

JavaScript *does* have line continuation — an array of short strings and a
`join("")`. That is the route this repository takes:

* **base64 in a JavaScript module** — `npm run font2js` reads
  `fonts/<FontFamily>.woff2`, chops its base64 into 200-character chunks and
  writes `app/webapp/fonts/<FontFamily>.js`, a module shaped to drop straight
  into `ICON_FONTS`. No line comes near the limit, no request leaves the page,
  and the font is in the transport with everything else.

  What makes it work with the `IconPool` is a detail worth knowing before you
  change it: UI5 does not take `fontURI` as the font's URL, it **builds** one,

  ```
  fontURI + fontFamily + ".woff2"
  ```

  and there is no way to switch that off. So the generated `fontURI` ends in a
  `#` — `registerFont` appends the `/` it is missing, and UI5 ends up
  requesting

  ```
  data:font/woff2;base64,<the font>#/MyCustomFontFamily.woff2
  ```

  where everything from the `#` on is the fragment, which the URL parser splits
  off before the data URI is decoded. UI5 gets the file name it insists on and
  the browser gets the font. Both of UI5's code paths are covered: the CSS
  `@font-face` rule 1.71 inserts (woff2, woff and ttf source, all three
  resolving to the one payload) and the `FontFace` object 1.120+ and UI5 2.x
  add to `document.fonts` (woff2 only).

  The name → code point map rides along inline, as `metadata` — and that entry
  needs **`metadataURI: ""`** beside it. `metadata` alone does not suppress the
  fetch: `_loadFontMetadata` defaults `metadataURI` to
  `fontURI + fontFamily + ".json"` whenever it is `undefined`, and reads the
  inline map only on the branch it takes when `metadataURI` is falsy. Left out,
  UI5 requests that `.json` against the data URI, the request dies on
  abap2UI5's CSP (`connect-src` is explicit and carries no `data:`), and the
  collection ends up **empty** — the names render, every glyph is blank, and
  the only trace is *"An error occurred loading the font metadata for
  collection"* in the console. Same on 1.71 and on 1.120+/2.x.

  Two things follow from the paragraph before. The payload **must be WOFF2** —
  it is the only format modern UI5 asks for, and the `format()` hint is matched
  against the actual bytes, so a `.ttf` renamed to `.woff2` loads nowhere;
  `font2js` checks the magic number rather than trusting the extension. And a
  browser without WOFF2 support (IE11, the only one UI5 1.71 still names) gets
  no icons.

  It also costs page weight: the base64 is ~33 % larger than the font and is
  parsed with the module, so it is the right route for an icon font of a few
  hundred glyphs and the wrong one for a text font.

* **MIME objects** — upload the font into the BSP with
  `/UI5/UI5_REPOSITORY_LOAD` (report `/UI5/UI5_REPOSITORY_LOAD` in `SE38`) or
  keep it as a `W3MI` object serialized by abapGit, then point `fontURI` at the
  URL it is served from. The right choice for anything large, for a font shared
  by several applications, or when you want the browser to cache it across
  sessions — at the price of a second artefact to deploy and a URL that depends
  on where it landed.

### Content-Security-Policy

A `data:` font is subject to `font-src`. The CSP abap2UI5 ships has no
`font-src` of its own, so fonts fall back to `default-src`, which carries
`data:` — nothing to do. A system that tightens this in its own
`z2ui5_cl_ui5_user_exit` has to keep `data:` reachable for fonts, or the icons
disappear with a CSP violation in the console and nowhere else.

## The icon font this repository ships

The template comes with an [IcoMoon](https://icomoon.io) warehouse set, as an
example of the whole route end to end — swap `fonts/MyCustomFontFamily.*` for
your own and re-run `npm run font2js`. 30 icons, collection **`my-icons`**:

| Code | Icon name | ABAP constant | Code | Icon name | ABAP constant |
|---|---|---|---|---|---|
| `U+E900` | `bestandsInfoHU` | `z2ui5_if_ccc_icon=>bestandsinfohu` | `U+E90F` | `LKWbeladen` | `z2ui5_if_ccc_icon=>lkwbeladen` |
| `U+E901` | `bestandsInfoLager` | `z2ui5_if_ccc_icon=>bestandsinfolager` | `U+E910` | `Regal` | `z2ui5_if_ccc_icon=>regal` |
| `U+E902` | `bestandsInfoMat` | `z2ui5_if_ccc_icon=>bestandsinfomat` | `U+E911` | `Regal2` | `z2ui5_if_ccc_icon=>regal2` |
| `U+E903` | `bestandsInfoMat1` | `z2ui5_if_ccc_icon=>bestandsinfomat1` | `U+E912` | `Regal3` | `z2ui5_if_ccc_icon=>regal3` |
| `U+E904` | `bewegungAbgeschlossen` | `z2ui5_if_ccc_icon=>bewegungabgeschlossen` | `U+E913` | `Regal4` | `z2ui5_if_ccc_icon=>regal4` |
| `U+E905` | `bewegungAbgeschlossen1` | `z2ui5_if_ccc_icon=>bewegungabgeschlossen1` | `U+E914` | `Regal5` | `z2ui5_if_ccc_icon=>regal5` |
| `U+E906` | `fordertechnikaufladen` | `z2ui5_if_ccc_icon=>fordertechnikaufladen` | `U+E915` | `Stapler` | `z2ui5_if_ccc_icon=>stapler` |
| `U+E907` | `fordertechnikentnehmen` | `z2ui5_if_ccc_icon=>fordertechnikentnehmen` | `U+E916` | `Staplereinlagern` | `z2ui5_if_ccc_icon=>staplereinlagern` |
| `U+E908` | `kommisionierHUbeladen` | `z2ui5_if_ccc_icon=>kommisionierhubeladen` | `U+E917` | `Staplerentnehmen` | `z2ui5_if_ccc_icon=>staplerentnehmen` |
| `U+E909` | `KommisionierHUentnehmen` | `z2ui5_if_ccc_icon=>kommisionierhuentnehmen` | `U+E918` | `StaplerInfo` | `z2ui5_if_ccc_icon=>staplerinfo` |
| `U+E90A` | `Lageraufgabequitiert` | `z2ui5_if_ccc_icon=>lageraufgabequitiert` | `U+E919` | `StaplerLogin` | `z2ui5_if_ccc_icon=>staplerlogin` |
| `U+E90B` | `Lageraufgabequitiert1` | `z2ui5_if_ccc_icon=>lageraufgabequitiert1` | `U+E91A` | `StaplerLogout` | `z2ui5_if_ccc_icon=>staplerlogout` |
| `U+E90C` | `Lagerauslagern` | `z2ui5_if_ccc_icon=>lagerauslagern` | `U+E91B` | `StaplerLogout1` | `z2ui5_if_ccc_icon=>staplerlogout1` |
| `U+E90D` | `Lagereinlagern` | `z2ui5_if_ccc_icon=>lagereinlagern` | `U+E91C` | `umpacken` | `z2ui5_if_ccc_icon=>umpacken` |
| `U+E90E` | `LKWausladen` | `z2ui5_if_ccc_icon=>lkwausladen` | `U+E91D` | `umpacken1` | `z2ui5_if_ccc_icon=>umpacken1` |

Address one either as a literal, `sap-icon://my-icons/Regal`, or — better —
through the generated constant, `z2ui5_if_ccc_icon=>regal`. The names are
**case sensitive** in the URI and a wrong one is not an error anywhere: UI5
resolves it to nothing and draws an empty icon, silently. The constant turns
that into a syntax check.

The same glyphs are available outside an icon property through the CSS class
`z2ui5_cccIcon` in `css/style.css` — for a `sap.m.FormattedText`, say. It works
because the `@font-face` UI5 inserts on registration is global to the page.

### Swapping in your own font

1. Download from IcoMoon (or any generator) and put two files in `fonts/`:
   `<FontFamily>.woff2` — the glyphs — and `<FontFamily>.svg`, the SVG font,
   which is the only download that carries the glyph **names**; the ttf, woff
   and woff2 keep code points and drop them. IcoMoon emits eot/svg/ttf/woff, so
   the woff2 usually has to be converted:

   ```bash
   pip install fonttools brotli
   python3 -c "from fontTools.ttLib import TTFont; f=TTFont('icomoon.ttf'); f.flavor='woff2'; f.save('MyCustomFontFamily.woff2')"
   ```

2. Set `FONT_FAMILY` and `COLLECTION_NAME` at the top of `tools/font2js.mjs` —
   `FONT_FAMILY` is both the CSS family and the base name of those two files,
   and UI5 derives the font URL from it, so the two cannot drift apart. Keep
   `COLLECTION_NAME` lower case: it ends up in a URI hostname position.
3. `npm run font2js && npm run app2bsp`, and commit what they write.

## Naming

ABAP objects here follow the scheme `z2ui5_<type>_<token>_<object>` the
abap2UI5 repositories share, with the token **`ccc`** — *custom control
customers* — reserved for this one, the way `smp` belongs to
[abap2UI5/samples](https://github.com/abap2UI5/samples) and `cc` to the
community add-on. So every class starts with `Z2UI5_CL_CCC` (`Z2UI5_CX_CCC`
for exceptions, `Z2UI5_IF_CCC` for interfaces) and is at most 25 characters
long — `object_naming` in `abaplint.jsonc` enforces both, and the comment
there explains where the 25 comes from.

The frontend side carries the same token: the BSP is `Z2UI5_CCC` and the
resourceRoot it is served under is **`z2ui5_ccc`** — the ABAP name of the BSP,
lowercased. A resourceRoot resolves to the BSP's URL
(`/sap/bc/ui5_ui5/sap/z2ui5_ccc/`), so the two are necessarily the same
string, and keeping the ABAP token in it means there is one name to remember
for the whole repository instead of two. It is reserved in the abap2UI5
`manifest.json`, which is what makes this BSP findable without patching
anything downstream.

The community controls follow the same rule, so
[abap2UI5-addons/custom-controls](https://github.com/abap2UI5-addons/custom-controls)
ships the BSP `Z2UI5_CCI` under the root `z2ui5_cci` for its `z2ui5_cl_cci*`
classes. The two roots therefore differ in the last letter only: `_cci` is
the community one, `_ccc` this one. They are distinct strings and cannot
collide, but a typo in a view's `xmlns:` resolves against the wrong BSP and
shows up only as a failed module request in the browser console — so when a
control does not render, check that letter first.

## Renaming

`Z2UI5_CCC` and the `Z2UI5_CL_CCC*` classes are the defaults. To use your own
namespace, change `BSP` and `PREFIX` in `tools/app2bsp.mjs`, the
`resourceRoots` key the frontend registers, the class names, and the
`object_naming` patterns in `abaplint.jsonc` — all together.

Be aware that `z2ui5_ccc` is the namespace abap2UI5 registers out of the box.
Renaming it means registering the new one yourself, which puts you back in the
business of patching framework files — so rename the ABAP objects if your
system demands it, but keep the resourceRoot.

## What is in the box

| Artefact | Purpose |
|---|---|
| `app/webapp/cc/Extension.js` | the bootstrap element — resource roots, libraries, icon fonts, stylesheets |
| `app/webapp/cc/Example.js` | a template custom control (property, event, renderer) |
| `app/webapp/Util.js` | `url`, `loadStyle`, `loadScript`, `logError`, `isDestroyed` |
| `app/webapp/fonts/MyCustomFontFamily.js` | **generated** — the icon font as base64 plus its name → code point map |
| `fonts/` | the font sources the generator reads; outside `app/webapp`, so never a BSP page |
| `src/z2ui5_cl_ccc.clas.abap` | ABAP side — `xmlns( )`, `render( )`, `example( )`, `tag( )` |
| `src/z2ui5_if_ccc_icon.intf.abap` | **generated** — one constant per icon |
| `src/00/z2ui5_cl_ccc_sample_00.clas.abap` | installation check app |
| `src/00/z2ui5_cl_ccc_sample_01.clas.abap` | icon gallery — the check app for the font |
| `tools/font2js.mjs` | `fonts/` → the icon font module and the ABAP icon interface |
| `tools/app2bsp.mjs` | `app/webapp` → the abapGit BSP artefacts under `src/01` |

## Dependencies

* [abap2UI5](https://github.com/abap2UI5/abap2UI5) — the framework, installed
  in the backend
* [abap2UI5/frontend](https://github.com/abap2UI5/frontend) — the frontend BSP,
  when running in BSP or launchpad mode

## Related

* [abap2UI5-addons/custom-controls](https://github.com/abap2UI5-addons/custom-controls)
  — the same mechanism under the reserved namespace `z2ui5_cci`, for controls
  shared with the community. If what you are building is generally useful,
  contribute it there instead.
