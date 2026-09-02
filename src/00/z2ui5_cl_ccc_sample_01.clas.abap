"! <p class="shorttext synchronized" lang="en">abap2UI5 customer frontend extension - icon gallery</p>
"!
"! Start with: <em>?app_start=z2ui5_cl_ccc_sample_01</em>
"!
"! Every icon this repository's font ships, with the name and the URI to
"! address it by. It is the check app for the icon font the way
"! <em>z2ui5_cl_ccc_sample_00</em> is the check app for the BSP itself: if the
"! glyphs are drawn, the font travelled into the browser, the IconPool
"! resolved the collection, and nothing was requested over the network to do
"! either.
"!
"! A list of names with EMPTY icons next to them is the interesting failure -
"! it means the collection is not registered (no
"! <em>z2ui5_cl_ccc=&gt;render( )</em> in the view, or the BSP is not
"! deployed), because an unresolved sap-icon:// URI draws nothing and logs
"! nothing.
CLASS z2ui5_cl_ccc_sample_01 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      "! one row of the gallery - what the font calls the glyph, and the URI
      "! a view puts into an icon property
      BEGIN OF ty_s_icon,
        name TYPE string,
        uri  TYPE string,
      END OF ty_s_icon.
    TYPES ty_t_icon TYPE STANDARD TABLE OF ty_s_icon WITH EMPTY KEY.

    " ONLY bound data here - PUBLIC attributes are serialized every roundtrip
    DATA t_icon TYPE ty_t_icon.

  PROTECTED SECTION.
    TYPES ty_t_uri TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.

    "! The gallery content, built from the generated icon interface rather
    "! than from literals - a glyph dropped from the font takes its constant
    "! with it, so this method stops compiling instead of rendering a blank.
    METHODS icons
      RETURNING
        VALUE(result) TYPE ty_t_icon.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_ccc_sample_01 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_init( ).
      t_icon = icons( ).
      view_display( ).
    ENDIF.

  ENDMETHOD.

  METHOD icons.

    DATA(lt_uri) = VALUE ty_t_uri(
        ( z2ui5_if_ccc_icon=>bestandsinfohu )
        ( z2ui5_if_ccc_icon=>bestandsinfolager )
        ( z2ui5_if_ccc_icon=>bestandsinfomat )
        ( z2ui5_if_ccc_icon=>bestandsinfomat1 )
        ( z2ui5_if_ccc_icon=>bewegungabgeschlossen )
        ( z2ui5_if_ccc_icon=>bewegungabgeschlossen1 )
        ( z2ui5_if_ccc_icon=>fordertechnikaufladen )
        ( z2ui5_if_ccc_icon=>fordertechnikentnehmen )
        ( z2ui5_if_ccc_icon=>kommisionierhubeladen )
        ( z2ui5_if_ccc_icon=>kommisionierhuentnehmen )
        ( z2ui5_if_ccc_icon=>lageraufgabequitiert )
        ( z2ui5_if_ccc_icon=>lageraufgabequitiert1 )
        ( z2ui5_if_ccc_icon=>lagerauslagern )
        ( z2ui5_if_ccc_icon=>lagereinlagern )
        ( z2ui5_if_ccc_icon=>lkwausladen )
        ( z2ui5_if_ccc_icon=>lkwbeladen )
        ( z2ui5_if_ccc_icon=>regal )
        ( z2ui5_if_ccc_icon=>regal2 )
        ( z2ui5_if_ccc_icon=>regal3 )
        ( z2ui5_if_ccc_icon=>regal4 )
        ( z2ui5_if_ccc_icon=>regal5 )
        ( z2ui5_if_ccc_icon=>stapler )
        ( z2ui5_if_ccc_icon=>staplereinlagern )
        ( z2ui5_if_ccc_icon=>staplerentnehmen )
        ( z2ui5_if_ccc_icon=>staplerinfo )
        ( z2ui5_if_ccc_icon=>staplerlogin )
        ( z2ui5_if_ccc_icon=>staplerlogout )
        ( z2ui5_if_ccc_icon=>staplerlogout1 )
        ( z2ui5_if_ccc_icon=>umpacken )
        ( z2ui5_if_ccc_icon=>umpacken1 ) ).

    LOOP AT lt_uri INTO DATA(lv_uri).
      APPEND VALUE #( uri  = lv_uri
                      name = substring_after( val = lv_uri
                                              sub = z2ui5_if_ccc_icon=>c_uri_prefix ) ) TO result.
    ENDLOOP.

  ENDMETHOD.

  METHOD view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).

    DATA(root) = view->ele( n  = `View`
                            ns = `mvc`
        )->a( n = `xmlns`
              v = `sap.m`
        )->a( n = `xmlns:mvc`
              v = `sap.ui.core.mvc`
        )->a( n = `displayBlock`
              v = `true`
        )->a( n = `height`
              v = `100%` ).

    " declares xmlns:z2ui5_ccc="z2ui5_ccc.cc" - once per view, on the root
    z2ui5_cl_ccc=>xmlns( root ).

    DATA(page) = root->ele( `Page`
        )->a( n = `title`
              v = `abap2UI5 customer frontend extension - icons` ).

    page->ele( `MessageStrip`
        )->a( n = `text`
              v = |{ lines( t_icon ) } icons, drawn from the font embedded in | &&
                  |z2ui5_ccc/fonts/MyCustomFontFamily.js. Address them with | &&
                  |the URI shown, or with the constant of the same name in | &&
                  |z2ui5_if_ccc_icon.|
        )->a( n = `type`
              v = `Information`
        )->a( n = `showIcon`
              v = `true`
        )->a( n = `class`
              v = `sapUiSmallMargin`
    )->end( ).

    " The bootstrap element: without it the URIs below resolve to nothing and
    " every row renders with an empty icon.
    z2ui5_cl_ccc=>render( page ).

    page->ele( `List`
        )->a( n = `items`
              v = client->_bind( t_icon )
        )->a( n = `headerText`
              v = z2ui5_if_ccc_icon=>c_collection

        )->ele( `items`
            )->tag( `StandardListItem`
                )->a( n = `icon`
                      v = `{URI}`
                )->a( n = `title`
                      v = `{NAME}`
                )->a( n = `description`
                      v = `{URI}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
