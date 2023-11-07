class ZMDG_CL_CREATE_CREQUEST definition
  public
  final
  create public .

public section.

  class-data GO_MDG_CONV type ref to IF_USMD_CONV_SOM_GOV_API .

  class-methods CREATE_CHANGE_REQUEST
    importing
      !IV_CR_TYPE type USMD_CREQUEST_TYPE
      !IV_DATA_MODEL type USMD_MODEL
      !IS_BP_CENTRL type /MDGBP/_S_BP_PP_BP_CENTRL
      !IS_BP_HEADER type /MDGBP/_S_BP_PP_BP_HEADER
      !IS_AD_POSTAL type /MDGBP/_S_BP_PP_AD_POSTAL
      !IV_CR_DESC type USMD_TXTLG
    exporting
      !ET_MESSAGE type USMD_T_MESSAGE
      !EV_CR_ID type USMD_CREQUEST .
protected section.
private section.
ENDCLASS.



CLASS ZMDG_CL_CREATE_CREQUEST IMPLEMENTATION.


  METHOD create_change_request.
    DATA: lt_entity_data      TYPE usmd_gov_api_ts_ent_data,
          ls_entity_data      LIKE LINE OF lt_entity_data,
          lt_entity_keys      TYPE usmd_gov_api_ts_ent_tabl,
          lt_entity_keys_lock TYPE usmd_gov_api_ts_ent_tabl,
          ls_entity_keys      LIKE LINE OF lt_entity_keys,
          ls_crequest_data    TYPE usmd_s_crequest,
          lv_temp_key_bp_addr TYPE string,
          lv_temp_key_bp      TYPE string.


** Creating Instance of Conveniance API
    IF go_mdg_conv IS NOT BOUND.
      TRY .
          go_mdg_conv = cl_usmd_conv_som_gov_api=>get_instance(
          iv_model_name = 'BP'
          ).
        CATCH cx_usmd_conv_som_gov_api INTO DATA(lo_som_gov_api_error).  "
          et_message = lo_som_gov_api_error->mt_messages.
        CATCH cx_usmd_app_context_cons_error INTO DATA(lo_cons_error).  "
          DATA(ls_message) = lo_cons_error->e_message.
          APPEND ls_message TO et_message.
        CATCH cx_usmd_gov_api INTO DATA(lo_gov_api_error).  "
          et_message = lo_gov_api_error->mt_messages.
      ENDTRY.

** Creating new Change Request
      TRY.
          go_mdg_conv->set_environment(
          EXPORTING
          iv_crequest_type   = iv_cr_type "'CUST1P2'
          iv_create_crequest = abap_true
          ).
        CATCH cx_usmd_conv_som_gov_api INTO lo_som_gov_api_error.  "
          et_message = lo_som_gov_api_error->mt_messages.
          RETURN.
      ENDTRY.
      ev_cr_id = go_mdg_conv->get_crequest_id( ).

** Update CR with Description
      TRY.
          ls_crequest_data-usmd_crequest    = ev_cr_id.
          ls_crequest_data-usmd_creq_type   = iv_cr_type.     "'CUST1P2'.
          ls_crequest_data-usmd_creq_text   = iv_cr_desc.     "'Description for Change Request
          ls_crequest_data-usmd_creq_status = '01'.           " IM_CHANGREQ_STAT

          go_mdg_conv->write_crequest( is_crequest_data =  ls_crequest_data ).

        CATCH cx_usmd_gov_api_core_error INTO DATA(lo_core_error).
          et_message = lo_core_error->mt_messages.
        CATCH cx_usmd_gov_api INTO lo_gov_api_error.  "
          et_message = lo_gov_api_error->mt_messages.
      ENDTRY.

