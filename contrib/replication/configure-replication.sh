#!/bin/bash
# $Id$

# Global defaults
CLUSTER=${CLUSTER:-"LedgerSMB"}
NUMNODES=${NUMNODES:-"2"}

# Defaults - origin node
DB1=${DB1:-${PGDATABASE:-"ledgersmb"}}
HOST1=${HOST1:-`hostname`}
USER1=${USER1:-${PGUSER:-"slony"}}
PORT1=${PORT1:-${PGPORT:-"5432"}}

# Defaults - node 2
DB2=${DB2:-${PGDATABASE:-"ledgersmb"}}
HOST2=${HOST2:-"backup.example.info"}
USER2=${USER2:-${PGUSER:-"slony"}}
PORT2=${PORT2:-${PGPORT:-"5432"}}

# Defaults - node 3
DB3=${DB3:-${PGDATABASE:-"ledgersmb"}}
HOST3=${HOST3:-"backup3.example.info"}
USER3=${USER3:-${PGUSER:-"slony"}}
PORT3=${PORT3:-${PGPORT:-"5432"}}

# Defaults - node 4
DB4=${DB4:-${PGDATABASE:-"ledgersmb"}}
HOST4=${HOST4:-"backup4.example.info"}
USER4=${USER4:-${PGUSER:-"slony"}}
PORT4=${PORT4:-${PGPORT:-"5432"}}

# Defaults - node 5
DB5=${DB5:-${PGDATABASE:-"ledgersmb"}}
HOST5=${HOST5:-"backup5.example.info"}
USER5=${USER5:-${PGUSER:-"slony"}}
PORT5=${PORT5:-${PGPORT:-"5432"}}

store_path()
{

echo "include <${PREAMBLE}>;" > $mktmp/store_paths.slonik
  i=1
  while : ; do
    eval db=\$DB${i}
    eval host=\$HOST${i}
    eval user=\$USER${i}
    eval port=\$PORT${i}

    if [ -n "${db}" -a "${host}" -a "${user}" -a "${port}" ]; then
      j=1
      while : ; do
        if [ ${i} -ne ${j} ]; then
          eval bdb=\$DB${j}
          eval bhost=\$HOST${j}
          eval buser=\$USER${j}
          eval bport=\$PORT${j}
          if [ -n "${bdb}" -a "${bhost}" -a "${buser}" -a "${bport}" ]; then
	    echo "STORE PATH (SERVER=${i}, CLIENT=${j}, CONNINFO='dbname=${db} host=${host} user=${user} port=${port}');" >> $mktmp/store_paths.slonik
          else
            err 3 "No conninfo"
          fi
        fi
        if [ ${j} -ge ${NUMNODES} ]; then
          break;
        else
          j=$((${j} + 1))
        fi
      done
      if [ ${i} -ge ${NUMNODES} ]; then
        break;
      else
        i=$((${i} +1))
      fi
    else
      err 3 "no DB"
    fi
  done
}

mktmp=`mktemp -d -t ledgersmb-temp.XXXXXX`
if [ $MY_MKTEMP_IS_DECREPIT ] ; then
       mktmp=`mktemp -d /tmp/ledgersmb-temp.XXXXXX`
fi

PREAMBLE=${mktmp}/preamble.slonik

echo "cluster name=${CLUSTER};" > $PREAMBLE

alias=1

while : ; do
  eval db=\$DB${alias}
  eval host=\$HOST${alias}
  eval user=\$USER${alias}
  eval port=\$PORT${alias}

  if [ -n "${db}" -a "${host}" -a "${user}" -a "${port}" ]; then
    conninfo="dbname=${db} host=${host} user=${user} port=${port}"
    echo "NODE ${alias} ADMIN CONNINFO = '${conninfo}';" >> $PREAMBLE
    if [ ${alias} -ge ${NUMNODES} ]; then
      break;
    else
      alias=`expr ${alias} + 1`
    fi   
  else
    break;
  fi
done


