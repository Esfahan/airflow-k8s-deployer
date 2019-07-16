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
$ sudo ./deploy.sh -n {YOUR_NAME_SPACE} -d {persistent_mode,git_mode} -r {default,dpl,sts}
Usage:
  OPTIONS:
    -h help
    -n Specify Namespace
    -d Use PersistentVolume or GitSync for dags_folder. Available options are "persistent_mode" or "git_mode"
    -r Use NFS with Deployment or NFS with StatefulSet. Available options are "default" or "dpl" or "sts"
    -c Use postgres-container
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
