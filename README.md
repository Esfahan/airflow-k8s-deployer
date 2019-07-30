# airflow-k8s-deployer
Deploying Airflow containers to Kubernetes.  
This repository referred to the original one. => https://github.com/apache/airflow

## Requirements
- [airflow-1.10.3](https://github.com/apache/airflow/releases/tag/1.10.3)

## Manifests
- manifests/templates/airflow.template.yaml
    - A base for build/airflow.yaml
- manifests/templates/configmaps.template.yaml
    - A base for build/configmaps.yaml
- manifests/templates/ingress.template.yaml
    - A base for build/ingress.yaml
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
$ sudo ./nfs-provisioner-k8s/nfs-provisioner/apply.sh
```

## Patch
You need this patch for [airflow-1.10.3](https://github.com/apache/airflow/releases/tag/1.10.3)

Ref: [Apache Airflow : airflow initdb results in “ImportError: No module named json”](https://stackoverflow.com/questions/56923003/apache-airflow-airflow-initdb-results-in-importerror-no-module-named-json)

```diff
$ git diff setup.py
diff --git a/setup.py b/setup.py
index 006de0a..95c40ae 100644
--- a/setup.py
+++ b/setup.py
@@ -307,7 +307,7 @@ def do_setup():
             'gunicorn>=19.5.0, <20.0',
             'iso8601>=0.1.12',
             'json-merge-patch==0.2',
-            'jinja2>=2.7.3, <=2.10.0',
+            'jinja2>=2.10.0',
             'lxml>=4.0.0',
             'markdown>=2.5.2, <3.0',
             'pandas>=0.17.1, <1.0.0',
@@ -324,9 +324,9 @@ def do_setup():
             'text-unidecode==1.2',
             'typing;python_version<"3.5"',
             'thrift>=0.9.2',
-            'tzlocal>=1.4',
+            'tzlocal>=1.5.0.0, <2.0.0.0',
             'unicodecsv>=0.14.1',
-            'werkzeug>=0.14.1, <0.15.0',
+            'werkzeug>=0.15.0',
             'zope.deprecation>=4.0, <5.0',
         ],
         setup_requires=[
```

## Add PyMySQL to Docker Image
If you use MySQL insted of PostgreSQL,  
Add `RUN pip install PyMySQL` into [scripts/ci/kubernetes/docker/Dockerfile#L41](https://github.com/apache/airflow/blob/1.10.3/scripts/ci/kubernetes/docker/Dockerfile).

Like this.

```diff
# Since we install vanilla Airflow, we also want to have support for Postgres and Kubernetes
RUN pip install -U setuptools && \
    pip install kubernetes && \
    pip install cryptography && \
    pip install psycopg2-binary==2.7.4  # I had issues with older versions of psycopg2, just a warning

+RUN pip install PyMySQL

# install airflow
COPY airflow.tar.gz /tmp/airflow.tar.gz
RUN pip install --no-use-pep517 /tmp/airflow.tar.gz
```


## Build Docker image
Build with https://github.com/apache/airflow.git

```
$ git clone https://github.com/apache/airflow.git
$ cd airflow
$ sudo SLUGIFY_USES_TEXT_UNIDECODE=yes PYTHON_VERSION=3 ./scripts/ci/kubernetes/docker/build.sh
```

Check the built images as below.

```
$ sudo docker images
REPOSITORY                                        TAG                 IMAGE ID            CREATED             SIZE
airflow                                           latest              7701b2257310        12 seconds ago      758MB
ubuntu                                            16.04               5e13f8dd4c1a        12 seconds ago      120MB
postgres                                          latest              53912975086f        12 seconds ago      312MB
python                                            3.6-slim            57fa2bc2339a        12 seconds ago      142MB
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
### With Ingress
http://{YOUR_HOST_NAME}

### Without Ingress
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
[airflow/scripts/ci/kubernetes/docker/airflow-test-env-init.sh](https://github.com/apache/airflow/blob/1.10.3/scripts/ci/kubernetes/docker/airflow-test-env-init.sh#L28)

## Differences to the original deploy.sh
Original => [scripts/ci/kubernetes/kube/deploy.sh](https://github.com/apache/airflow/blob/1.10.3/scripts/ci/kubernetes/kube/deploy.sh)
