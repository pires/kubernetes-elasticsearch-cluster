# kubernetes-elasticsearch-cluster
Elasticsearch (5.4.0) cluster on top of Kubernetes made easy.

### Table of Contents

* [Important Notes](#important-notes)
* [Pre-Requisites](#pre-requisites)
* [Build-Images(optional)](#build-images)
* [Test (deploying & accessing)](#test)
* [Deploying with Helm](#helm)
* [Install plug-ins](#plugins)
* [Clean up with Curator](#curator)
* [FAQ](#faq)
* [Troubleshooting](#troubleshooting)

## Abstract

Elasticsearch best-practices recommend to separate nodes in three roles:
* `Master` nodes - intended for clustering management only, no data, no HTTP API
* `Client` nodes - intended for client usage, no data, with HTTP API
* `Data` nodes - intended for storing and indexing data, no HTTP API

Given this, I'm going to demonstrate how to provision a (near, as storage is still an issue) production grade scenario consisting of 3 master, 2 client and 2 data nodes.

<a id="important-notes">

## (Very) Important notes

* Elasticsearch pods need for an init-container to run in privileged mode, so it can set some VM options. For that to happen, the `kubelet` should be running with args `--allow-privileged`, otherwise
the init-container will fail to run.

* By default, `ES_JAVA_OPTS` is set to `-Xms256m -Xmx256m`. This is a *very low* value but many users, i.e. `minikube` users, were having issues with pods getting killed because hosts were out of memory.
One can change this in the deployment descriptors available in this repository.

* As of the moment, Kubernetes pod descriptors use an `emptyDir` for storing data in each data node container. This is meant to be for the sake of simplicity and should be adapted according to one's storage needs.

* The [stateful](stateful) directory contains an example which deploys the data pods as a `StatefulSet`. These use a `volumeClaimTemplates` to provision persistent storage for each pod.

<a id="pre-requisites">

## Pre-requisites

* Kubernetes cluster with **alpha features enabled** (tested with v1.5.2 on top of [Vagrant + CoreOS](https://github.com/pires/kubernetes-vagrant-coreos-cluster))
* `kubectl` configured to access the cluster master API Server

<a id="build-images">

## Build images (optional)

Providing one's own version of [the images automatically built from this repository](https://github.com/pires/docker-elasticsearch-kubernetes) will not be supported. This is an *optional* step. One has been warned.

## Test

### Deploy ELK (Elasticsearch and Kibana)
./start-es-cluster.sh

### Stopping the elk cluster
./stop-es-cluster.sh

### Test Kibana URL
http://{kubernetes-node-ips}:30102/status

### Test Elastic search API
http://{kubernetes-node-ips}:30101


### Deploy Elasticsearch Only

```
kubectl create -f es-discovery-svc.yaml
kubectl create -f es-svc.yaml
kubectl create -f es-master.yaml
```

Wait until `es-master` deployment is provisioned, and
```
kubectl create -f es-client.yaml
kubectl create -f es-data.yaml
```

Wait for containers to be in the `Running` state and check one of the Elasticsearch master nodes logs:
```
$ kubectl get svc,deployment,pods
NAME                          CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
svc/elasticsearch             10.100.75.158   <pending>     9200:31163/TCP   3m
svc/elasticsearch-discovery   10.100.182.93   <none>        9300/TCP         3m
svc/kubernetes                10.100.0.1      <none>        443/TCP          1h

NAME               DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/es-client   2         2         2            2           32s
deploy/es-data     2         2         2            2           32s
deploy/es-master   3         3         3            3           3m

NAME                            READY     STATUS    RESTARTS   AGE
po/es-client-3170561982-djb1f   1/1       Running   0          32s
po/es-client-3170561982-mwfhs   1/1       Running   0          32s
po/es-data-1526844084-4mfg3     1/1       Running   0          31s
po/es-data-1526844084-8njx2     1/1       Running   0          31s
po/es-master-2212299741-0x880   1/1       Running   0          3m
po/es-master-2212299741-1j9lm   1/1       Running   0          3m
po/es-master-2212299741-p1jrt   1/1       Running   0          3m
```

```
$ kubectl logs po/es-master-2212299741-0x880
[2017-05-10T08:57:49,686][INFO ][o.e.n.Node               ] [es-master-2212299741-0x880] initializing ...
[2017-05-10T08:57:49,793][INFO ][o.e.e.NodeEnvironment    ] [es-master-2212299741-0x880] using [1] data paths, mounts [[/data (/dev/sda9)]], net usable_space [13.6gb], net total_space [15.5gb], spins? [possibly], types [ext4]
[2017-05-10T08:57:49,794][INFO ][o.e.e.NodeEnvironment    ] [es-master-2212299741-0x880] heap size [247.5mb], compressed ordinary object pointers [true]
[2017-05-10T08:57:49,797][INFO ][o.e.n.Node               ] [es-master-2212299741-0x880] node name [es-master-2212299741-0x880], node ID [NQTFaK_vRO6YixjB3_8cLQ]
[2017-05-10T08:57:49,799][INFO ][o.e.n.Node               ] [es-master-2212299741-0x880] version[5.4.0], pid[12], build[780f8c4/2017-04-28T17:43:27.229Z], OS[Linux/4.10.12-coreos/amd64], JVM[Oracle Corporation/OpenJDK 64-Bit Server VM/1.8.0_121/25.121-b13]
[2017-05-10T08:57:51,365][INFO ][o.e.p.PluginsService     ] [es-master-2212299741-0x880] loaded module [aggs-matrix-stats]
[2017-05-10T08:57:51,365][INFO ][o.e.p.PluginsService     ] [es-master-2212299741-0x880] loaded module [ingest-common]
[2017-05-10T08:57:51,366][INFO ][o.e.p.PluginsService     ] [es-master-2212299741-0x880] loaded module [lang-expression]
[2017-05-10T08:57:51,366][INFO ][o.e.p.PluginsService     ] [es-master-2212299741-0x880] loaded module [lang-groovy]
[2017-05-10T08:57:51,366][INFO ][o.e.p.PluginsService     ] [es-master-2212299741-0x880] loaded module [lang-mustache]
[2017-05-10T08:57:51,366][INFO ][o.e.p.PluginsService     ] [es-master-2212299741-0x880] loaded module [lang-painless]
[2017-05-10T08:57:51,366][INFO ][o.e.p.PluginsService     ] [es-master-2212299741-0x880] loaded module [percolator]
[2017-05-10T08:57:51,366][INFO ][o.e.p.PluginsService     ] [es-master-2212299741-0x880] loaded module [reindex]
[2017-05-10T08:57:51,366][INFO ][o.e.p.PluginsService     ] [es-master-2212299741-0x880] loaded module [transport-netty3]
[2017-05-10T08:57:51,366][INFO ][o.e.p.PluginsService     ] [es-master-2212299741-0x880] loaded module [transport-netty4]
[2017-05-10T08:57:51,368][INFO ][o.e.p.PluginsService     ] [es-master-2212299741-0x880] no plugins loaded
[2017-05-10T08:57:54,135][INFO ][o.e.d.DiscoveryModule    ] [es-master-2212299741-0x880] using discovery type [zen]
[2017-05-10T08:57:54,868][INFO ][o.e.n.Node               ] [es-master-2212299741-0x880] initialized
[2017-05-10T08:57:54,874][INFO ][o.e.n.Node               ] [es-master-2212299741-0x880] starting ...
[2017-05-10T08:57:55,144][INFO ][o.e.t.TransportService   ] [es-master-2212299741-0x880] publish_address {10.244.8.2:9300}, bound_addresses {10.244.8.2:9300}
[2017-05-10T08:57:55,159][INFO ][o.e.b.BootstrapChecks    ] [es-master-2212299741-0x880] bound or publishing to a non-loopback or non-link-local address, enforcing bootstrap checks
[2017-05-10T08:57:58,387][INFO ][o.e.c.s.ClusterService   ] [es-master-2212299741-0x880] detected_master {es-master-2212299741-1j9lm}{NM2PTRGoTeumDqDX9HpPJA}{UYMXBCwlT1iRYA_n2xiIgg}{10.244.65.3}{10.244.65.3:9300}, added {{es-master-2212299741-p1jrt}{RiXtIv1MRZCWo5gLY49SOg}{COlIrU86QZCAGStFmYWhxA}{10.244.55.2}{10.244.55.2:9300},{es-master-2212299741-1j9lm}{NM2PTRGoTeumDqDX9HpPJA}{UYMXBCwlT1iRYA_n2xiIgg}{10.244.65.3}{10.244.65.3:9300},}, reason: zen-disco-receive(from master [master {es-master-2212299741-1j9lm}{NM2PTRGoTeumDqDX9HpPJA}{UYMXBCwlT1iRYA_n2xiIgg}{10.244.65.3}{10.244.65.3:9300} committed version [2]])
[2017-05-10T08:57:58,433][INFO ][o.e.n.Node               ] [es-master-2212299741-0x880] started
[2017-05-10T09:00:22,451][INFO ][o.e.c.s.ClusterService   ] [es-master-2212299741-0x880] added {{es-client-3170561982-djb1f}{O9m5ywLUQ4GkzxUSmlMaiA}{UrDy6jrUTm-7BolECTI1LA}{10.244.55.3}{10.244.55.3:9300},}, reason: zen-disco-receive(from master [master {es-master-2212299741-1j9lm}{NM2PTRGoTeumDqDX9HpPJA}{UYMXBCwlT1iRYA_n2xiIgg}{10.244.65.3}{10.244.65.3:9300} committed version [4]])
[2017-05-10T09:00:22,628][INFO ][o.e.c.s.ClusterService   ] [es-master-2212299741-0x880] added {{es-data-1526844084-8njx2}{PvMdQGwGQt21D4ltTRyu0w}{ukaNsOurSImj4JB9vM4ofA}{10.244.8.3}{10.244.8.3:9300},}, reason: zen-disco-receive(from master [master {es-master-2212299741-1j9lm}{NM2PTRGoTeumDqDX9HpPJA}{UYMXBCwlT1iRYA_n2xiIgg}{10.244.65.3}{10.244.65.3:9300} committed version [5]])
[2017-05-10T09:00:26,671][INFO ][o.e.c.s.ClusterService   ] [es-master-2212299741-0x880] added {{es-client-3170561982-mwfhs}{87v1IBw9TSecjwjrBZOpFw}{ywtU3PTGQ56KRLpdy1LnLg}{10.244.65.4}{10.244.65.4:9300},}, reason: zen-disco-receive(from master [master {es-master-2212299741-1j9lm}{NM2PTRGoTeumDqDX9HpPJA}{UYMXBCwlT1iRYA_n2xiIgg}{10.244.65.3}{10.244.65.3:9300} committed version [6]])
[2017-05-10T09:00:28,684][INFO ][o.e.c.s.ClusterService   ] [es-master-2212299741-0x880] added {{es-data-1526844084-4mfg3}{F6EWBX0dTPuD0hXNcKqI-w}{ASI3slfvS6GIYweNQLoWpg}{10.244.65.5}{10.244.65.5:9300},}, reason: zen-disco-receive(from master [master {es-master-2212299741-1j9lm}{NM2PTRGoTeumDqDX9HpPJA}{UYMXBCwlT1iRYA_n2xiIgg}{10.244.65.3}{10.244.65.3:9300} committed version [7]])
```

As we can assert, the cluster is up and running. Easy, wasn't it?

### Access the service

*Don't forget* that services in Kubernetes are only acessible from containers in the cluster. For different behavior one should [configure the creation of an external load-balancer](http://kubernetes.io/v1.1/docs/user-guide/services.html#type-loadbalancer). While it's supported within this example service descriptor, its usage is out of scope of this document, for now.

```
$ kubectl get svc elasticsearch
NAME            CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
elasticsearch   10.100.75.158   <pending>     9200:31163/TCP   5m
```

From any host on the Kubernetes cluster (that's running `kube-proxy` or similar), run:

```
curl http://10.100.75.158:9200
```

One should see something similar to the following:

```json
{
  "name" : "es-client-3170561982-mwfhs",
  "cluster_name" : "myesdb",
  "cluster_uuid" : "TmidWUO6TJqFOd2WmHgg5Q",
  "version" : {
    "number" : "5.4.0",
    "build_hash" : "780f8c4",
    "build_date" : "2017-04-28T17:43:27.229Z",
    "build_snapshot" : false,
    "lucene_version" : "6.5.0"
  },
  "tagline" : "You Know, for Search"
}
```

Or if one wants to see cluster information:

```
curl http://10.100.75.158:9200/_cluster/health?pretty
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

<a id="helm">

## Deploying with Helm

[Helm](https://github.com/kubernetes/helm) charts for a basic (non-stateful) ElasticSearch deployment are maintained at https://github.com/clockworksoul/helm-elasticsearch. With Helm properly installed and configured, standing up a complete cluster is almost trivial:

```
$ git clone git@github.com:clockworksoul/helm-elasticsearch.git
$ helm install helm-elasticsearch
```

<a id="plugins">

## Install plug-ins

The image used in this repo is very minimalist. However, one can install additional plug-ins at will by simply specifying the `ES_PLUGINS_INSTALL` environment variable in the desired pod descriptors. For instance, to install Google Cloud Storage and X-Pack plug-ins it would be like follows:
```yaml
- name: "ES_PLUGINS_INSTALL"
  value: "repository-gcs,x-pack"
```

<a id="curator">

## Clean up with Curator

Additionally, one can run a [CronJob](http://kubernetes.io/docs/user-guide/cron-jobs/) that will periodically run [Curator](https://github.com/elastic/curator) to clean up indices (or do other actions on the Elasticsearch cluster).

```
kubectl create -f es-curator-config.yaml
kubectl create -f es-curator.yaml
```

Please, confirm the job has been created.

```
$ kubectl get cronjobs
NAME      SCHEDULE    SUSPEND   ACTIVE    LAST-SCHEDULE
curator   1 0 * * *   False     0         <none>
```

The job is configured to run once a day at _1 minute past midnight and delete indices that are older than 3 days_.

**Notes**

- One can change the schedule by editing the cron notation in `es-curator.yaml`.
- One can change the action (e.g. delete older than 3 days) by editing the `es-curator-config.yaml`.
- The definition of the `action_file.yaml` is quite self-explaining for simple set-ups. For more advanced configuration options, please consult the [Curator Documentation](https://www.elastic.co/guide/en/elasticsearch/client/curator/current/index.html).

If one wants to remove the curator job, just run:

```
kubectl delete cronjob curator
kubectl delete configmap curator-config
```

Various parameters of the cluster, including replica count and memory allocations, can be adjusted by editing the `helm-elasticsearch/values.yaml` file. For information about Helm, please consult the [complete Helm documentation](https://github.com/kubernetes/helm/blob/master/docs/index.md).

## FAQ

### Why does `NUMBER_OF_MASTERS` differ from number of master-replicas?
The default value for this environment variable is 2, meaning a cluster will need a minimum of 2 master nodes to operate. If a cluster has 3 masters and one dies, the cluster still works. Minimum master nodes are usually `n/2 + 1`, where `n` is the number of master nodes in a cluster. If a cluster has 5 master nodes, one should have a minimum of 3, less than that and the cluster _stops_. If one scales the number of masters, make sure to update the minimum number of master nodes through the Elasticsearch API as setting environment variable will only work on cluster setup. More info: https://www.elastic.co/guide/en/elasticsearch/guide/1.x/_important_configuration_changes.html#_minimum_master_nodes


### How can I customize `elasticsearch.yaml`?
Read a different config file by settings env var `path.conf=/path/to/my/config/`. Another option would be to build one's own image from  [this repository](https://github.com/pires/docker-elasticsearch-kubernetes)

## Troubleshooting
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
  value: "_eth0_" #_p1p1_ if interface name is p1p1, ens4 would be _ens4_, etc
```