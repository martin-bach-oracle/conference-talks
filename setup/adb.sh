#!/usr/bin/env bash

#
# start/stop/create/drop an ADB instance named ittage
#

set -euxo pipefail

DISPLAYNAME=ittage
ME=$(curl https://ifconfig.me)

function usage {
set +x
    cat <<EOF
usage: ${0} <start|stop|status|create|drop|wallet>

Requires the OCI CLI to be in the path and the COMPARTMENT_OCID
to be exported.

Pull the wallet into the cwd by calling the script with the wallet option
EOF
}

# safety test
which oci 2>&1 > /dev/null || {
    echo ERR: ensure the OCI CLI has been added to the path
    exit 1
}

[[ -z ${COMPARTMENT_OCID} ]] && {
    echo "ERR: ensure the target COMPARTMENT_OCID has been exported"
    exit 1
}

[[ -z ${ADMIN_PWD} ]] && {
    echo "ERR: ensure the database's ADMIN password has been exported"
    exit 1
}

data=$(oci db autonomous-database list \
        -c ${COMPARTMENT_OCID} \
        --query "data[?\"display-name\" == '"${DISPLAYNAME}"'].{id:id,state:\"lifecycle-state\"} | [0]" --raw-output)

status=$(echo ${data} | jq -r .state)
ocid=$(echo ${data} | jq -r .id)

case ${1:-status} in

    status)
        oci db autonomous-database list \
        -c ${COMPARTMENT_OCID} \
        --query "data \
            [?contains(\"display-name\", '${DISPLAYNAME}')]  \
            .{id:id,\"display-name\":\"display-name\",\"lifecycle-state\":\"lifecycle-state\"}" \
        --output table
        ;;

    start)
        if [[ "${status}" != AVAILABLE ]]; then 
            oci db autonomous-database start --autonomous-database-id ${ocid}
        else
            [[ -z ${ocid} ]] && {
                echo ERR: cannot start the database, create it first
                exit 1
            } || {
                echo ERR: database already started
                exit 1
            }
        fi
        ;;

    stop)
        if [[ "${status}" == AVAILABLE ]]; then 
            oci db autonomous-database stop --autonomous-database-id ${ocid}
        else
            echo "INFO: the database is already stopped or hasn't yet been created"
        fi
        ;;

    create)
        oci db autonomous-database create \
        --compartment-id ${COMPARTMENT_OCID} \
        --db-name ${DISPLAYNAME} \
        --compute-model ECPU \
        --compute-count 4 \
        --admin-password ${ADMIN_PWD} \
        --data-storage-size-in-gbs 100 \
        --database-edition ENTERPRISE_EDITION \
        --display-name ${DISPLAYNAME} \
        --db-workload OLTP \
        --db-version 26ai \
        --license-model BRING_YOUR_OWN_LICENSE \
        --is-dedicated false \
        --whitelisted-ips '["'${ME}'"]'
        ;;
    drop)
        echo dropping the database

        [[ -z "${ocid}" ]] && {
            echo ERR: cannot drop a non existing database
            exit 1
        }
        
        oci db autonomous-database delete --autonomous-database-id "${ocid}"
        ;;
    wallet)
        [[ -z "${ocid}" ]] && {
            echo ERR: cannot get the wallet of an non-existing database.
            exit 1
        }

        oci db autonomous-database generate-wallet \
        --autonomous-database-id "${ocid}" \
        --password "${ADMIN_PWD}" \
        --file "./Wallet_${DISPLAYNAME}.zip"
        ;;
    *)
        usage
        ;;
esac