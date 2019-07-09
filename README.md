# airflow-k8s-deployer
Deploying Airflow containers to Kubernetes.  
This repository referred to the original one. => https://github.com/apache/airflow

## Manifests
- manifests/templates/airflow.template.yaml
    - A base for build/airflow.yaml
- manifests/templates/configmaps.template.yaml
    - A base for build/configmaps.yaml
- manifests/templates/init_git_sync.template.yaml
    - A part of airflow.yaml with `git_mode`
- manigests/secrets.yaml
    - airflow-secrets
- manifests/default
    - The original manifests used hostPath with PersistentVolume.
- manifests/nfs-deployment
    - Using NFS with PersistentVolumeClaim for `airflow-dags`, `airflow-logs`, `test-volume`, `postgres-volume`.
- manifests/nfs-statefulset
    - Using NFS with PersistentVolumeClaim for `airflow-dags`, `airflow-logs`, `test-volume`.
    - Using NFS with StatefuleSet for `postgres-volume`.

## NFS Provisioner
If you mount NFS Server, Create NFS Provisioner.  
https://github.com/Esfahan/nfs-provisioner-k8s

```
$ git submodule update -i && git submodule foreach git pull origin master
$ sudo ./nfs-provisioner-k8s/nfs-porvisioner/apply.sh
```

## Build Docker image
Build with https://github.com/apache/airflow.git

```
$ git clone https://github.com/apache/airflow.git
$ cd airflow
$ sudo ./scripts/ci/kubernetes/docker/build.sh
```

Check the built images as below.

```
$ sudo docker images
REPOSITORY                                        TAG                 IMAGE ID            CREATED             SIZE
airflow                                           latest              7701b2257310        12 seconds ago      758MB
python                                            3.6-slim            57fa2bc2339a        6 hours ago         142MB
```

## Deploy
Deploy Airflow containers to Kubernetes.

```
$ sudo ./deploy.sh -d {persistent_mode,git_mode} -r {default,dpl,sts}
```

## WEB UI
Forward port to browse web ui.

Check the pod name of Airflow with command below.

```sh
$ sudo kubectl get pod
NAME                                      READY   STATUS    RESTARTS   AGE
airflow-xxxxxxxxxx-xxxxx                  2/2     Running   0          22m
```

```
$ sudo kubectl port-forward [PodName of Airflow] 8080:8080 --address="0.0.0.0"
```

http://{YOUR_HOST_NAME}:8080

Check your default account created when Docker Image is built with code below.  
[airflow/scripts/ci/kubernetes/docker/airflow-test-env-init.sh](https://github.com/apache/airflow/blob/0ac501faa976a3bdc91ad9455c8de83c6b4abdd0/scripts/ci/kubernetes/docker/airflow-test-env-init.sh#L28)

## Differences to the original deploy.sh
Original => [deploy.sh](https://github.com/apache/airflow/blob/f710a0db493f89829849fb17230060f91e3925d2/scripts/ci/kubernetes/kube/deploy.sh)

```diff
$ git diff scripts/ci/kubernetes/kube/deploy.sh
diff --git a/scripts/ci/kubernetes/kube/deploy.sh b/scripts/ci/kubernetes/kube/deploy.sh
index 3d8562b..eb1c3b5 100755
--- a/scripts/ci/kubernetes/kube/deploy.sh
+++ b/scripts/ci/kubernetes/kube/deploy.sh
@@ -21,7 +21,7 @@ set -x

 AIRFLOW_IMAGE=${IMAGE:-airflow}
 AIRFLOW_TAG=${TAG:-latest}
-DIRNAME=$(cd "$(dirname "$0")"; pwd)
+DIRNAME=$(cd "$(dirname "$0")"; pwd)/manifests
 TEMPLATE_DIRNAME=${DIRNAME}/templates
 BUILD_DIRNAME=${DIRNAME}/build

@@ -30,14 +30,17 @@ usage() {
   usage: $0 options
   OPTIONS:
     -d Use PersistentVolume or GitSync for dags_folder. Available options are "persistent_mode" or "git_mode"
+    -r Use NFS with Deployment or NFS with StatefulSet. Available options are "default" or "dpl" or "sts"
 EOF
     exit 1;
 }

-while getopts ":d:" OPTION; do
+while getopts ":d:r:" OPTION; do
   case ${OPTION} in
     d)
       DAGS_VOLUME=${OPTARG};;
+    r)
+      RESOURCE=${OPTARG};;
     \?)
       echo "Invalid option: -$OPTARG" >&2
       exit 1
@@ -62,6 +65,18 @@ case ${DAGS_VOLUME} in
     ;;
 esac

+case ${RESOURCE} in
+  "dpl")
+    MANIFEST_DIRNAME="${DIRNAME}/nfs-deployment"
+    ;;
+  "sts")
+    MANIFEST_DIRNAME="${DIRNAME}/nfs-statefulset"
+    ;;
+  *)
+    MANIFEST_DIRNAME="${DIRNAME}/default"
+    ;;
+esac
+
 if [ ! -d "$BUILD_DIRNAME" ]; then
   mkdir -p ${BUILD_DIRNAME}
 fi
@@ -141,7 +156,7 @@ if [[ "${TRAVIS}" == true ]]; then
   sudo chown -R travis.travis $HOME/.kube $HOME/.minikube
 fi

-kubectl delete -f $DIRNAME/postgres.yaml
+kubectl delete -f $MANIFEST_DIRNAME/postgres.yaml
 kubectl delete -f $BUILD_DIRNAME/airflow.yaml
 kubectl delete -f $DIRNAME/secrets.yaml

@@ -149,8 +164,8 @@ set -e

 kubectl apply -f $DIRNAME/secrets.yaml
 kubectl apply -f $BUILD_DIRNAME/configmaps.yaml
-kubectl apply -f $DIRNAME/postgres.yaml
-kubectl apply -f $DIRNAME/volumes.yaml
+kubectl apply -f $MANIFEST_DIRNAME/postgres.yaml
+kubectl apply -f $MANIFEST_DIRNAME/volumes.yaml
 kubectl apply -f $BUILD_DIRNAME/airflow.yaml

 dump_logs() {
```