*** Create Temperory key's for Address ID and Business Partner ID
      TRY.
          go_mdg_conv->create_entity_tmp_key(
                       EXPORTING
                         iv_entity = 'ADDRNO'
                       IMPORTING
                         es_key    = lv_temp_key_bp_addr
                          ).
        CATCH cx_usmd_conv_som_gov_api INTO lo_som_gov_api_error.  "
          et_message = lo_som_gov_api_error->mt_messages.
        CATCH cx_usmd_gov_api INTO lo_gov_api_error.  "
          et_message = lo_gov_api_error->mt_messages.
      ENDTRY.

      TRY.
          go_mdg_conv->create_entity_tmp_key(
                        EXPORTING
                          iv_entity =  'BP_HEADER'
                        IMPORTING
                          es_key    =  lv_temp_key_bp
                           ).

        CATCH cx_usmd_conv_som_gov_api INTO lo_som_gov_api_error.
          et_message = lo_som_gov_api_error->mt_messages.

        CATCH cx_usmd_gov_api INTO lo_gov_api_error.
          et_message = lo_gov_api_error->mt_messages.
      ENDTRY.

    ENDIF.

** Getting GUIID for Business Partner
    TRY.
        DATA(lv_uuid_16) = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error INTO DATA(lo_error).
        CLEAR lv_uuid_16.
    ENDTRY.

** Setting BP Header values

    TRY .
        go_mdg_conv->get_entity_structure(
        EXPORTING
        iv_entity_name = 'BP_HEADER'
        iv_struct_type = go_mdg_conv->gc_struct_key_attr
        IMPORTING
        er_structure   = DATA(ls_entity)
        er_table       = DATA(lt_entity)
        ).

      CATCH cx_usmd_gov_api INTO lo_gov_api_error.  "
        et_message = lo_gov_api_error->mt_messages.
    ENDTRY.

    ASSIGN ls_entity->* TO FIELD-SYMBOL(<ls_bp_header>).
    ASSIGN lt_entity->* TO FIELD-SYMBOL(<lt_bp_header>).

    ASSIGN COMPONENT 'BP_HEADER' OF STRUCTURE <ls_bp_header> TO FIELD-SYMBOL(<lv_value>).
    IF <lv_value> IS ASSIGNED.
      <lv_value> = lv_temp_key_bp.
    ENDIF.

    ASSIGN COMPONENT 'BP_GUID' OF STRUCTURE <ls_bp_header> TO <lv_value>.
    IF <lv_value> IS ASSIGNED.
      <lv_value> = lv_uuid_16.
    ENDIF.

    ASSIGN COMPONENT 'BU_GROUP' OF STRUCTURE <ls_bp_header> TO <lv_value>.
    IF <lv_value> IS ASSIGNED.
      <lv_value> = is_bp_header-bu_group.
    ENDIF.

    ASSIGN COMPONENT 'BU_TYPE' OF STRUCTURE <ls_bp_header> TO <lv_value>.
    IF <lv_value> IS ASSIGNED.
      <lv_value> = is_bp_header-bu_type.
    ENDIF.

    INSERT <ls_bp_header> INTO TABLE <lt_bp_header>.

    ls_entity_keys-entity = 'BP_HEADER'.
    ls_entity_keys-tabl = lt_entity.

    INSERT ls_entity_keys INTO TABLE lt_entity_keys.
    INSERT ls_entity_keys INTO TABLE lt_entity_keys_lock.

    DATA(lt_header_key) = lt_entity_keys_lock.
    CLEAR ls_entity_data.

    ls_entity_data-entity = 'BP_HEADER'.
    ls_entity_data-entity_data = lt_entity.

    INSERT ls_entity_data INTO TABLE lt_entity_data.

