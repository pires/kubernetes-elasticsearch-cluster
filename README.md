# kubernetes-elasticsearch-cluster
Elasticsearch (5.5.2) cluster on top of Kubernetes made easy.

### Table of Contents

* [Important Notes](#important-notes)
* [Pre-Requisites](#pre-requisites)
* [Build-Images(optional)](#build-images)
* [Test (deploying & accessing)](#test)
* [Pod anti-affinity](#pod-anti-affinity)
* [Deploying with Helm](#helm)
* [Install plug-ins](#plugins)
* [Clean up with Curator](#curator)
* [Deploy Kibana](#kibana)
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

* Kubernetes cluster with **alpha features enabled** (tested with v1.7.2 on top of [Vagrant + CoreOS](https://github.com/pires/kubernetes-vagrant-coreos-cluster))
* `kubectl` configured to access the cluster master API Server

<a id="build-images">

## Build images (optional)

Providing one's own version of [the images automatically built from this repository](https://github.com/pires/docker-elasticsearch-kubernetes) will not be supported. This is an *optional* step. One has been warned.

## Test

### Deploy

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
svc/elasticsearch             10.100.68.102   <pending>     9200:30536/TCP   2m
svc/elasticsearch-discovery   10.100.98.9     <none>        9300/TCP         2m
svc/kubernetes                10.100.0.1      <none>        443/TCP          14m

NAME               DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/es-client   2         2         2            2           49s
deploy/es-data     2         2         2            2           48s
deploy/es-master   3         3         3            3           2m

NAME                            READY     STATUS    RESTARTS   AGE
po/es-client-3159607856-cj49h   1/1       Running   0          49s
po/es-client-3159607856-g54pg   1/1       Running   0          49s
po/es-data-1222765614-1lzz6     1/1       Running   0          48s
po/es-data-1222765614-j10lj     1/1       Running   0          48s
po/es-master-3966308282-2qdbc   1/1       Running   0          2m
po/es-master-3966308282-hd6zh   1/1       Running   0          2m
po/es-master-3966308282-tvx67   1/1       Running   0          2m
```

```
$ kubectl logs po/es-master-3966308282-2qdbc
[2017-07-31T10:13:04,506][INFO ][o.e.n.Node               ] [es-master-3966308282-2qdbc] initializing ...
[2017-07-31T10:13:04,665][INFO ][o.e.e.NodeEnvironment    ] [es-master-3966308282-2qdbc] using [1] data paths, mounts [[/data (/dev/sda9)]], net usable_space [13.6gb], net total_space [15.5gb], spins? [possibly], types [ext4]
[2017-07-31T10:13:04,666][INFO ][o.e.e.NodeEnvironment    ] [es-master-3966308282-2qdbc] heap size [247.5mb], compressed ordinary object pointers [true]
[2017-07-31T10:13:04,669][INFO ][o.e.n.Node               ] [es-master-3966308282-2qdbc] node name [es-master-3966308282-2qdbc], node ID [FtuYCvAATJyXg6suftszIw]
[2017-07-31T10:13:04,671][INFO ][o.e.n.Node               ] [es-master-3966308282-2qdbc] version[5.5.1], pid[20], build[19c13d0/2017-07-18T20:44:24.823Z], OS[Linux/4.12.2-coreos/amd64], JVM[Oracle Corporation/OpenJDK 64-Bit Server VM/1.8.0_131/25.131-b11]
[2017-07-31T10:13:04,671][INFO ][o.e.n.Node               ] [es-master-3966308282-2qdbc] JVM arguments [-XX:+UseConcMarkSweepGC, -XX:CMSInitiatingOccupancyFraction=75, -XX:+UseCMSInitiatingOccupancyOnly, -XX:+DisableExplicitGC, -XX:+AlwaysPreTouch, -Xss1m, -Djava.awt.headless=true, -Dfile.encoding=UTF-8, -Djna.nosys=true, -Djdk.io.permissionsUseCanonicalPath=true, -Dio.netty.noUnsafe=true, -Dio.netty.noKeySetOptimization=true, -Dlog4j.shutdownHookEnabled=false, -Dlog4j2.disable.jmx=true, -Dlog4j.skipJansi=true, -XX:+HeapDumpOnOutOfMemoryError, -Xms256m, -Xmx256m, -Des.path.home=/elasticsearch]
[2017-07-31T10:13:05,971][INFO ][o.e.p.PluginsService     ] [es-master-3966308282-2qdbc] loaded module [aggs-matrix-stats]
[2017-07-31T10:13:05,971][INFO ][o.e.p.PluginsService     ] [es-master-3966308282-2qdbc] loaded module [ingest-common]
[2017-07-31T10:13:05,971][INFO ][o.e.p.PluginsService     ] [es-master-3966308282-2qdbc] loaded module [lang-expression]
[2017-07-31T10:13:05,972][INFO ][o.e.p.PluginsService     ] [es-master-3966308282-2qdbc] loaded module [lang-groovy]
[2017-07-31T10:13:05,972][INFO ][o.e.p.PluginsService     ] [es-master-3966308282-2qdbc] loaded module [lang-mustache]
[2017-07-31T10:13:05,972][INFO ][o.e.p.PluginsService     ] [es-master-3966308282-2qdbc] loaded module [lang-painless]
[2017-07-31T10:13:05,973][INFO ][o.e.p.PluginsService     ] [es-master-3966308282-2qdbc] loaded module [parent-join]
[2017-07-31T10:13:05,973][INFO ][o.e.p.PluginsService     ] [es-master-3966308282-2qdbc] loaded module [percolator]
[2017-07-31T10:13:05,973][INFO ][o.e.p.PluginsService     ] [es-master-3966308282-2qdbc] loaded module [reindex]
[2017-07-31T10:13:05,974][INFO ][o.e.p.PluginsService     ] [es-master-3966308282-2qdbc] loaded module [transport-netty3]
[2017-07-31T10:13:05,974][INFO ][o.e.p.PluginsService     ] [es-master-3966308282-2qdbc] loaded module [transport-netty4]
[2017-07-31T10:13:05,975][INFO ][o.e.p.PluginsService     ] [es-master-3966308282-2qdbc] no plugins loaded
[2017-07-31T10:13:08,733][INFO ][o.e.d.DiscoveryModule    ] [es-master-3966308282-2qdbc] using discovery type [zen]
[2017-07-31T10:13:09,613][INFO ][o.e.n.Node               ] [es-master-3966308282-2qdbc] initialized
[2017-07-31T10:13:09,613][INFO ][o.e.n.Node               ] [es-master-3966308282-2qdbc] starting ...
[2017-07-31T10:13:09,869][INFO ][o.e.t.TransportService   ] [es-master-3966308282-2qdbc] publish_address {10.244.23.2:9300}, bound_addresses {10.244.23.2:9300}
[2017-07-31T10:13:09,898][INFO ][o.e.b.BootstrapChecks    ] [es-master-3966308282-2qdbc] bound or publishing to a non-loopback or non-link-local address, enforcing bootstrap checks
[2017-07-31T10:13:12,978][WARN ][o.e.d.z.ZenDiscovery     ] [es-master-3966308282-2qdbc] not enough master nodes discovered during pinging (found [[Candidate{node={es-master-3966308282-2qdbc}{FtuYCvAATJyXg6suftszIw}{bTlVUi-QRd-8-ix42LvpwA}{10.244.23.2}{10.244.23.2:9300}, clusterStateVersion=-1}]], but needed [2]), pinging again
[2017-07-31T10:13:15,980][WARN ][o.e.d.z.ZenDiscovery     ] [es-master-3966308282-2qdbc] not enough master nodes discovered during pinging (found [[Candidate{node={es-master-3966308282-2qdbc}{FtuYCvAATJyXg6suftszIw}{bTlVUi-QRd-8-ix42LvpwA}{10.244.23.2}{10.244.23.2:9300}, clusterStateVersion=-1}]], but needed [2]), pinging again
[2017-07-31T10:13:19,125][INFO ][o.e.c.s.ClusterService   ] [es-master-3966308282-2qdbc] detected_master {es-master-3966308282-hd6zh}{ewftNOzOQy2elVEPoTnqIA}{YXHme-qySgG0QmAvr-pwkA}{10.244.21.3}{10.244.21.3:9300}, added {{es-master-3966308282-tvx67}{wAUf_fUGRam0pkS2lm_yeg}{PNhDfm1pQE26BMIsZ3EaXw}{10.244.16.2}{10.244.16.2:9300},{es-master-3966308282-hd6zh}{ewftNOzOQy2elVEPoTnqIA}{YXHme-qySgG0QmAvr-pwkA}{10.244.21.3}{10.244.21.3:9300},}, reason: zen-disco-receive(from master [master {es-master-3966308282-hd6zh}{ewftNOzOQy2elVEPoTnqIA}{YXHme-qySgG0QmAvr-pwkA}{10.244.21.3}{10.244.21.3:9300} committed version [3]])
[2017-07-31T10:13:19,183][INFO ][o.e.n.Node               ] [es-master-3966308282-2qdbc] started
[2017-07-31T10:14:29,497][INFO ][o.e.c.s.ClusterService   ] [es-master-3966308282-2qdbc] added {{es-client-3159607856-cj49h}{t_IDXER9S-eMzi9fMftZFQ}{iVlxbMVHQAye84oi2bjz-A}{10.244.23.3}{10.244.23.3:9300},}, reason: zen-disco-receive(from master [master {es-master-3966308282-hd6zh}{ewftNOzOQy2elVEPoTnqIA}{YXHme-qySgG0QmAvr-pwkA}{10.244.21.3}{10.244.21.3:9300} committed version [4]])
[2017-07-31T10:14:29,703][INFO ][o.e.c.s.ClusterService   ] [es-master-3966308282-2qdbc] added {{es-data-1222765614-j10lj}{1ZPKoD2yTTm-ggL6kBGl1w}{-KB__GUTTaiGs1aeLl4ceg}{10.244.16.3}{10.244.16.3:9300},}, reason: zen-disco-receive(from master [master {es-master-3966308282-hd6zh}{ewftNOzOQy2elVEPoTnqIA}{YXHme-qySgG0QmAvr-pwkA}{10.244.21.3}{10.244.21.3:9300} committed version [5]])
[2017-07-31T10:14:34,872][INFO ][o.e.c.s.ClusterService   ] [es-master-3966308282-2qdbc] added {{es-client-3159607856-g54pg}{QW3IbBR6Qkuu0qfsvBWukQ}{-pM_D-5_Rwuo9xb_gxiKnQ}{10.244.21.4}{10.244.21.4:9300},}, reason: zen-disco-receive(from master [master {es-master-3966308282-hd6zh}{ewftNOzOQy2elVEPoTnqIA}{YXHme-qySgG0QmAvr-pwkA}{10.244.21.3}{10.244.21.3:9300} committed version [6]])
[2017-07-31T10:14:36,975][INFO ][o.e.c.s.ClusterService   ] [es-master-3966308282-2qdbc] added {{es-data-1222765614-1lzz6}{wtCzgKPMRLm4zut8qYi0Bg}{JHSDg3huQAu04OXiWO_6rA}{10.244.21.5}{10.244.21.5:9300},}, reason: zen-disco-receive(from master [master {es-master-3966308282-hd6zh}{ewftNOzOQy2elVEPoTnqIA}{YXHme-qySgG0QmAvr-pwkA}{10.244.21.3}{10.244.21.3:9300} committed version [7]])
```

As we can assert, the cluster is up and running. Easy, wasn't it?

### Access the service

*Don't forget* that services in Kubernetes are only acessible from containers in the cluster. For different behavior one should [configure the creation of an external load-balancer](http://kubernetes.io/v1.1/docs/user-guide/services.html#type-loadbalancer). While it's supported within this example service descriptor, its usage is out of scope of this document, for now.

```
$ kubectl get svc elasticsearch
NAME            CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
elasticsearch   10.100.68.102   <pending>     9200:30536/TCP   3m
```

From any host on the Kubernetes cluster (that's running `kube-proxy` or similar), run:

```
curl http://10.100.68.102:9200
```

One should see something similar to the following:

```json
{
  "name" : "es-client-3159607856-cj49h",
  "cluster_name" : "myesdb",
  "cluster_uuid" : "m0jm8ASlSaKOS0wT52R5cA",
  "version" : {
    "number" : "5.5.1",
    "build_hash" : "19c13d0",
    "build_date" : "2017-07-18T20:44:24.823Z",
    "build_snapshot" : false,
    "lucene_version" : "6.6.0"
  },
  "tagline" : "You Know, for Search"
}
```

Or if one wants to see cluster information:

```
curl http://10.100.68.102:9200/_cluster/health?pretty
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
            - key: role
              operator: In
              values:
              - data
          topologyKey: kubernetes.io/hostname
  containers:
  - (...)
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

<a id="kibana>

## Kibana

Additionally, one can also add Kibana to the mix. In order to do so, one must use a container image of Kibana without x-pack,
as it's not supported by the Elasticsearch container images used in this repository.

An image is already provided but one can build their own like follows:

```
FROM docker.elastic.co/kibana/kibana:5.5.1
RUN bin/kibana-plugin remove x-pack
```

If ones does provide their own image, one must make sure to alter the following files before deploying:

```
kubectl create -f kibana.yaml
kubectl create -f kibana-svc.yaml
```

Kibana will be available through service `kibana`, and one will be able to access it from within the cluster or
proxy it through the Kubernetes API Server, as follows:

```
https://<API_SERVER_URL>/api/v1/proxy/namespaces/default/services/kibana/proxy
```

One can also create an Ingress to expose the service publicly or simly use the service nodeport.
In the case one proceeds to do so, one must change the environment variable `SERVER_BASEPATH` to the match their environment.

## FAQ

### Why does `NUMBER_OF_MASTERS` differ from number of master-replicas?
The default value for this environment variable is 2, meaning a cluster will need a minimum of 2 master nodes to operate. If a cluster has 3 masters and one dies, the cluster still works. Minimum master nodes are usually `n/2 + 1`, where `n` is the number of master nodes in a cluster. If a cluster has 5 master nodes, one should have a minimum of 3, less than that and the cluster _stops_. If one scales the number of masters, make sure to update the minimum number of master nodes through the Elasticsearch API as setting environment variable will only work on cluster setup. More info: https://www.elastic.co/guide/en/elasticsearch/guide/1.x/_important_configuration_changes.html#_minimum_master_nodes


### How can I customize `elasticsearch.yaml`?
Read a different config file by settings env var `path.conf=/path/to/my/config/`. Another option would be to build one's own image from  [this repository](https://github.com/pires/docker-elasticsearch-kubernetes)

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
