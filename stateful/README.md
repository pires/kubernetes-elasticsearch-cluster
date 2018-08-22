# Elasticsearch StatefulSet Data Pod

This directory contains Kubernetes configurations which run elasticsearch data and master pods as a [`StatefulSet`](https://kubernetes.io/docs/concepts/abstractions/controllers/statefulsets/), using storage provisioned using a [`StorageClass`](http://blog.kubernetes.io/2016/10/dynamic-provisioning-and-storage-in-kubernetes.html). Be sure to read and understand the documentation in the root directory, which deploys the data pods as a `Deployment` using an `emptyDir` for storage.

## Storage

The [`es-data-stateful.yaml`](es-data-stateful.yaml) and [`es-master-stateful.yaml`](es-master-stateful.yaml) files contain `volumeClaimTemplates` sections which request 2GB volume for each master node, and 12GB volume for each data node. This is plenty of space for a demonstration cluster, but will fill up quickly under moderate to heavy load. Consider modifying the disk size to your needs.

## Deploy
The root directory contains instructions for deploying elasticsearch using a `Deployment` with transient storage for data pods. These brief instructions show a deployment using the `StatefulSet` and `StorageClass`.

```
kubectl create -f ../es-discovery-svc.yaml
kubectl create -f ../es-svc.yaml

kubectl create -f es-master-svc.yaml
kubectl create -f es-master-stateful.yaml
kubectl rollout status -f es-master-stateful.yaml

kubectl create -f ../es-ingest-svc.yaml
kubectl create -f ../es-ingest.yaml
kubectl rollout status -f ../es-ingest.yaml

kubectl create -f es-data-svc.yaml
kubectl create -f es-data-stateful.yaml
kubectl rollout status -f es-data-stateful.yaml
```

Kubernetes creates the pods for a `StatefulSet` one at a time, waiting for each to come up before starting the next, so it may take a few minutes for all pods to be provisioned. Refer back to the documentation in the root directory for details on testing the cluster, and configuring a curator job to clean up.