*** ADDRNO

    TRY .
        go_mdg_conv->get_entity_structure(
                     EXPORTING
                       iv_entity_name = 'ADDRNO'
                       iv_struct_type = go_mdg_conv->gc_struct_key_attr
                     IMPORTING
                       er_structure   = ls_entity
                       er_table       = lt_entity
                        ).

      CATCH cx_usmd_gov_api INTO lo_gov_api_error.  "
        et_message = lo_gov_api_error->mt_messages.

    ENDTRY.

    ASSIGN ls_entity->* TO FIELD-SYMBOL(<ls_addrno>).
    ASSIGN lt_entity->* TO FIELD-SYMBOL(<lt_addrno>).

    ASSIGN COMPONENT 'ADDRNO' OF STRUCTURE <ls_addrno> TO <lv_value>.
    IF <lv_value> IS ASSIGNED.
      <lv_value> = lv_temp_key_bp_addr.
    ENDIF.

    INSERT <ls_addrno> INTO TABLE <lt_addrno>.

    CLEAR ls_entity_data.
    ls_entity_data-entity = 'ADDRNO'.
    ls_entity_data-entity_data = lt_entity.
    INSERT ls_entity_data INTO TABLE lt_entity_data.

    CLEAR: ls_entity_keys.
    ls_entity_keys-entity = 'ADDRNO'.
    ls_entity_keys-tabl = lt_entity.

    INSERT ls_entity_keys INTO TABLE lt_entity_keys.
    INSERT ls_entity_keys INTO TABLE lt_entity_keys_lock.

    TRY.
        go_mdg_conv->enqueue_entity(
                      EXPORTING
                       it_entity_keys = lt_entity_keys_lock ).
      CATCH cx_usmd_conv_som_gov_api INTO lo_som_gov_api_error.  "
        et_message = lo_som_gov_api_error->mt_messages.
      CATCH cx_usmd_gov_api INTO lo_gov_api_error.  "
        et_message = lo_gov_api_error->mt_messages.
    ENDTRY.

    TRY.
        go_mdg_conv->write_entity_data( it_entity_data = lt_entity_data ).
        CLEAR lt_entity_data.
      CATCH cx_usmd_gov_api_core_error INTO DATA(go_core_error).
        et_message = go_core_error->mt_messages.
      CATCH cx_usmd_gov_api_entity_write INTO DATA(lo_ent_error).
        et_message = lo_ent_error->mt_messages.
      CATCH cx_usmd_gov_api INTO lo_gov_api_error.  "
        et_message = lo_gov_api_error->mt_messages.    "
    ENDTRY.

** ADDRESS

    TRY .
        go_mdg_conv->get_entity_structure(
                     EXPORTING
                       iv_entity_name = 'ADDRESS'
                       iv_struct_type = go_mdg_conv->gc_struct_key_attr
                     IMPORTING
                       er_structure   = ls_entity
                       er_table       = lt_entity
                            ).

      CATCH cx_usmd_gov_api INTO lo_gov_api_error.  "
        et_message = lo_gov_api_error->mt_messages.
    ENDTRY.

    ASSIGN ls_entity->* TO FIELD-SYMBOL(<ls_address>).
    ASSIGN lt_entity->* TO FIELD-SYMBOL(<lt_address>).

    ASSIGN COMPONENT 'ADDRNO' OF STRUCTURE <ls_address> TO <lv_value>.
    IF <lv_value> IS ASSIGNED.
      <lv_value> = lv_temp_key_bp_addr.
    ENDIF.

    ASSIGN COMPONENT 'BP_HEADER' OF STRUCTURE <ls_address> TO <lv_value>.
    IF <lv_value> IS ASSIGNED.
      <lv_value> = lv_temp_key_bp.
    ENDIF.

    ASSIGN COMPONENT 'TYPE' OF STRUCTURE <ls_address> TO <lv_value>.
    IF <lv_value> IS ASSIGNED.
      <lv_value> = 1.
    ENDIF.

    INSERT <ls_address> INTO TABLE <lt_address>.
    CLEAR ls_entity_data.
    ls_entity_data-entity = 'ADDRESS'.
    ls_entity_data-entity_data = lt_entity.

    INSERT ls_entity_data INTO TABLE lt_entity_data.

    CLEAR ls_entity_keys.
    ls_entity_keys-entity = 'ADDRESS'.
    ls_entity_keys-tabl = lt_entity.
    INSERT ls_entity_keys INTO TABLE lt_entity_keys.