SEQUENCES=" asset_report_id_seq asset_dep_method_id_seq 
            asset_disposal_method_id_seq audittrail_entry_id_seq
            batch_class_id_seq budget_info_id_seq
            custom_field_catalog_field_id_seq asset_class_id_seq
            asset_item_id_seq contact_class_id_seq country_id_seq
            custom_table_catalog_table_id_seq entity_class_id_seq
            file_class_id_seq batch_id_seq department_id_seq new_shipto_id_seq
            entity_bank_account_id_seq location_class_id_seq note_class_id_seq
            menu_acl_id_seq menu_attribute_id_seq menu_node_id_seq
            mime_type_id_seq file_base_id_seq payment_type_id_seq 
            location_id_seq open_forms_id_seq partscustomer_entry_id_seq
            partsvendor_entry_id_seq payment_id_seq jcitems_id_seq
            pending_job_id_seq salutation_id_seq taxcategory_taxcategory_id_seq
            warehouse_id_seq acc_trans_entry_id_seq account_checkpoint_id_seq
            company_id_seq note_id_seq account_heading_id_seq id
            business_id_seq parts_id_seq oe_id_seq invoice_id_seq
            orderitems_id_seq country_tax_form_id_seq pricegroup_id_seq
            cr_report_line_id_seq session_session_id_seq inventory_entry_id_seq
            project_id_seq cr_report_id_seq entity_credit_account_id_seq 
            taxmodule_taxmodule_id_seq users_id_seq voucher_id_seq 
            person_id_seq entity_id_seq partsgroup_id_seq account_id_seq"

TABLES=" ac_tax_form acc_trans account account_checkpoint account_heading
         account_link account_link_description ap ar assembly asset_class
         asset_dep_method asset_disposal_method asset_item asset_note
         asset_report asset_report_class asset_report_line
         asset_rl_to_disposal_method asset_unit_class audittrail batch
         batch_class budget_info budget_line budget_note budget_to_department
         budget_to_project business company company_to_contact company_to_entity
         company_to_location contact_class country country_tax_form
         cr_coa_to_account cr_report cr_report_line custom_field_catalog
         custom_is custom_table_catalog customertax defaults department
         dpt_trans eca_note eca_to_contact eca_to_location entity
         entity_bank_account entity_class entity_class_to_entity
         entity_credit_account entity_employee entity_note entity_other_name
         exchangerate file_base file_class file_order file_order_to_order
         file_order_to_tx file_part file_secondary_attachment file_transaction
         file_tx_to_order file_view_catalog gifi gl inventory invoice
         invoice_note invoice_tax_form jcitems language location location_class
         makemodel menu_acl menu_attribute menu_node mime_type
         new_shipto note note_class oe oe_class open_forms orderitems parts
         parts_translation partscustomer partsgroup partsgroup_translation
         partstax partsvendor payment payment_links payment_type payments_queue
         pending_job person person_to_company person_to_contact person_to_entity
         person_to_location pricegroup project project_translation recurring
         recurringemail recurringprint salutation session sic status tax
         tax_extended taxcategory taxmodule transactions translation
         user_preference users vendortax voucher warehouse yearend"


SETUPSET=${mktmp}/create_set.slonik

echo "include <${PREAMBLE}>;" > $SETUPSET
echo "create set (id=1, origin=1, comment='${CLUSTER} Tables and Sequences');" >> $SETUPSET

tnum=1

for table in `echo $TABLES`; do
    echo "set add table (id=${tnum}, set id=1, origin=1, fully qualified name='public.${table}', comment='${CLUSTER} table ${table}');" >> $SETUPSET
    tnum=`expr ${tnum} + 1`
done

snum=1
for seq in `echo $SEQUENCES`; do
    echo "set add sequence (id=${snum}, set id=1, origin=1, fully qualified name='public.${seq}', comment='${CLUSTER} sequence ${seq}');" >> $SETUPSET
    snum=`expr ${snum} + 1`
done

NODEINIT=$mktmp/create_nodes.slonik
echo "include <${PREAMBLE}>;" > $NODEINIT
echo "init cluster (id=1, comment='${CLUSTER} node 1');" >> $NODEINIT

node=2
while : ; do
    SUBFILE=$mktmp/subscribe_set_${node}.slonik
    echo "include <${PREAMBLE}>;" > $SUBFILE
    echo "store node (id=${node}, comment='${CLUSTER} subscriber node ${node}');" >> $NODEINIT
    echo "subscribe set (id=1, provider=1, receiver=${node}, forward=yes);" >> $SUBFILE
    if [ ${node} -ge ${NUMNODES} ]; then
      break;
    else
      node=`expr ${node} + 1`
    fi   
done

store_path

echo "
$0 has generated Slony-I slonik scripts to initialize replication for LedgerSMB.

Cluster name: ${CLUSTER}
Number of nodes: ${NUMNODES}
Scripts are in ${mktmp}
=====================
"
ls -l $mktmp

echo "
=====================
Be sure to verify that the contents of $PREAMBLE very carefully, as
the configuration there is used widely in the other scripts.
=====================
====================="









