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

    "! Declare the extension's XML namespace on a view or fragment root.
    "!
    "! Call it once, on the root element, before adding any element of this
    "! extension:
    "!
    "!   DATA(view) = z2ui5_cl_ai_xml=>factory( ).
    "!   DATA(root) = view->open( n = `View` ns = `mvc`
    "!       )->a( n = `xmlns`     v = `sap.m`
    "!       )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc` ).
    "!   z2ui5_cl_ccc=>xmlns( root ).
    "!
    "! @parameter view   | the builder positioned at the root element
    "! @parameter result | the unchanged view builder, for chaining
    CLASS-METHODS xmlns
      IMPORTING
        view          TYPE REF TO z2ui5_cl_ai_xml
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ai_xml.

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
        view          TYPE REF TO z2ui5_cl_ai_xml
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ai_xml.

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
        view          TYPE REF TO z2ui5_cl_ai_xml
        text          TYPE string OPTIONAL
        color         TYPE string OPTIONAL
        press         TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ai_xml.

    "! Emit one element of this extension, skipping the attributes the caller
    "! left empty.
    "!
    "! Passing an EMPTY attribute is not the same as passing none: it would
    "! override the control's own defaultValue with an empty string. So the
    "! builders collect their parameters as `key=value` strings and let this
    "! method drop the ones whose value is initial.
    "!
    "! Mirrors z2ui5_cl_ai_xml=>leaf: the element is added as a child and the
    "! cursor stays on the current node, so the caller can keep chaining.
    "!
    "! @parameter view   | the builder positioned at the parent element
    "! @parameter name   | element name, without the namespace prefix
    "! @parameter a      | attributes as `key=value`; empty values are dropped
    "! @parameter result | the unchanged view builder, for chaining
    CLASS-METHODS leaf
      IMPORTING
        view          TYPE REF TO z2ui5_cl_ai_xml
        name          TYPE string
        a             TYPE z2ui5_cl_ai_xml=>ty_t_attr OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ai_xml.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_ccc IMPLEMENTATION.

  METHOD xmlns.

    result = view->a( n = |xmlns:{ c_ns }|
                      v = c_ns_uri ).

  ENDMETHOD.

  METHOD render.

    result = leaf( view = view
                   name = `Extension` ).

  ENDMETHOD.

  METHOD example.

    result = leaf( view = view
                   name = `Example`
                   a    = VALUE #( ( |text={ text }| )
                                   ( |color={ color }| )
                                   ( |press={ press }| ) ) ).

  ENDMETHOD.

  METHOD leaf.

    DATA lt_attr TYPE z2ui5_cl_ai_xml=>ty_t_attr.

    LOOP AT a INTO DATA(lv_attr).

      DATA(lv_off) = find( val = lv_attr
                           sub = `=` ).
      " no `=` at all is a malformed attribute, `key=` an unset one - both
      " would end up as an empty attribute value in the rendered XML
      IF lv_off < 0 OR strlen( lv_attr ) <= lv_off + 1.
        CONTINUE.
      ENDIF.

      APPEND lv_attr TO lt_attr.

    ENDLOOP.

    result = view->leaf( n  = name
                         ns = c_ns
                         a  = lt_attr ).

  ENDMETHOD.

ENDCLASS.
