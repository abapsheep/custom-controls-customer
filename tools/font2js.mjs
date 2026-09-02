// Generates, from the font sources under fonts/, the two artefacts that carry
// the icon set into an abap2UI5 app:
//
//   app/webapp/fonts/<FONT_FAMILY>.js   the font itself + the name -> code
//                                       point map, as a UI5 module
//   src/z2ui5_if_ccc_icon.intf.abap     one ABAP constant per icon
//
// Both come out of the same IcoMoon selection, so an icon renamed in the font
// cannot silently keep working on the ABAP side.
//
// Why a generator and not a checked-in file: a BSP page is TEXT, so the font
// has to travel as base64 inside a JavaScript module, and base64 of a real
// icon font is a five-figure number of characters. Chopping that into lines
// short enough for a BSP page (see LINE_WIDTH in app2bsp.mjs) is exactly the
// kind of thing nobody should do by hand - and the icon names have to stay in
// sync with the font file they are read from.
//
// Run: npm run font2js - and commit what it writes. CI regenerates and fails
// on a diff, the same way it does for app2bsp.
import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

// ---------------------------------------------------------------------------
// The one place the font is named.
//
// FONT_FAMILY is the CSS font-family AND the base name of the files under
// fonts/ - UI5 derives the font URL from it, so the two cannot drift apart.
// COLLECTION_NAME is what a view writes: sap-icon://<COLLECTION_NAME>/<icon>.
// It ends up in a URI hostname position, so keep it lower case.
// ---------------------------------------------------------------------------
const FONT_FAMILY = "MyCustomFontFamily";
const COLLECTION_NAME = "my-icons";
// what a UI5 icon property expects in front of the collection
const ICON_URI_SCHEME = "sap-icon://";
const ABAP_DESCRIPT = "abap2UI5 customer frontend extension - icons";

const SOURCE_DIR = "fonts";
const TARGET_DIR = "app/webapp/fonts";
// ABAP side: the interface holding one constant per icon. Its name follows the
// object_naming pattern in abaplint.jsonc; the .intf.xml sidecar next to it is
// metadata and stays hand-written.
const ABAP_INTF = "src/z2ui5_if_ccc_icon.intf.abap";

// The generated file is a BSP page like every other one, so no line of it may
// exceed the 255 characters app2bsp pads to - a longer line is wrapped into
// 255-character chunks, and a base64 literal wrapped mid-string is a syntax
// error on the customer's system, not here. 200 leaves room for the indent
// and the quotes the chunks are wrapped in.
const B64_CHUNK = 200;
const MAX_LINE = 255;

// UI5 asks for exactly <fontFamily>.woff2 from 1.120 on (_IconRegistry builds
// a FontFace with a single woff2 source); 1.71 tries woff2, woff and ttf in
// that order. woff2 is therefore the only payload that works on every release
// abap2UI5 supports, and the format() hint UI5 emits for the first source has
// to match the bytes or the browser skips it without a word.
const WOFF2_MAGIC = "wOF2";

function readFont() {
  const path = join(SOURCE_DIR, `${FONT_FAMILY}.woff2`);
  let bytes;
  try {
    bytes = readFileSync(path);
  } catch {
    throw new Error(
      `${path} not found. The embedded payload must be WOFF2 - it is the only ` +
        `format UI5 1.120+ requests. IcoMoon emits eot/svg/ttf/woff; convert ` +
        `the ttf with e.g.  pip install fonttools brotli  and\n` +
        `  python3 -c "from fontTools.ttLib import TTFont; f=TTFont('${FONT_FAMILY}.ttf'); f.flavor='woff2'; f.save('${FONT_FAMILY}.woff2')"`,
    );
  }
  if (bytes.subarray(0, 4).toString("latin1") !== WOFF2_MAGIC) {
    throw new Error(
      `${path} is not a WOFF2 file (magic '${WOFF2_MAGIC}' missing). A ttf or ` +
        `woff renamed to .woff2 loads nowhere: the browser matches the ` +
        `format('woff2') hint UI5 emits against the actual bytes.`,
    );
  }
  return bytes;
}

