"! <p class="shorttext synchronized" lang="en">abap2UI5 customer frontend extension</p>
"!
"! ABAP side of this repository's BSP: the XML namespace its elements are
"! emitted under, and the helpers that declare it on a view.
"!
"! The prefix resolves to the UI5 module namespace <em>z2ui5_ccc.cc</em>. Its
"! first segment is the resourceRoot the abap2UI5 frontend reserves in its
"! manifest.json, which is what makes this repository's BSP findable:
"!
"!   "sap.ui5": \{ "resourceRoots": \{ "z2ui5_ccc": "../z2ui5_ccc/" \} \}
"!
"! so <em>z2ui5_ccc/cc/Example</em> is served from
"! <em>/sap/bc/ui5_ui5/sap/z2ui5_ccc/cc/Example.js</em>. In the standalone HTTP
"! service, where there is no sibling BSP, the abap2UI5 HTTP handler hands the
"! absolute path to the frontend instead - either way nothing in abap2UI5 or in
"! its frontend BSP has to be patched for this repository to be reachable.
CLASS z2ui5_cl_ccc DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    "! XML namespace prefix used for this extension's elements
    CONSTANTS c_ns TYPE string VALUE `z2ui5_ccc`.
    "! UI5 module namespace the prefix resolves to
    CONSTANTS c_ns_uri TYPE string VALUE `z2ui5_ccc.cc`.

    "! attribute list - one `key=value` string per attribute, e.g.
    "! a = VALUE #( ( `text=Hello` ) ( `width=100%` ) ). Split on the first `=`.
    TYPES ty_t_attr TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    "! Declare the extension's XML namespace on a view or fragment root.
    "!
    "! Call it once, on the root element, before adding any element of this
    "! extension:
    "!
    "!   DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    "!   DATA(root) = view->ele( n = `View` ns = `mvc`
    "!       )->a( n = `xmlns`     v = `sap.m`
    "!       )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc` ).
    "!   z2ui5_cl_ccc=>xmlns( root ).
    "!
    "! @parameter view   | the builder positioned at the root element
    "! @parameter result | the unchanged view builder, for chaining
    CLASS-METHODS xmlns
      IMPORTING
        view          TYPE REF TO z2ui5_cl_ui5_view_builder
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ui5_view_builder.

    "! Render the bootstrap element of this extension.
    "!
    "! Renders nothing visible. It is what makes the browser load
    "! <em>z2ui5_ccc/cc/Extension.js</em>, which registers the resource roots,
    "! UI5 libraries, icon fonts and stylesheets declared there - so add it to
    "! every view that relies on any of them, before the controls that use
    "! them. Adding it twice is harmless; the installation runs once per page.
    "!
    "! @parameter view   | the builder positioned at the parent element
    "! @parameter result | the unchanged view builder, for chaining
    CLASS-METHODS render
      IMPORTING
        view          TYPE REF TO z2ui5_cl_ui5_view_builder
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ui5_view_builder.

    "! Render the Example control - the template control this repository
    "! ships. Replace it with builders for your own controls.
    "!
    "! @parameter view   | the builder positioned at the parent element
    "! @parameter text   | text shown in the badge, bindable
    "! @parameter color  | CSS colour of the badge background
    "! @parameter press  | event fired on click
    "! @parameter result | the unchanged view builder, for chaining
    CLASS-METHODS example
      IMPORTING
        view          TYPE REF TO z2ui5_cl_ui5_view_builder
        text          TYPE string OPTIONAL
        color         TYPE string OPTIONAL
        press         TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ui5_view_builder.

    "! Emit one element of this extension, skipping the attributes the caller
    "! left empty.
    "!
    "! Passing an EMPTY attribute is not the same as passing none: it would
    "! override the control's own defaultValue with an empty string. So the
    "! builders collect their parameters as `key=value` strings and let this
    "! method drop the ones whose value is initial.
    "!
    "! Mirrors z2ui5_cl_ui5_view_builder=>tag: the element is added as a child
    "! and the cursor stays on the current node, so the caller can keep chaining.
    "!
    "! @parameter view   | the builder positioned at the parent element
    "! @parameter name   | element name, without the namespace prefix
    "! @parameter a      | attributes as `key=value`; empty values are dropped
    "! @parameter result | the unchanged view builder, for chaining
    CLASS-METHODS tag
      IMPORTING
        view          TYPE REF TO z2ui5_cl_ui5_view_builder
        name          TYPE string
        a             TYPE ty_t_attr OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ui5_view_builder.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_ccc IMPLEMENTATION.

  METHOD xmlns.

    result = view->a( n = |xmlns:{ c_ns }|
                      v = c_ns_uri ).

  ENDMETHOD.

  METHOD render.

    result = tag( view = view
                  name = `Extension` ).

  ENDMETHOD.

  METHOD example.

    result = tag( view = view
                  name = `Example`
                  a    = VALUE #( ( |text={ text }| )
                                  ( |color={ color }| )
                                  ( |press={ press }| ) ) ).

  ENDMETHOD.

  METHOD tag.

    result = view->tag( n  = name
                        ns = c_ns ).

    LOOP AT a INTO DATA(lv_attr).

      DATA(lv_off) = find( val = lv_attr
                           sub = `=` ).
      " no `=` at all is a malformed attribute, `=value` a nameless one and
      " `key=` an unset one - all three would end up as an empty attribute
      " name or value in the rendered XML
      IF lv_off < 1 OR strlen( lv_attr ) <= lv_off + 1.
        CONTINUE.
      ENDIF.

      " a( ) lands on the element the chain points at - the tag just added
      result->a( n = substring( val = lv_attr
                                len = lv_off )
                 v = substring( val = lv_attr
                                off = lv_off + 1 ) ).

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
