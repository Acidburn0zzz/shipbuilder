#!/usr/bin/env bash

cd "$(dirname "$0")"

source libfns.sh

while getopts “H:S:c:h” OPTION; do
    case $OPTION in
        h)
            echo "usage: $0 -H [load-balancer-host] -S [shipbuilder-host] [ACTION]" 1>&2
            echo '' 1>&2
            echo 'This is the load-balancer installer.' 1>&2
            echo '' 1>&2
            echo '  ACTION                  Action to perform. Available actions are: install'
            echo '  -H [load-balancer-host] Load-balancer hostname' 1>&2
            echo '  -S [shipbuilder-host]   ShipBuilder server hostname' 1>&2
            exit 1
            ;;
        H)
            lbHost=$OPTARG
            ;;
        S)
            sbHost=$OPTARG
            ;;
        c)
            certFile=$OPTARG
            ;;
    esac
done

# Clear options from $n.
shift $(($OPTIND - 1))

action=$1

test -z "${sbHost}" && autoDetectServer

# Validate required parameters.
test -z "${sbHost}" && echo 'error: missing required parameter: -S [shipbuilder-host]' 1>&2 && exit 1
test -z "${lbHost}" && echo 'error: missing required parameter: -H [load-balancer-host]' 1>&2 && exit 1
test -z "${action}" && echo 'error: missing required parameter: action' 1>&2 && exit 1

test -n "${certFile}" && test ! -r "${certFile}" && echo "error: unable to read ssl certificate file (may not exist): ${certFile}" 1>&2 && exit 1
test -z "${certFile}" && echo "warn: no ssl certificate file specified, ssl support will not be available (specify with '-c [path-to-ssl-cert]'" 1>&2
    

verifySshAndSudoForHosts "${sbHost} ${lbHost}"


if [ "${action}" = "install" ]; then
    installAccessForSshHost $lbHost
    
    rsync -azve "ssh -o 'BatchMode yes' -o 'StrictHostKeyChecking no'" libfns.sh $certFile $lbHost:/tmp/
    ssh -o 'BatchMode yes' -o 'StrictHostKeyChecking no' $lbHost "source /tmp/libfns.sh && prepareLoadBalancer $(basename "${certFile}")"

else
	echo 'unrecognized action: ${action}' 1>&2 && exit 1
fi