// The IcoMoon SVG font is the only download that carries the icon NAMES -
// the ttf/woff/woff2 keep code points and drop them (post table format 3).
// So the names come from there and the glyphs from the woff2; both are
// generated from the same IcoMoon selection and cannot disagree.
function readMetadata() {
  const path = join(SOURCE_DIR, `${FONT_FAMILY}.svg`);
  const svg = readFileSync(path, "utf8");
  const metadata = {};
  const re = /<glyph\b[^>]*\bunicode="&#x([0-9a-fA-F]+);"[^>]*\bglyph-name="([^"]+)"/g;
  for (const [, code, name] of svg.matchAll(re)) {
    // The space glyph and any other name UI5 could not address are not icons.
    if (!/^[A-Za-z][A-Za-z0-9_-]*$/.test(name)) continue;
    metadata[name] = code.toLowerCase();
  }
  if (!Object.keys(metadata).length) {
    throw new Error(`${path} declares no named glyph - is it an IcoMoon SVG font?`);
  }
  return metadata;
}

const chunk = (s, n) => s.match(new RegExp(`.{1,${n}}`, "g")) ?? [];

const font = readFont();
const metadata = readMetadata();
const b64 = chunk(font.toString("base64"), B64_CHUNK);
const names = Object.keys(metadata).sort((a, b) =>
  metadata[a] < metadata[b] ? -1 : 1,
);

const out = [
  `// z2ui5_ccc.fonts.${FONT_FAMILY} - GENERATED by tools/font2js.mjs.`,
  `// Do not edit: run 'npm run font2js' after changing fonts/${FONT_FAMILY}.*.`,
  "//",
  `// ${names.length} icons, addressed from a view as`,
  `// sap-icon://${COLLECTION_NAME}/<name> - see the table in README.md.`,
  "//",
  "// The font travels as a data: URI because a BSP page is text and a .woff2",
  "// cannot be committed under app/webapp at all. What makes that work with",
  "// the IconPool - which builds the font URL itself, as",
  "//",
  "//     fontURI + fontFamily + '.woff2'",
  "//",
  "// - is the trailing '#': registerFont appends the missing '/', so the URL",
  `// UI5 ends up with is  data:font/woff2;base64,<data>#/${FONT_FAMILY}.woff2`,
  "// and everything from the '#' on is the fragment, which the URL parser",
  "// splits off before the data URI is decoded. So UI5 gets the file name it",
  "// insists on, the browser gets the font, and no request leaves the page.",
  "//",
  "// That covers both code paths: the CSS @font-face UI5 1.71 inserts (woff2,",
  "// woff and ttf source, all three resolving to this one payload) and the",
  "// FontFace object 1.120+ and UI5 2.x add to document.fonts (woff2 only).",
  "sap.ui.define([], () => {",
  '  "use strict";',
  "",
  "  // The font file, base64. Split because no line of a BSP page may exceed",
  `  // ${MAX_LINE} characters - join('') puts it back together in the browser.`,
  "  const DATA = [",
  ...b64.map((c) => `    "${c}",`),
  '  ].join("");',
  "",
  "  // name -> code point, the map IconPool would otherwise fetch as",
  `  // ${FONT_FAMILY}.json. Inline, so nothing is requested at all.`,
  "  const METADATA = {",
  ...names.map((n) => `    ${n}: "${metadata[n]}",`),
  "  };",
  "",
  "  // Shaped to be spread straight into an ICON_FONTS entry in cc/Extension.js.",
  "  return {",
  `    fontFamily: "${FONT_FAMILY}",`,
  `    collectionName: "${COLLECTION_NAME}",`,
  '    fontURI: "data:font/woff2;base64," + DATA + "#",',
  "    metadata: METADATA,",
  "  };",
  "});",
  "",
].join("\n");

// The whole point of the chunking - assert it rather than trust it.
const long = out
  .split("\n")
  .map((line, i) => [i + 1, line.length])
  .filter(([, len]) => len > MAX_LINE);
