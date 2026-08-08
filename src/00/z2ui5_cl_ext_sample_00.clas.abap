"! <p class="shorttext synchronized" lang="en">abap2UI5 customer frontend extension - check</p>
"!
"! Start with: <em>?app_start=z2ui5_cl_ext_sample_00</em>
"!
"! Installation check of this repository. If the badge renders, is styled and
"! reacts to a click, then the Z2UI5EXT BSP is deployed, the abap2UI5 frontend
"! resolves the reserved resourceRoot <em>z2ui5ext</em>, and both the control
"! and the stylesheet are being served from here. Nothing in abap2UI5 or in its
"! frontend BSP was touched to make that work.
"!
"! Keep it as a smoke test after every deployment of this repository.
CLASS z2ui5_cl_ext_sample_00 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " ONLY bound data here - PUBLIC attributes are serialized every roundtrip
    DATA text  TYPE string.
    DATA color TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_ext_sample_00 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_init( ).
      text  = `Extension loaded`.
      color = `#0a6ed1`.
      view_display( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ENDIF.

  ENDMETHOD.

  METHOD view_display.

    DATA(view) = z2ui5_cl_ai_xml=>factory( ).

    DATA(root) = view->open( n  = `View`
                             ns = `mvc`
        )->a( n = `xmlns`
              v = `sap.m`
        )->a( n = `xmlns:mvc`
              v = `sap.ui.core.mvc`
        )->a( n = `displayBlock`
              v = `true`
        )->a( n = `height`
              v = `100%` ).

    " declares xmlns:z2ui5ext="z2ui5ext.cc" - once per view, on the root
    z2ui5_cl_ext=>xmlns( root ).

    DATA(page) = root->open( `Page`
        )->a( n = `title`
              v = `abap2UI5 customer frontend extension` ).

    page->open( `MessageStrip`
        )->a( n = `text`
              v = `Everything below is served by the Z2UI5EXT BSP of this ` &&
                  `repository, not by abap2UI5 or its frontend BSP.`
        )->a( n = `type`
              v = `Information`
        )->a( n = `showIcon`
              v = `true`
        )->a( n = `class`
              v = `sapUiSmallMargin`
    )->shut( ).

    " The bootstrap element: registers the resource roots, libraries, icon
    " fonts and stylesheets declared in app/webapp/cc/Extension.js. Add it
    " before the controls that depend on any of them.
    z2ui5_cl_ext=>render( page ).

    DATA(box) = page->open( `VBox`
        )->a( n = `class`
              v = `sapUiMediumMargin` ).

    box->leaf( `Label`
        )->a( n = `text`
              v = `Badge text`
        )->a( n = `labelFor`
              v = `TEXT` ).

    " No event on purpose: the input and the badge below are bound to the SAME
    " model path, so typing updates the badge in the browser without a
    " roundtrip. That the badge follows along is itself part of the check -
    " it proves the control is a real UI5 control with working data binding,
    " not a static snippet.
    box->leaf( `Input`
        )->a( n = `id`
              v = `TEXT`
        )->a( n = `value`
              v = client->_bind( text )
        )->a( n = `width`
              v = `20rem` ).

    " the control this repository ships - z2ui5ext/cc/Example.js
    z2ui5_cl_ext=>example( view  = box
                           text  = client->_bind( text )
                           color = client->_bind( color )
                           press = client->_event( `PRESS` ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

  METHOD on_event.

    CASE client->get( )-event.
      WHEN `PRESS`.
        " the text arrived with the roundtrip through the two-way binding -
        " echoing it back proves the event carries the edited model, not the
        " state the view was rendered with
        client->message_toast_display( |Badge pressed: { text }| ).
    ENDCASE.

  ENDMETHOD.

ENDCLASS.