** BP_CENTRL **
    TRY .
        go_mdg_conv->get_entity_structure(
                     EXPORTING
                       iv_entity_name = 'BP_CENTRL'
                       iv_struct_type = go_mdg_conv->gc_struct_key_attr
                     IMPORTING
                       er_structure   = ls_entity
                       er_table       = lt_entity
                          ).

      CATCH cx_usmd_gov_api INTO lo_gov_api_error.
        et_message = lo_gov_api_error->mt_messages.
    ENDTRY.

    ASSIGN ls_entity->* TO FIELD-SYMBOL(<ls_bp_centrl>).
    ASSIGN lt_entity->* TO FIELD-SYMBOL(<lt_centrl>).

    ASSIGN COMPONENT 'BP_HEADER' OF STRUCTURE <ls_bp_centrl> TO <lv_value>.
    IF <lv_value> IS ASSIGNED.
      <lv_value> = lv_temp_key_bp.
    ENDIF.

    ASSIGN COMPONENT 'NAME_ORG1' OF STRUCTURE <ls_bp_centrl> TO <lv_value>.
    IF <lv_value> IS ASSIGNED.
      <lv_value> = is_bp_centrl-name_org1.
    ENDIF.

    ASSIGN COMPONENT 'NAME_ORG2' OF STRUCTURE <ls_bp_centrl> TO <lv_value>.
    IF <lv_value> IS ASSIGNED.
      <lv_value> = is_bp_centrl-name_org2.
    ENDIF.

    ASSIGN COMPONENT 'BU_SORT1' OF STRUCTURE <ls_bp_centrl> TO <lv_value>.
    IF <lv_value> IS ASSIGNED.
      <lv_value> = is_bp_centrl-bu_sort1.
    ENDIF.

    INSERT <ls_bp_centrl> INTO TABLE <lt_centrl>.
    CLEAR ls_entity_data.

    ls_entity_data-entity = 'BP_CENTRL'.
    ls_entity_data-entity_data = lt_entity.
    INSERT ls_entity_data INTO TABLE lt_entity_data.

    CLEAR ls_entity_keys.
    ls_entity_keys-entity = 'BP_CENTRL'.
    ls_entity_keys-tabl = lt_entity.

    INSERT ls_entity_keys INTO TABLE lt_entity_keys.

    TRY.
        go_mdg_conv->enqueue_entity(
                       EXPORTING
                        it_entity_keys = lt_header_key ).

      CATCH cx_usmd_conv_som_gov_api INTO lo_som_gov_api_error.
        et_message = lo_som_gov_api_error->mt_messages.
      CATCH cx_usmd_gov_api INTO lo_gov_api_error.
        et_message = lo_gov_api_error->mt_messages.
    ENDTRY.

** BP_ADDR

    CLEAR: ls_entity, lt_entity.
    TRY .
        go_mdg_conv->get_entity_structure(
                     EXPORTING
                       iv_entity_name = 'BP_ADDR'
                       iv_struct_type = go_mdg_conv->gc_struct_key_attr
                     IMPORTING
                       er_structure   = ls_entity
                       er_table       = lt_entity
                         ).

      CATCH cx_usmd_gov_api INTO lo_gov_api_error.  "
        et_message = lo_gov_api_error->mt_messages.
    ENDTRY.

    ASSIGN ls_entity->* TO FIELD-SYMBOL(<ls_bp_addr>).
    ASSIGN lt_entity->* TO FIELD-SYMBOL(<lt_bp_addr>).

    ASSIGN COMPONENT 'ADDRNO' OF STRUCTURE <ls_bp_addr> TO <lv_value>.
    IF <lv_value> IS ASSIGNED.
      <lv_value> = lv_temp_key_bp_addr.
    ENDIF.

    ASSIGN COMPONENT 'BP_HEADER' OF STRUCTURE <ls_bp_addr> TO <lv_value>.
    IF <lv_value> IS ASSIGNED.
      <lv_value> = lv_temp_key_bp.
    ENDIF.

    INSERT <ls_bp_addr> INTO TABLE <lt_bp_addr>.

    CLEAR ls_entity_data.

    ls_entity_data-entity = 'BP_ADDR'.
    ls_entity_data-entity_data = lt_entity.

    INSERT ls_entity_data INTO TABLE lt_entity_data.
    CLEAR ls_entity_keys.

    ls_entity_keys-entity = 'BP_ADDR'.
    ls_entity_keys-tabl = lt_entity.

    INSERT ls_entity_keys INTO TABLE lt_entity_keys.