if (long.length) {
  console.error(
    `generated module has ${long.length} line(s) over ${MAX_LINE} characters: ` +
      long.map(([i, len]) => `${i} (${len})`).join(", "),
  );
  process.exit(1);
}

const target = join(TARGET_DIR, `${FONT_FAMILY}.js`);
writeFileSync(target, out, "utf8");

// ---------------------------------------------------------------------------
// The ABAP side
//
// A constant per icon rather than a string literal in every view: the glyph
// names are mixed case and UI5 looks them up case sensitively, so a typo in
// `sap-icon://my-icons/Stapelr` is not an error anywhere - the icon is simply
// not drawn. As a constant it is a syntax check.
// ---------------------------------------------------------------------------
const constName = (name) => name.toLowerCase();
const width = Math.max(...names.map((n) => constName(n).length));
const uri = (name) => `${ICON_URI_SCHEME}${COLLECTION_NAME}/${name}`;

const abap = [
  `"! <p class="shorttext synchronized" lang="en">${ABAP_DESCRIPT}</p>`,
  '"!',
  `"! The icons of the <em>${COLLECTION_NAME}</em> collection, one constant per`,
  '"! glyph. GENERATED by tools/font2js.mjs - run \'npm run font2js\' after',
  `"! changing fonts/${FONT_FAMILY}.*.`,
  '"!',
  '"! The collection is registered in the browser by',
  `"! <em>z2ui5_ccc/fonts/${FONT_FAMILY}.js</em>, which`,
  '"! <em>z2ui5_ccc/cc/Extension.js</em> hands to the UI5 IconPool - so a view',
  '"! that uses one of these constants has to render the bootstrap element',
  '"! first:',
  '"!',
  '"!   z2ui5_cl_ccc=&gt;render( page ).',
  '"!   page-&gt;tag( `Button`',
  '"!       )-&gt;a( n = `icon` v = z2ui5_if_ccc_icon=&gt;regal ).',
  '"!',
  '"! Without it the icon property holds a URI nothing resolves, and UI5 draws',
  '"! NO glyph and logs nothing - see the note in cc/Extension.js on why the',
  '"! registration happens in init( ) rather than after rendering.',
  '"!',
  '"! The constant names are the glyph names lower-cased; the values keep the',
  '"! font\'s own spelling, which is what UI5 looks up and IS case sensitive.',
  "INTERFACE z2ui5_if_ccc_icon",
  "  PUBLIC.",
  "",
  '  "! collection name - the host part of every URI below, and the name',
  '  "! cc/Extension.js registers the font under',
  `  CONSTANTS c_collection TYPE string VALUE \`${COLLECTION_NAME}\`.`,
  '  "! prefix every icon URI of this collection carries',
  `  CONSTANTS c_uri_prefix TYPE string VALUE \`${ICON_URI_SCHEME}${COLLECTION_NAME}/\`.`,
  "",
  ...names.flatMap((n) => [
    `  "! ${n} (U+${metadata[n].toUpperCase()})`,
    `  CONSTANTS ${constName(n).padEnd(width)} TYPE string VALUE \`${uri(n)}\`.`,
  ]),
  "",
  "ENDINTERFACE.",
  "",
].join("\n");

// 255 characters is an ABAP source line limit too - a longer one does not fail
// abaplint here, it fails the customer's abapGit import with "Literals across
// more than one line are not allowed", leaving an empty stub behind.
const longAbap = abap
  .split("\n")
  .filter((line) => line.length > MAX_LINE).length;
if (longAbap) {
  console.error(`${ABAP_INTF}: ${longAbap} line(s) over ${MAX_LINE} characters`);
  process.exit(1);
}
writeFileSync(ABAP_INTF, abap, "utf8");

console.log(
  `${SOURCE_DIR}/${FONT_FAMILY}.woff2 (${font.length} bytes) + ` +
    `${names.length} icon names -> ${target}, ${ABAP_INTF}`,
);
