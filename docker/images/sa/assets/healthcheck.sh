#!/bin/bash -e

checkReadiness=false

for i in "$@"; do
  case $i in
    --ready)
      checkReadiness=true
      shift
      ;;
    -*|--*)
      echo "Unknown option $i"
      exit 1
      ;;
    *)
      ;;
  esac
done

health=$(curl -fs 127.0.0.1:9990/health)
nodeStatus=$(jq -r '.checks[]|select(.name=="SA Health Check").data | ."node status"' <<< $health)
suspendState=$(jq -r '.checks[]|select(.name=="SA Health Check").data | ."suspend state" + ."internal suspend state"' <<< $health)

if [[ $nodeStatus != RUNNING ]]; then
    exit 1
fi

if [[ $checkReadiness == true && $suspendState != RESUMEDRESUMED ]]; then
    exit 1
fi

exit 0