** AD_POSTAL

    TRY .
        go_mdg_conv->get_entity_structure(
                      EXPORTING
                         iv_entity_name = 'AD_POSTAL'
                         iv_struct_type = go_mdg_conv->gc_struct_key_attr
                      IMPORTING
                         er_structure   = ls_entity
                         er_table       = lt_entity
                         ).
      CATCH cx_usmd_gov_api INTO lo_gov_api_error.  "
        et_message = lo_gov_api_error->mt_messages.
    ENDTRY.

    ASSIGN ls_entity->* TO FIELD-SYMBOL(<ls_ad_postal>).
    ASSIGN lt_entity->* TO FIELD-SYMBOL(<lt_ad_postal>).

    ASSIGN COMPONENT 'ADDRNO' OF STRUCTURE <ls_ad_postal> TO <lv_value>.

    IF sy-subrc EQ 0.
      <lv_value> = lv_temp_key_bp_addr.
    ENDIF.
    ASSIGN COMPONENT 'BP_HEADER' OF STRUCTURE <ls_ad_postal> TO <lv_value>.
    IF sy-subrc EQ 0.
      <lv_value> = lv_temp_key_bp.
    ENDIF.
    ASSIGN COMPONENT 'STREET' OF STRUCTURE <ls_ad_postal> TO <lv_value>.
    IF <lv_value> IS ASSIGNED.
      <lv_value> = is_ad_postal-street.
    ENDIF.

    ASSIGN COMPONENT 'CITY1' OF STRUCTURE <ls_ad_postal> TO <lv_value>.
    IF <lv_value> IS ASSIGNED.
      <lv_value> = is_ad_postal-city1.
    ENDIF.

    ASSIGN COMPONENT 'REF_POSTA' OF STRUCTURE <ls_ad_postal> TO <lv_value>.
    IF <lv_value> IS ASSIGNED.
      <lv_value> = is_ad_postal-ref_posta.
    ENDIF.

    ASSIGN COMPONENT 'LANGU_COM' OF STRUCTURE <ls_ad_postal> TO <lv_value>.
    IF <lv_value> IS ASSIGNED.
      <lv_value> = is_ad_postal-langu_com.
    ENDIF.

    ASSIGN COMPONENT 'POST_COD1' OF STRUCTURE <ls_ad_postal> TO <lv_value>.
    IF <lv_value> IS ASSIGNED.
      <lv_value> = is_ad_postal-post_cod1.
    ENDIF.

    INSERT <ls_ad_postal> INTO TABLE <lt_ad_postal>.

    CLEAR ls_entity_data.
    ls_entity_data-entity = 'AD_POSTAL'.
    ls_entity_data-entity_data = lt_entity.
    INSERT ls_entity_data INTO TABLE lt_entity_data.

    CLEAR ls_entity_keys.
    ls_entity_keys-entity = 'AD_POSTAL'.
    ls_entity_keys-tabl = lt_entity.
    INSERT ls_entity_keys INTO TABLE lt_entity_keys.

