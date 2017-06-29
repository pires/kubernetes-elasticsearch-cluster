# kubernetes-elasticsearch-cluster
Elasticsearch (5.4.3) cluster on top of Kubernetes made easy.

### Table of Contents

* [Important Notes](#important-notes)
* [Pre-Requisites](#pre-requisites)
* [Build-Images(optional)](#build-images)
* [Test (deploying & accessing)](#test)
* [Pod anti-affinity](#pod-anti-affinity)
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

* Kubernetes cluster with **alpha features enabled** (tested with v1.6.6 on top of [Vagrant + CoreOS](https://github.com/pires/kubernetes-vagrant-coreos-cluster))
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
NAME                          CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
svc/elasticsearch             10.100.254.59    <pending>     9200:30372/TCP   4m
svc/elasticsearch-discovery   10.100.137.209   <none>        9300/TCP         4m
svc/kubernetes                10.100.0.1       <none>        443/TCP          24m

NAME               DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/es-client   2         2         2            2           2m
deploy/es-data     2         2         2            2           1m
deploy/es-master   3         3         3            3           4m

NAME                            READY     STATUS    RESTARTS   AGE
po/es-client-3752325057-68zl4   1/1       Running   0          2m
po/es-client-3752325057-rxk8p   1/1       Running   0          2m
po/es-data-2088356535-kdsk8     1/1       Running   0          1m
po/es-data-2088356535-qbsrc     1/1       Running   0          1m
po/es-master-2805466080-9j3zn   1/1       Running   0          4m
po/es-master-2805466080-fmjxw   1/1       Running   0          4m
po/es-master-2805466080-g7hr5   1/1       Running   0          4m
```

```
$ kubectl logs po/es-master-2805466080-9j3zn
[2017-06-29T08:59:38,312][INFO ][o.e.n.Node               ] [es-master-2805466080-9j3zn] initializing ...
[2017-06-29T08:59:38,386][INFO ][o.e.e.NodeEnvironment    ] [es-master-2805466080-9j3zn] using [1] data paths, mounts [[/data (/dev/sda9)]], net usable_space [13.6gb], net total_space [15.5gb], spins? [possibly], types [ext4]
[2017-06-29T08:59:38,386][INFO ][o.e.e.NodeEnvironment    ] [es-master-2805466080-9j3zn] heap size [247.5mb], compressed ordinary object pointers [true]
[2017-06-29T08:59:38,387][INFO ][o.e.n.Node               ] [es-master-2805466080-9j3zn] node name [es-master-2805466080-9j3zn], node ID [5-zQyCurSoCBSNp1dJJFpg]
[2017-06-29T08:59:38,387][INFO ][o.e.n.Node               ] [es-master-2805466080-9j3zn] version[5.4.3], pid[10], build[eed30a8/2017-06-22T00:34:03.743Z], OS[Linux/4.11.6-coreos-r1/amd64], JVM[Oracle Corporation/OpenJDK 64-Bit Server VM/1.8.0_131/25.131-b11]
[2017-06-29T08:59:38,387][INFO ][o.e.n.Node               ] [es-master-2805466080-9j3zn] JVM arguments [-XX:+UseConcMarkSweepGC, -XX:CMSInitiatingOccupancyFraction=75, -XX:+UseCMSInitiatingOccupancyOnly, -XX:+DisableExplicitGC, -XX:+AlwaysPreTouch, -Xss1m, -Djava.awt.headless=true, -Dfile.encoding=UTF-8, -Djna.nosys=true, -Djdk.io.permissionsUseCanonicalPath=true, -Dio.netty.noUnsafe=true, -Dio.netty.noKeySetOptimization=true, -Dlog4j.shutdownHookEnabled=false, -Dlog4j2.disable.jmx=true, -Dlog4j.skipJansi=true, -XX:+HeapDumpOnOutOfMemoryError, -Xms256m, -Xmx256m, -Des.path.home=/elasticsearch]
[2017-06-29T08:59:39,135][INFO ][o.e.p.PluginsService     ] [es-master-2805466080-9j3zn] loaded module [aggs-matrix-stats]
[2017-06-29T08:59:39,136][INFO ][o.e.p.PluginsService     ] [es-master-2805466080-9j3zn] loaded module [ingest-common]
[2017-06-29T08:59:39,136][INFO ][o.e.p.PluginsService     ] [es-master-2805466080-9j3zn] loaded module [lang-expression]
[2017-06-29T08:59:39,136][INFO ][o.e.p.PluginsService     ] [es-master-2805466080-9j3zn] loaded module [lang-groovy]
[2017-06-29T08:59:39,136][INFO ][o.e.p.PluginsService     ] [es-master-2805466080-9j3zn] loaded module [lang-mustache]
[2017-06-29T08:59:39,136][INFO ][o.e.p.PluginsService     ] [es-master-2805466080-9j3zn] loaded module [lang-painless]
[2017-06-29T08:59:39,136][INFO ][o.e.p.PluginsService     ] [es-master-2805466080-9j3zn] loaded module [percolator]
[2017-06-29T08:59:39,136][INFO ][o.e.p.PluginsService     ] [es-master-2805466080-9j3zn] loaded module [reindex]
[2017-06-29T08:59:39,137][INFO ][o.e.p.PluginsService     ] [es-master-2805466080-9j3zn] loaded module [transport-netty3]
[2017-06-29T08:59:39,137][INFO ][o.e.p.PluginsService     ] [es-master-2805466080-9j3zn] loaded module [transport-netty4]
[2017-06-29T08:59:39,137][INFO ][o.e.p.PluginsService     ] [es-master-2805466080-9j3zn] no plugins loaded
[2017-06-29T08:59:40,871][INFO ][o.e.d.DiscoveryModule    ] [es-master-2805466080-9j3zn] using discovery type [zen]
[2017-06-29T08:59:41,326][INFO ][o.e.n.Node               ] [es-master-2805466080-9j3zn] initialized
[2017-06-29T08:59:41,327][INFO ][o.e.n.Node               ] [es-master-2805466080-9j3zn] starting ...
[2017-06-29T08:59:41,496][INFO ][o.e.t.TransportService   ] [es-master-2805466080-9j3zn] publish_address {10.244.12.3:9300}, bound_addresses {10.244.12.3:9300}
[2017-06-29T08:59:41,506][INFO ][o.e.b.BootstrapChecks    ] [es-master-2805466080-9j3zn] bound or publishing to a non-loopback or non-link-local address, enforcing bootstrap checks
[2017-06-29T08:59:44,574][INFO ][o.e.c.s.ClusterService   ] [es-master-2805466080-9j3zn] new_master {es-master-2805466080-9j3zn}{5-zQyCurSoCBSNp1dJJFpg}{ZtbPR2deRBq_ku1WKWioDA}{10.244.12.3}{10.244.12.3:9300}, added {{es-master-2805466080-g7hr5}{jldvP1AGThmwIezAvh3Psw}{oazHv7x0SJS_B29sI1ntlQ}{10.244.22.2}{10.244.22.2:9300},}, reason: zen-disco-elected-as-master ([1] nodes joined)[{es-master-2805466080-g7hr5}{jldvP1AGThmwIezAvh3Psw}{oazHv7x0SJS_B29sI1ntlQ}{10.244.22.2}{10.244.22.2:9300}]
[2017-06-29T08:59:44,630][INFO ][o.e.n.Node               ] [es-master-2805466080-9j3zn] started
[2017-06-29T08:59:44,696][INFO ][o.e.g.GatewayService     ] [es-master-2805466080-9j3zn] recovered [0] indices into cluster_state
[2017-06-29T09:00:14,008][INFO ][o.e.c.s.ClusterService   ] [es-master-2805466080-9j3zn] added {{es-master-2805466080-fmjxw}{PtSOK-yhQ4uO38IsDGUbjA}{2_pmZFotQn6inISk-HKHnQ}{10.244.74.2}{10.244.74.2:9300},}, reason: zen-disco-node-join[{es-master-2805466080-fmjxw}{PtSOK-yhQ4uO38IsDGUbjA}{2_pmZFotQn6inISk-HKHnQ}{10.244.74.2}{10.244.74.2:9300}]
[2017-06-29T09:00:48,629][INFO ][o.e.c.s.ClusterService   ] [es-master-2805466080-9j3zn] added {{es-client-3752325057-68zl4}{8XZe4xpgSa6hy4nhQ3Ejkw}{G4EJG0W5RoqCBMbkv53IFQ}{10.244.12.4}{10.244.12.4:9300},}, reason: zen-disco-node-join[{es-client-3752325057-68zl4}{8XZe4xpgSa6hy4nhQ3Ejkw}{G4EJG0W5RoqCBMbkv53IFQ}{10.244.12.4}{10.244.12.4:9300}]
[2017-06-29T09:00:49,202][INFO ][o.e.c.s.ClusterService   ] [es-master-2805466080-9j3zn] added {{es-client-3752325057-rxk8p}{cV3b-TyyQ7m5wK-mnazBRQ}{tcEEmpP9RgOC2GzKkuYMnw}{10.244.22.3}{10.244.22.3:9300},}, reason: zen-disco-node-join[{es-client-3752325057-rxk8p}{cV3b-TyyQ7m5wK-mnazBRQ}{tcEEmpP9RgOC2GzKkuYMnw}{10.244.22.3}{10.244.22.3:9300}]
[2017-06-29T09:01:24,633][INFO ][o.e.c.s.ClusterService   ] [es-master-2805466080-9j3zn] added {{es-data-2088356535-qbsrc}{7N4EZhVIQC6f3a_3m66ETQ}{AYxuAIthScy40LRK1EzeXQ}{10.244.74.3}{10.244.74.3:9300},}, reason: zen-disco-node-join[{es-data-2088356535-qbsrc}{7N4EZhVIQC6f3a_3m66ETQ}{AYxuAIthScy40LRK1EzeXQ}{10.244.74.3}{10.244.74.3:9300}]
[2017-06-29T09:01:25,971][INFO ][o.e.c.s.ClusterService   ] [es-master-2805466080-9j3zn] added {{es-data-2088356535-kdsk8}{qAmcpDd5TA-SoBmD_Rmpcw}{3EhKm8e1SWq5OulNpa6TZA}{10.244.12.5}{10.244.12.5:9300},}, reason: zen-disco-node-join[{es-data-2088356535-kdsk8}{qAmcpDd5TA-SoBmD_Rmpcw}{3EhKm8e1SWq5OulNpa6TZA}{10.244.12.5}{10.244.12.5:9300}]
```

As we can assert, the cluster is up and running. Easy, wasn't it?

### Access the service

*Don't forget* that services in Kubernetes are only acessible from containers in the cluster. For different behavior one should [configure the creation of an external load-balancer](http://kubernetes.io/v1.1/docs/user-guide/services.html#type-loadbalancer). While it's supported within this example service descriptor, its usage is out of scope of this document, for now.

```
$ kubectl get svc elasticsearch
NAME            CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
elasticsearch   10.100.254.59   <pending>     9200:30372/TCP   5m
```

From any host on the Kubernetes cluster (that's running `kube-proxy` or similar), run:

```
curl http://10.100.254.59:9200
```

One should see something similar to the following:

```json
{
  "name" : "es-client-3752325057-68zl4",
  "cluster_name" : "myesdb",
  "cluster_uuid" : "fwGbC7FnTGmRL9200RPVPA",
  "version" : {
    "number" : "5.4.3",
    "build_hash" : "eed30a8",
    "build_date" : "2017-06-22T00:34:03.743Z",
    "build_snapshot" : false,
    "lucene_version" : "6.5.1"
  },
  "tagline" : "You Know, for Search"
}
```

Or if one wants to see cluster information:

```
curl http://10.100.254.59:9200/_cluster/health?pretty
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