# kubernetes-elasticsearch-cluster
Elasticsearch (6.3.2) cluster on top of Kubernetes made easy.

### Table of Contents

* [(Very) Important Notes](#important-notes)
* [Pre-Requisites](#pre-requisites)
* [Build container image (optional)](#build-images)
* [Test](#test)
  * [Deploy](#deploy)
  * [Access the service](#access-the-service)
* [Pod anti-affinity](#pod-anti-affinity)
* [Availability](#availability)
* [Deploy with Helm](#helm)
* [Install plug-ins](#plugins)
* [Clean-up with Curator](#curator)
* [Kibana](#kibana)
* [FAQ](#faq)
* [Troubleshooting](#troubleshooting)

## Abstract

[Elasticsearch best-practices recommend to separate nodes in three roles](https://www.elastic.co/guide/en/elasticsearch/reference/6.2/modules-node.html):

* `Master` nodes - intended for clustering management only, no data, no HTTP API
* `Data` nodes - intended for client usage and data
* `Ingest` nodes - intended for document pre-processing during ingestion

Given this, I'm going to demonstrate how to provision a production grade scenario consisting of 3 master, 2 data and 2 ingest nodes.

<a id="important-notes">

## (Very) Important notes

* Elasticsearch pods need for an init-container to run in privileged mode, so it can set some VM options.
  For that to happen, the `kubelet` should be running with args `--allow-privileged`, otherwise the init-container will fail to run.

* By default, `ES_JAVA_OPTS` is set to `-Xms256m -Xmx256m`. This is a *very low* value but many users, i.e. `minikube` users,
  were having issues with pods getting killed because hosts were out of memory.
  One can change this in the deployment descriptors available in this repository.

* As of the moment, Kubernetes pod descriptors use an `emptyDir` for storing data in each data node container.
  This is meant to be for the sake of simplicity and should be adapted according to one's storage needs.

* The [stateful](stateful) directory contains an example which deploys the data pods as a `StatefulSet`.
  These use a `volumeClaimTemplates` to provision persistent storage for each pod.

* By default, `PROCESSORS` is set to `1`. This may not be enough for some deployments, especially at startup time.
  Adjust `resources.limits.cpu` and/or `livenessProbe` accordingly if required. Note that `resources.limits.cpu` must be an integer.

<a id="pre-requisites">

## Pre-requisites

* Kubernetes 1.11.x (tested with v1.11.2 on top of [Vagrant + CoreOS](https://github.com/pires/kubernetes-vagrant-coreos-cluster)).
* `kubectl` configured to access the Kubernetes API.

<a id="build-images">

## Build images (optional)

Providing one's own version of [the images automatically built from this repository](https://github.com/pires/docker-elasticsearch-kubernetes) will not be supported. This is an *optional* step. One has been warned.

## Test

### Deploy

```shell
kubectl create -f es-discovery-svc.yaml
kubectl create -f es-svc.yaml
kubectl create -f es-master.yaml
kubectl rollout status -f es-master.yaml

kubectl create -f es-ingest-svc.yaml
kubectl create -f es-ingest.yaml
kubectl rollout status -f es-ingest.yaml

kubectl create -f es-data.yaml
kubectl rollout status -f es-data.yaml
```

Let's check if everything is working properly:

```shell
kubectl get svc,deployment,pods -l component=elasticsearch
NAME                              TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/elasticsearch             ClusterIP   10.100.243.196   <none>        9200/TCP   3m
service/elasticsearch-discovery   ClusterIP   None             <none>        9300/TCP   3m
service/elasticsearch-ingest      ClusterIP   10.100.76.74     <none>        9200/TCP   2m

NAME                              DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deployment.extensions/es-data     2         2         2            2           1m
deployment.extensions/es-ingest   2         2         2            2           2m
deployment.extensions/es-master   3         3         3            3           3m

NAME                             READY     STATUS    RESTARTS   AGE
pod/es-data-56f8ff8c97-642bq     1/1       Running   0          1m
pod/es-data-56f8ff8c97-h6hpc     1/1       Running   0          1m
pod/es-ingest-6ddd5fc689-b4s94   1/1       Running   0          2m
pod/es-ingest-6ddd5fc689-d8rtj   1/1       Running   0          2m
pod/es-master-68bf8f86c4-bsfrx   1/1       Running   0          3m
pod/es-master-68bf8f86c4-g8nph   1/1       Running   0          3m
pod/es-master-68bf8f86c4-q5khn   1/1       Running   0          3m
```

As we can assert, the cluster seems to be up and running. Easy, wasn't it?

### Access the service

*Don't forget* that services in Kubernetes are only acessible from containers in the cluster. For different behavior one should [configure the creation of an external load-balancer](https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer). While it's supported within this example service descriptor, its usage is out of scope of this document, for now.

*Note:* if you are using one of the cloud providers which support external load balancers, setting the type field to "LoadBalancer" will provision a load balancer for your Service. You can uncomment the field in [es-svc.yaml](https://github.com/pires/kubernetes-elasticsearch-cluster/blob/master/es-svc.yaml).

```shell
kubectl get svc elasticsearch
NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
elasticsearch   ClusterIP   10.100.243.196   <none>        9200/TCP   3m
```

From any host on the Kubernetes cluster (that's running `kube-proxy` or similar), run:

```shell
curl http://10.100.243.196:9200
```

One should see something similar to the following:

```json
{
  "name" : "es-data-56f8ff8c97-642bq",
  "cluster_name" : "myesdb",
  "cluster_uuid" : "RkRkTl26TDOE7o0FhCcW_g",
  "version" : {
    "number" : "6.3.2",
    "build_flavor" : "default",
    "build_type" : "tar",
    "build_hash" : "053779d",
    "build_date" : "2018-07-20T05:20:23.451332Z",
    "build_snapshot" : false,
    "lucene_version" : "7.3.1",
    "minimum_wire_compatibility_version" : "5.6.0",
    "minimum_index_compatibility_version" : "5.0.0"
  },
  "tagline" : "You Know, for Search"
}
```

Or if one wants to see cluster information:

```shell
curl http://10.100.243.196:9200/_cluster/health?pretty
```

One should see something similar to the following:

```json
{
  "cluster_name" : "myesdb",
  "status" : "green",
  "timed_out" : false,
  "number_of_nodes" : 7,
  "number_of_data_nodes" : 2,
  "active_primary_shards" : 0,
  "active_shards" : 0,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 0,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 100.0
}
```

<a id="pod-anti-affinity">

## Pod anti-affinity

One of the main advantages of running Elasticsearch on top of Kubernetes is how resilient the cluster becomes, particularly during
node restarts. However if all data pods are scheduled onto the same node(s), this advantage decreases significantly and may even
result in no data pods being available.

It is then **highly recommended**, in the context of the solution described in this repository, that one adopts [pod anti-affinity](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#inter-pod-affinity-and-anti-affinity-beta-feature)
in order to guarantee that two data pods will never run on the same node.

Here's an example:

```yaml
spec:
  affinity:
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: component
              operator: In
              values:
              - elasticsearch
            - key: role
              operator: In
              values:
              - data
          topologyKey: kubernetes.io/hostname
  containers:
  - (...)
```

<a id="availability">

## Availability

If one wants to ensure that no more than `n` Elasticsearch nodes will be unavailable at a time, one can optionally (change and) apply the following manifests:

```shell
kubectl create -f es-master-pdb.yaml
kubectl create -f es-data-pdb.yaml
```

**Note:** This is an advanced subject and one should only put it in practice if one understands clearly what it means both in the Kubernetes and Elasticsearch contexts. For more information, please consult [Pod Disruptions](https://kubernetes.io/docs/concepts/workloads/pods/disruptions).

<a id="helm">

## Deploy with Helm

**WARNING:** The Helm chart is maintained by someone else in the community and may not up-to-date with this repo.

[Helm](https://github.com/kubernetes/helm) charts for a basic (non-stateful) ElasticSearch deployment are maintained at https://github.com/clockworksoul/helm-elasticsearch. With Helm properly installed and configured, standing up a complete cluster is almost trivial:

```shell
git clone https://github.com/clockworksoul/helm-elasticsearch.git
helm install helm-elasticsearch
```

Various parameters of the cluster, including replica count and memory allocations, can be adjusted by editing the `helm-elasticsearch/values.yaml` file. For information about Helm, please consult the [complete Helm documentation](https://github.com/kubernetes/helm/blob/master/docs/index.md).

<a id="plugins">

## Install plug-ins

The image used in this repo is very minimalist. However, one can install additional plug-ins at will by simply specifying the `ES_PLUGINS_INSTALL` environment variable in the desired pod descriptors. For instance, to install [Google Cloud Storage](https://www.elastic.co/guide/en/elasticsearch/plugins/current/repository-gcs.html) and [S3](https://www.elastic.co/guide/en/elasticsearch/plugins/current/repository-s3.html) plug-ins it would be like follows:

```yaml
- name: "ES_PLUGINS_INSTALL"
  value: "repository-gcs,repository-s3"
```

**Note:** The X-Pack plugin does not currently work with the `quay.io/pires/docker-elasticsearch-kubernetes` image. See Issue #102

<a id="curator">

## Clean-up with Curator

Additionally, one can run a [CronJob](http://kubernetes.io/docs/user-guide/cron-jobs/) that will periodically run [Curator](https://github.com/elastic/curator) to clean up indices (or do other actions on the Elasticsearch cluster).

```shell
kubectl create -f es-curator-config.yaml
kubectl create -f es-curator.yaml
```

Please, confirm the job has been created.

```shell
kubectl get cronjobs
NAME      SCHEDULE    SUSPEND   ACTIVE    LAST-SCHEDULE
curator   1 0 * * *   False     0         <none>
```

The job is configured to run once a day at _1 minute past midnight and delete indices that are older than 3 days_.

**Notes**

* One can change the schedule by editing the cron notation in `es-curator.yaml`.
* One can change the action (e.g. delete older than 3 days) by editing the `es-curator-config.yaml`.
* The definition of the `action_file.yaml` is quite self-explaining for simple set-ups. For more advanced configuration options, please consult the [Curator Documentation](https://www.elastic.co/guide/en/elasticsearch/client/curator/current/index.html).

If one wants to remove the curator job, just run:

```shell
kubectl delete cronjob curator
kubectl delete configmap curator-config
```

<a id="kibana">

## Kibana

**WARNING:** The Kibana section is maintained by someone else in the community and may not up-to-date with this repo.

### Deploy

If Kibana defaults are not enough, one may want to customize `kibana.yaml` through a `ConfigMap`.
Please refer to [Configuring Kibana](https://www.elastic.co/guide/en/kibana/current/settings.html) for all available attributes.

```shell
kubectl create -f kibana-cm.yaml
kubectl create -f kibana-svc.yaml
kubectl create -f kibana.yaml
```

Kibana will become available through service `kibana`, and one will be able to access it from within the cluster, or proxy it through the Kubernetes API as follows:

```shell
curl https://<API_SERVER_URL>/api/v1/namespaces/default/services/kibana:http/proxy
```

One can also create an Ingress to expose the service publicly or simply use the service nodeport.
In the case one proceeds to do so, one must change the environment variable `SERVER_BASEPATH` to the match their environment.

## FAQ

### Why does `NUMBER_OF_MASTERS` differ from number of master-replicas?

The default value for this environment variable is 2, meaning a cluster will need a minimum of 2 master nodes to operate. If a cluster has 3 masters and one dies, the cluster still works. Minimum master nodes are usually `n/2 + 1`, where `n` is the number of master nodes in a cluster. If a cluster has 5 master nodes, one should have a minimum of 3, less than that and the cluster _stops_. If one scales the number of masters, make sure to update the minimum number of master nodes through the Elasticsearch API as setting environment variable will only work on cluster setup. More info: https://www.elastic.co/guide/en/elasticsearch/guide/1.x/_important_configuration_changes.html#_minimum_master_nodes


### How can I customize `elasticsearch.yaml`?

Read a different config file by settings env var `ES_PATH_CONF=/path/to/my/config/` [(see the Elasticsearch docs for more)](https://www.elastic.co/guide/en/elasticsearch/reference/current/settings.html#config-files-location). Another option would be to build one's own image from  [this repository](https://github.com/pires/docker-elasticsearch-kubernetes)

## Troubleshooting

### No up-and-running site-local

One of the errors one may come across when running the setup is the following error:

```
[2016-11-29T01:28:36,515][WARN ][o.e.b.ElasticsearchUncaughtExceptionHandler] [] uncaught exception in thread [main]
org.elasticsearch.bootstrap.StartupException: java.lang.IllegalArgumentException: No up-and-running site-local (private) addresses found, got [name:lo (lo), name:eth0 (eth0)]
	at org.elasticsearch.bootstrap.Elasticsearch.init(Elasticsearch.java:116) ~[elasticsearch-5.0.1.jar:5.0.1]
	at org.elasticsearch.bootstrap.Elasticsearch.execute(Elasticsearch.java:103) ~[elasticsearch-5.0.1.jar:5.0.1]
	at org.elasticsearch.cli.SettingCommand.execute(SettingCommand.java:54) ~[elasticsearch-5.0.1.jar:5.0.1]
	at org.elasticsearch.cli.Command.mainWithoutErrorHandling(Command.java:96) ~[elasticsearch-5.0.1.jar:5.0.1]
	at org.elasticsearch.cli.Command.main(Command.java:62) ~[elasticsearch-5.0.1.jar:5.0.1]
	at org.elasticsearch.bootstrap.Elasticsearch.main(Elasticsearch.java:80) ~[elasticsearch-5.0.1.jar:5.0.1]
	at org.elasticsearch.bootstrap.Elasticsearch.main(Elasticsearch.java:73) ~[elasticsearch-5.0.1.jar:5.0.1]
Caused by: java.lang.IllegalArgumentException: No up-and-running site-local (private) addresses found, got [name:lo (lo), name:eth0 (eth0)]
	at org.elasticsearch.common.network.NetworkUtils.getSiteLocalAddresses(NetworkUtils.java:187) ~[elasticsearch-5.0.1.jar:5.0.1]
	at org.elasticsearch.common.network.NetworkService.resolveInternal(NetworkService.java:246) ~[elasticsearch-5.0.1.jar:5.0.1]
 	at org.elasticsearch.common.network.NetworkService.resolveInetAddresses(NetworkService.java:220) ~[elasticsearch-5.0.1.jar:5.0.1]
 	at org.elasticsearch.common.network.NetworkService.resolveBindHostAddresses(NetworkService.java:130) ~[elasticsearch-5.0.1.jar:5.0.1]
 	at org.elasticsearch.transport.TcpTransport.bindServer(TcpTransport.java:575) ~[elasticsearch-5.0.1.jar:5.0.1]
 	at org.elasticsearch.transport.netty4.Netty4Transport.doStart(Netty4Transport.java:182) ~[?:?]
 	at org.elasticsearch.common.component.AbstractLifecycleComponent.start(AbstractLifecycleComponent.java:68) ~[elasticsearch-5.0.1.jar:5.0.1]
 	at org.elasticsearch.transport.TransportService.doStart(TransportService.java:182) ~[elasticsearch-5.0.1.jar:5.0.1]
 	at org.elasticsearch.common.component.AbstractLifecycleComponent.start(AbstractLifecycleComponent.java:68) ~[elasticsearch-5.0.1.jar:5.0.1]
 	at org.elasticsearch.node.Node.start(Node.java:525) ~[elasticsearch-5.0.1.jar:5.0.1]
 	at org.elasticsearch.bootstrap.Bootstrap.start(Bootstrap.java:211) ~[elasticsearch-5.0.1.jar:5.0.1]
 	at org.elasticsearch.bootstrap.Bootstrap.init(Bootstrap.java:288) ~[elasticsearch-5.0.1.jar:5.0.1]
 	at org.elasticsearch.bootstrap.Elasticsearch.init(Elasticsearch.java:112) ~[elasticsearch-5.0.1.jar:5.0.1]
 	... 6 more
[2016-11-29T01:28:37,448][INFO ][o.e.n.Node               ] [kIEYQSE] stopping ...
[2016-11-29T01:28:37,451][INFO ][o.e.n.Node               ] [kIEYQSE] stopped
[2016-11-29T01:28:37,452][INFO ][o.e.n.Node               ] [kIEYQSE] closing ...
[2016-11-29T01:28:37,464][INFO ][o.e.n.Node               ] [kIEYQSE] closed
```

This is related to how the container binds to network ports (defaults to ``_local_``). It will need to match the actual node network interface name, which depends on what OS and infrastructure provider one uses. For instance, if the primary interface on the node is `p1p1` then that is the value that needs to be set for the `NETWORK_HOST` environment variable.
Please see [the documentation](https://github.com/pires/docker-elasticsearch#environment-variables) for reference of options.

In order to workaround this, set `NETWORK_HOST` environment variable in the pod descriptors as follows:

```yaml
- name: "NETWORK_HOST"
  value: "_eth0_" #_p1p1_ if interface name is p1p1, _ens4_ if interface name is ens4, and so on.
```

### (IPv6) org.elasticsearch.bootstrap.StartupException: BindTransportException

Intermittent failures occur when the local network interface has both IPv4 and IPv6 addresses, and Elasticsearch tries to bind to the IPv6 address first.
If the IPv4 address is chosen first, Elasticsearch starts correctly.

In order to workaround this, set `NETWORK_HOST` environment variable in the pod descriptors as follows:

```yaml
- name: "NETWORK_HOST"
  value: "_eth0:ipv4_" #_p1p1:ipv4_ if interface name is p1p1, _ens4:ipv4_ if interface name is ens4, and so on.
```