**BP_ADUSTD
    TRY .
        go_mdg_conv->get_entity_structure(
                      EXPORTING
                        iv_entity_name = 'BP_ADUSTD'
                        iv_struct_type = go_mdg_conv->gc_struct_key_attr
                      IMPORTING
                        er_structure   = ls_entity
                        er_table       = lt_entity
                        ).
      CATCH cx_usmd_gov_api INTO lo_gov_api_error.  "
        et_message = lo_gov_api_error->mt_messages.

    ENDTRY.
    ASSIGN ls_entity->* TO FIELD-SYMBOL(<ls_bp_adustd>).
    ASSIGN lt_entity->* TO FIELD-SYMBOL(<lt_bp_adustd>).

    ASSIGN COMPONENT 'ADUS_VDTO' OF STRUCTURE <ls_bp_adustd> TO <lv_value>.
    IF <lv_value> IS ASSIGNED.
      <lv_value> = '99991231'.
    ENDIF.

    ASSIGN COMPONENT 'ADDRNO' OF STRUCTURE <ls_bp_adustd> TO <lv_value>.
    IF <lv_value> IS ASSIGNED.
      <lv_value> = lv_temp_key_bp_addr.
    ENDIF.

    ASSIGN COMPONENT 'BP_HEADER' OF STRUCTURE <ls_bp_adustd> TO <lv_value>.
    IF <lv_value> IS ASSIGNED.
      <lv_value> = lv_temp_key_bp.
    ENDIF.

    ASSIGN COMPONENT 'BP_ADRKND' OF STRUCTURE <ls_bp_adustd> TO <lv_value>.
    IF <lv_value> IS ASSIGNED.
      <lv_value> = 'XXDEFAULT'.
    ENDIF.

    ASSIGN COMPONENT 'ADUS_VDFR' OF STRUCTURE <ls_bp_adustd> TO <lv_value>.
    IF <lv_value> IS ASSIGNED.
      <lv_value> = sy-datum.
    ENDIF.

    INSERT <ls_bp_adustd> INTO TABLE <lt_bp_adustd>.
    CLEAR ls_entity_data.
    ls_entity_data-entity = 'BP_ADUSTD'.
    ls_entity_data-entity_data = lt_entity.

    INSERT ls_entity_data INTO TABLE lt_entity_data.
    CLEAR ls_entity_keys.
    ls_entity_keys-entity = 'BP_ADUSTD'.
    ls_entity_keys-tabl = lt_entity.
    INSERT ls_entity_keys INTO TABLE lt_entity_keys.

** enque
    TRY.
        go_mdg_conv->enqueue_entity(
        EXPORTING
        it_entity_keys = lt_header_key ).
      CATCH cx_usmd_conv_som_gov_api INTO lo_som_gov_api_error.  "
        et_message = lo_som_gov_api_error->mt_messages.
      CATCH cx_usmd_gov_api INTO lo_gov_api_error.  "
        et_message = lo_gov_api_error->mt_messages.
    ENDTRY.

    TRY.
        go_mdg_conv->write_entity_data( it_entity_data = lt_entity_data ).
        CLEAR lt_entity_data.
      CATCH cx_usmd_gov_api_core_error INTO go_core_error.
        et_message = go_core_error->mt_messages.
      CATCH cx_usmd_gov_api_entity_write INTO lo_ent_error.
        et_message = lo_ent_error->mt_messages.
      CATCH cx_usmd_gov_api INTO lo_gov_api_error.  "
        et_message = lo_gov_api_error->mt_messages.    "
    ENDTRY.

** save CR
    TRY.
        go_mdg_conv->save( ).
      CATCH cx_usmd_conv_som_gov_api INTO lo_som_gov_api_error.  "
        et_message = lo_som_gov_api_error->mt_messages.
      CATCH cx_usmd_app_context_cons_error INTO lo_cons_error.  "
        ls_message = lo_cons_error->e_message.
        APPEND ls_message TO et_message.
      CATCH cx_usmd_gov_api_core_error INTO go_core_error.
        et_message = go_core_error->mt_messages.
      CATCH cx_usmd_gov_api INTO lo_gov_api_error.  "
        et_message = lo_gov_api_error->mt_messages.
    ENDTRY.

    " DEQUE
    go_mdg_conv->dequeue_entity_all( ).

    COMMIT WORK AND WAIT.

    TRY.
        go_mdg_conv->set_action( iv_crequest_action = '00' ).
      CATCH cx_usmd_gov_api_core_error.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
