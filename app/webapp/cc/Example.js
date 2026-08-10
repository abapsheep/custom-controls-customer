// z2ui5ext.cc.Example - a minimal custom control, here as a template.
//
// It shows the three things a control needs to be usable from ABAP:
//
//   a property   `text`, two-way bindable, so client->_bind( ) writes back
//   an event     `press`, so client->_event( ) arrives in on_event
//   a renderer   apiVersion 2, no innerHTML, no eval
//
// Delete it once you have your own, or keep it as the smoke test the sample
// app renders. The ABAP side is z2ui5_cl_ccc=>example( ).
sap.ui.define(["sap/ui/core/Control"], (Control) => {
  "use strict";

  return Control.extend("z2ui5ext.cc.Example", {
    metadata: {
      properties: {
        text: { type: "string", defaultValue: "" },
        // a plain CSS colour, applied to the badge background
        color: { type: "string", defaultValue: "#0a6ed1" },
      },
      events: {
        press: {},
      },
    },

    onclick() {
      this.firePress();
    },

    renderer: {
      apiVersion: 2,
      render(rm, control) {
        rm.openStart("span", control);
        rm.class("z2ui5extExample");
        // Written as a style, not as a class: the value is app data, and a
        // generated class name would need CSS this BSP cannot know upfront.
        // The renderer API escapes it, so a hostile value cannot break out.
        rm.style("background-color", control.getColor());
        rm.openEnd();
        // rm.text() escapes - never assemble HTML from bound data
        rm.text(control.getText());
        rm.close("span");
      },
    },
  });
});
