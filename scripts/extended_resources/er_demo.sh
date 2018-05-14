#!/bin/sh

# extended resources demo script
oc login --username=admin --password=XYZ > /dev/null
TOKEN=$(oc whoami -t)
MASTER=master.hostname 
NODE=node.hostname

if [ -z $1 ]
  then 
    echo "syntax $0 add-er|remove-er|get-er|create-pod|delete-pod|create-pod"
    exit 1
fi

if [ "$1" == "add-er" ]
  then
    echo "adding 42 dongles to $NODE"
    curl -s -k --header "Authorization: Bearer $TOKEN" --header "Content-Type: application/json-patch+json" --request PATCH --data '[{"op": "add", "path": "/status/capacity/example.com~1dongle", "value": "42"}]' https://$MASTER:8443/api/v1/nodes/$NODE/status > /dev/null
    curl -s -k --header "Authorization: Bearer $TOKEN" --header "Content-Type: application/json-patch+json" --request PATCH --data '[{"op": "add", "path": "/status/allocatable/example.com~1dongle", "value": "42"}]' https://$MASTER:8443/api/v1/nodes/$NODE/status > /dev/null
  elif [ "$1" == "remove-er" ]
  then
    echo "removing 42 dongles from $NODE"
    curl -s -k --header "Authorization: Bearer $TOKEN" --header "Content-Type: application/json-patch+json" --request PATCH --data '[{"op": "remove", "path": "/status/capacity/example.com~1dongle"}]' https://$MASTER:8443/api/v1/nodes/$NODE/status > /dev/null
    curl -s -k --header "Authorization: Bearer $TOKEN" --header "Content-Type: application/json-patch+json" --request PATCH --data '[{"op": "remove", "path": "/status/allocatable/example.com~1dongle"}]' https://$MASTER:8443/api/v1/nodes/$NODE/status > /dev/null
  elif [ "$1" == "get-er" ]
    then
      echo "================================"
      echo "Resources on $NODE"
      echo "================================"
      oc describe node $NODE |egrep -A15 Capacity
      echo "================================"
  elif [ "$1" == "create-pod" ]
    then
      oc create -f extended-resource-pod.yaml
  elif [ "$1" == "delete-pod" ]
    then
      oc delete -f extended-resource-pod.yaml
  elif [ "$1" == "get-pod" ]
    then
      echo "================================"
      echo "Status of pod"
      echo "================================"
      oc get pod extended-resource-demo
      echo "================================"
      echo "Limits/Requests on pod"
      echo "================================"
      oc describe pod extended-resource-demo | grep -A3 Limits
      echo "================================"
  else
    echo "syntax $0 add-er|remove-er|get-er|create-pod|delete-pod|create-pod"
    exit 1
fi
