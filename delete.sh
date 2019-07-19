#!/bin/bash
DIRNAME=$(cd "$(dirname "$0")"; pwd)/manifests
BUILD_DIRNAME=${DIRNAME}/build

set -x

usage() {
    cat << EOF
  usage: $0 options
  OPTIONS:
    -h help
    -n Specify NAMESPACE
    -r Use NFS with Deployment or NFS with StatefulSet. Available options are "default" or "dpl" or "sts"
EOF
    exit 1;
}

while getopts ":n:r:h" OPTION; do
  case ${OPTION} in
    n)
      NAMESPACE=${OPTARG};;
    r)
      RESOURCE=${OPTARG};;
    h)
      usage
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      usage
      ;;
  esac
done

if [ -z "${NAMESPACE}" ]; then
  NAMESPACE=default
fi

if [ -z "${RESOURCE}" ]; then
  echo "Invalid resource: -$RESOURCE" >&2
  usage
  exit 1
fi

case ${RESOURCE} in
  "dpl")
    MANIFEST_DIRNAME="${DIRNAME}/nfs-deployment"
    ;;
  "sts")
    MANIFEST_DIRNAME="${DIRNAME}/nfs-statefulset"
    ;;
  *)
    MANIFEST_DIRNAME="${DIRNAME}/default"
    ;;
esac

kubectl config set-context $(kubectl config current-context) --namespace=${NAMESPACE}

kubectl delete -f $DIRNAME/secrets.yaml
kubectl delete -f $BUILD_DIRNAME/configmaps.yaml
kubectl delete -f $BUILD_DIRNAME/postgres.yaml
kubectl delete -f $BUILD_DIRNAME/airflow.yaml
kubectl delete -f $BUILD_DIRNAME/ingress.yaml
#kubectl delete -f $BUILD_DIRNAME/volumes.yaml
#kubectl delete -f $BUILD_DIRNAME/namespace.yaml
