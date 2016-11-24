# kubernetes-elasticsearch-cluster
Elasticsearch (5.0.1) cluster on top of Kubernetes made easy.

Elasticsearch best-practices recommend to separate nodes in three roles:
* `Master` nodes - intended for clustering management only, no data, no HTTP API
* `Client` nodes - intended for client usage, no data, with HTTP API
* `Data` nodes - intended for storing and indexing your data, no HTTP API

Given this, I'm hereby making possible for you to scale as needed. For instance, a good strong scenario could be 3 master, 2 client, 5 data nodes.

## (Very) Important notes

* By default, `ES_JAVA_OPTS` is set to `-Xms256m -Xmx256m`. This is a *very low* value but many users, i.e. `minikube` users, were having issues with pods getting killed because hosts were out of memory.
You can change this yourself in the deployment descriptors available in this repository.

* As of the moment, Kubernetes pod descriptors use an `emptyDir` for storing data in each data node container. This is meant to be for the sake of simplicity and should be adapted according to your storage needs.

## Pre-requisites

* Kubernetes cluster (tested with v1.4.6 on top of [Vagrant + CoreOS](https://github.com/pires/kubernetes-vagrant-coreos-cluster))
* `kubectl` configured to access your cluster master API Server

## Build images (optional)

Providing your own version of [the images automatically built from this repository](https://github.com/pires/docker-elasticsearch-kubernetes) will not be supported. This is an *optional* step. You have been warned.

## Test

### Deploy

```
kubectl create -f es-discovery-svc.yaml
kubectl create -f es-svc.yaml
kubectl create -f es-master.yaml
```

Wait until `es-master` is provisioned, and

```
kubectl create -f es-client.yaml
```

Wait until `es-client` is provisioned, and

```
kubectl create -f es-data.yaml
```

Wait until `es-data` is provisioned.

Now, I leave up to you how to validate the cluster, but a first step is to wait for containers to be in the `Running` state and check Elasticsearch master logs:

```
$ kubectl get svc,deployment,pods
NAME                          CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
svc/elasticsearch             10.100.68.199    <pending>     9200/TCP   12m
svc/elasticsearch-discovery   10.100.195.104   <none>        9300/TCP   12m
svc/kubernetes                10.100.0.1       <none>        443/TCP    19m
NAME               DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/es-client   1         1         1            1           9m
deploy/es-data     1         1         1            1           9m
deploy/es-master   1         1         1            1           12m
NAME                            READY     STATUS    RESTARTS   AGE
po/es-client-2550992941-cnf80   1/1       Running   0          9m
po/es-data-3644975745-6n2pb     1/1       Running   0          9m
po/es-master-2175404059-oeqt6   1/1       Running   0          12m
```

```
$ kubectl logs -f es-master-2175404059-oeqt6
[2016-11-24T15:32:40,692][WARN ][o.e.c.l.LogConfigurator  ] ignoring unsupported logging configuration file [/elasticsearch/config/logging.yml], logging is configured via [/elasticsearch/config/log4j2.properties]
[2016-11-24T15:32:41,242][INFO ][o.e.n.Node               ] [] initializing ...
[2016-11-24T15:32:41,401][INFO ][o.e.e.NodeEnvironment    ] [3Um_aVf] using [1] data paths, mounts [[/data (/dev/sda9)]], net usable_space [13.7gb], net total_space [15.5gb], spins? [possibly], types [ext4]
[2016-11-24T15:32:41,403][INFO ][o.e.e.NodeEnvironment    ] [3Um_aVf] heap size [247.5mb], compressed ordinary object pointers [true]
[2016-11-24T15:32:41,406][INFO ][o.e.n.Node               ] [3Um_aVf] node name [3Um_aVf] derived from node ID; set [node.name] to override
[2016-11-24T15:32:41,410][INFO ][o.e.n.Node               ] [3Um_aVf] version[5.0.1], pid[12], build[080bb47/2016-11-11T22:08:49.812Z], OS[Linux/4.8.6-coreos/amd64], JVM[Oracle Corporation/OpenJDK 64-Bit Server VM/1.8.0_111-internal/25.111-b14]
[2016-11-24T15:32:43,402][INFO ][o.e.p.PluginsService     ] [3Um_aVf] loaded module [aggs-matrix-stats]
[2016-11-24T15:32:43,402][INFO ][o.e.p.PluginsService     ] [3Um_aVf] loaded module [ingest-common]
[2016-11-24T15:32:43,402][INFO ][o.e.p.PluginsService     ] [3Um_aVf] loaded module [lang-expression]
[2016-11-24T15:32:43,403][INFO ][o.e.p.PluginsService     ] [3Um_aVf] loaded module [lang-groovy]
[2016-11-24T15:32:43,403][INFO ][o.e.p.PluginsService     ] [3Um_aVf] loaded module [lang-mustache]
[2016-11-24T15:32:43,403][INFO ][o.e.p.PluginsService     ] [3Um_aVf] loaded module [lang-painless]
[2016-11-24T15:32:43,404][INFO ][o.e.p.PluginsService     ] [3Um_aVf] loaded module [percolator]
[2016-11-24T15:32:43,404][INFO ][o.e.p.PluginsService     ] [3Um_aVf] loaded module [reindex]
[2016-11-24T15:32:43,404][INFO ][o.e.p.PluginsService     ] [3Um_aVf] loaded module [transport-netty3]
[2016-11-24T15:32:43,404][INFO ][o.e.p.PluginsService     ] [3Um_aVf] loaded module [transport-netty4]
[2016-11-24T15:32:43,405][INFO ][o.e.p.PluginsService     ] [3Um_aVf] loaded plugin [discovery-kubernetes]
[2016-11-24T15:32:47,345][INFO ][o.e.n.Node               ] [3Um_aVf] initialized
[2016-11-24T15:32:47,346][INFO ][o.e.n.Node               ] [3Um_aVf] starting ...
[2016-11-24T15:32:47,643][INFO ][o.e.t.TransportService   ] [3Um_aVf] publish_address {10.244.29.2:9300}, bound_addresses {10.244.29.2:9300}
[2016-11-24T15:32:47,654][INFO ][o.e.b.BootstrapCheck     ] [3Um_aVf] bound or publishing to a non-loopback or non-link-local address, enforcing bootstrap checks
SLF4J: Failed to load class "org.slf4j.impl.StaticLoggerBinder".
SLF4J: Defaulting to no-operation (NOP) logger implementation
SLF4J: See http://www.slf4j.org/codes.html#StaticLoggerBinder for further details.
[2016-11-24T15:32:52,132][INFO ][o.e.c.s.ClusterService   ] [3Um_aVf] new_master {3Um_aVf}{3Um_aVfwSJqeThuCkyUGoQ}{i-DJtjTxTQWs-l6sNKR9yQ}{10.244.29.2}{10.244.29.2:9300}, reason: zen-disco-elected-as-master ([0] nodes joined)
[2016-11-24T15:32:52,154][INFO ][o.e.n.Node               ] [3Um_aVf] started
[2016-11-24T15:32:52,234][INFO ][o.e.g.GatewayService     ] [3Um_aVf] recovered [0] indices into cluster_state
[2016-11-24T15:34:37,237][INFO ][o.e.c.s.ClusterService   ] [3Um_aVf] added {{BXq2wbe}{BXq2wbeEQMC4FOLb_L89kA}{t3wQ3vQeQGCrc8JCbOawmw}{10.244.29.3}{10.244.29.3:9300},}, reason: zen-disco-node-join[{BXq2wbe}{BXq2wbeEQMC4FOLb_L89kA}{t3wQ3vQeQGCrc8JCbOawmw}{10.244.29.3}{10.244.29.3:9300}]
[2016-11-24T15:35:07,195][INFO ][o.e.c.s.ClusterService   ] [3Um_aVf] added {{neU0DK_}{neU0DK_5SC28_DzUlZJREw}{-kcaKr9RQZG7oNduymlCfg}{10.244.29.4}{10.244.29.4:9300},}, reason: zen-disco-node-join[{neU0DK_}{neU0DK_5SC28_DzUlZJREw}{-kcaKr9RQZG7oNduymlCfg}{10.244.29.4}{10.244.29.4:9300}]
```

As you can assert, the cluster is up and running. Easy, wasn't it?

### Scale

Scaling each type of node to handle your cluster is as easy as:

```
kubectl scale deployment es-master --replicas 3
kubectl scale deployment es-client --replicas 2
kubectl scale deployment es-data --replicas 2
```

Did it work?

```
$ kubectl get deployments,pods
NAME               DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/es-client   2         2         2            2           10m
deploy/es-data     2         2         2            2           11m
deploy/es-master   3         3         3            3           13m
NAME                            READY     STATUS    RESTARTS   AGE
po/es-client-2550992941-cnf80   1/1       Running   0          10m
po/es-client-2550992941-g4sm0   1/1       Running   0          2m
po/es-data-3644975745-6n2pb     1/1       Running   0          11m
po/es-data-3644975745-ixtrz     1/1       Running   0          2m
po/es-master-2175404059-mukmp   1/1       Running   0          5m
po/es-master-2175404059-oeqt6   1/1       Running   0          13m
po/es-master-2175404059-w53ze   1/1       Running   0          5m
```

Let's take another look at the logs of one of the Elasticsearch `master` nodes:

```
$ kubectl logs -f es-master-2175404059-oeqt6
[2016-11-24T15:32:40,692][WARN ][o.e.c.l.LogConfigurator  ] ignoring unsupported logging configuration file [/elasticsearch/config/logging.yml], logging is configured via [/elasticsearch/config/log4j2.properties]
[2016-11-24T15:32:41,242][INFO ][o.e.n.Node               ] [] initializing ...
[2016-11-24T15:32:41,401][INFO ][o.e.e.NodeEnvironment    ] [3Um_aVf] using [1] data paths, mounts [[/data (/dev/sda9)]], net usable_space [13.7gb], net total_space [15.5gb], spins? [possibly], types [ext4]
[2016-11-24T15:32:41,403][INFO ][o.e.e.NodeEnvironment    ] [3Um_aVf] heap size [247.5mb], compressed ordinary object pointers [true]
[2016-11-24T15:32:41,406][INFO ][o.e.n.Node               ] [3Um_aVf] node name [3Um_aVf] derived from node ID; set [node.name] to override
[2016-11-24T15:32:41,410][INFO ][o.e.n.Node               ] [3Um_aVf] version[5.0.1], pid[12], build[080bb47/2016-11-11T22:08:49.812Z], OS[Linux/4.8.6-coreos/amd64], JVM[Oracle Corporation/OpenJDK 64-Bit Server VM/1.8.0_111-internal/25.111-b14]
[2016-11-24T15:32:43,402][INFO ][o.e.p.PluginsService     ] [3Um_aVf] loaded module [aggs-matrix-stats]
[2016-11-24T15:32:43,402][INFO ][o.e.p.PluginsService     ] [3Um_aVf] loaded module [ingest-common]
[2016-11-24T15:32:43,402][INFO ][o.e.p.PluginsService     ] [3Um_aVf] loaded module [lang-expression]
[2016-11-24T15:32:43,403][INFO ][o.e.p.PluginsService     ] [3Um_aVf] loaded module [lang-groovy]
[2016-11-24T15:32:43,403][INFO ][o.e.p.PluginsService     ] [3Um_aVf] loaded module [lang-mustache]
[2016-11-24T15:32:43,403][INFO ][o.e.p.PluginsService     ] [3Um_aVf] loaded module [lang-painless]
[2016-11-24T15:32:43,404][INFO ][o.e.p.PluginsService     ] [3Um_aVf] loaded module [percolator]
[2016-11-24T15:32:43,404][INFO ][o.e.p.PluginsService     ] [3Um_aVf] loaded module [reindex]
[2016-11-24T15:32:43,404][INFO ][o.e.p.PluginsService     ] [3Um_aVf] loaded module [transport-netty3]
[2016-11-24T15:32:43,404][INFO ][o.e.p.PluginsService     ] [3Um_aVf] loaded module [transport-netty4]
[2016-11-24T15:32:43,405][INFO ][o.e.p.PluginsService     ] [3Um_aVf] loaded plugin [discovery-kubernetes]
[2016-11-24T15:32:47,345][INFO ][o.e.n.Node               ] [3Um_aVf] initialized
[2016-11-24T15:32:47,346][INFO ][o.e.n.Node               ] [3Um_aVf] starting ...
[2016-11-24T15:32:47,643][INFO ][o.e.t.TransportService   ] [3Um_aVf] publish_address {10.244.29.2:9300}, bound_addresses {10.244.29.2:9300}
[2016-11-24T15:32:47,654][INFO ][o.e.b.BootstrapCheck     ] [3Um_aVf] bound or publishing to a non-loopback or non-link-local address, enforcing bootstrap checks
SLF4J: Failed to load class "org.slf4j.impl.StaticLoggerBinder".
SLF4J: Defaulting to no-operation (NOP) logger implementation
SLF4J: See http://www.slf4j.org/codes.html#StaticLoggerBinder for further details.
[2016-11-24T15:32:52,132][INFO ][o.e.c.s.ClusterService   ] [3Um_aVf] new_master {3Um_aVf}{3Um_aVfwSJqeThuCkyUGoQ}{i-DJtjTxTQWs-l6sNKR9yQ}{10.244.29.2}{10.244.29.2:9300}, reason: zen-disco-elected-as-master ([0] nodes joined)
[2016-11-24T15:32:52,154][INFO ][o.e.n.Node               ] [3Um_aVf] started
[2016-11-24T15:32:52,234][INFO ][o.e.g.GatewayService     ] [3Um_aVf] recovered [0] indices into cluster_state
[2016-11-24T15:34:37,237][INFO ][o.e.c.s.ClusterService   ] [3Um_aVf] added {{BXq2wbe}{BXq2wbeEQMC4FOLb_L89kA}{t3wQ3vQeQGCrc8JCbOawmw}{10.244.29.3}{10.244.29.3:9300},}, reason: zen-disco-node-join[{BXq2wbe}{BXq2wbeEQMC4FOLb_L89kA}{t3wQ3vQeQGCrc8JCbOawmw}{10.244.29.3}{10.244.29.3:9300}]
[2016-11-24T15:35:07,195][INFO ][o.e.c.s.ClusterService   ] [3Um_aVf] added {{neU0DK_}{neU0DK_5SC28_DzUlZJREw}{-kcaKr9RQZG7oNduymlCfg}{10.244.29.4}{10.244.29.4:9300},}, reason: zen-disco-node-join[{neU0DK_}{neU0DK_5SC28_DzUlZJREw}{-kcaKr9RQZG7oNduymlCfg}{10.244.29.4}{10.244.29.4:9300}]
[2016-11-24T15:41:41,110][INFO ][o.e.c.s.ClusterService   ] [3Um_aVf] added {{yWjUQH0}{yWjUQH0bTFanpnXl7225-g}{9TqkmrGNSRifcUezTU5pUQ}{10.244.25.2}{10.244.25.2:9300},}, reason: zen-disco-node-join[{yWjUQH0}{yWjUQH0bTFanpnXl7225-g}{9TqkmrGNSRifcUezTU5pUQ}{10.244.25.2}{10.244.25.2:9300}]
[2016-11-24T15:41:41,296][WARN ][o.e.d.z.ElectMasterService] [3Um_aVf] value for setting "discovery.zen.minimum_master_nodes" is too low. This can result in data loss! Please set it to at least a quorum of master-eligible nodes (current value: [1], total number of master-eligible nodes used for publishing in this round: [2])
[2016-11-24T15:41:43,640][INFO ][o.e.c.s.ClusterService   ] [3Um_aVf] added {{JGQr1oJ}{JGQr1oJZQZahjltWE_9ulw}{hZgqYQEgQt6V2RqnHP_RWg}{10.244.74.2}{10.244.74.2:9300},}, reason: zen-disco-node-join[{JGQr1oJ}{JGQr1oJZQZahjltWE_9ulw}{hZgqYQEgQt6V2RqnHP_RWg}{10.244.74.2}{10.244.74.2:9300}]
[2016-11-24T15:42:59,613][INFO ][o.e.c.s.ClusterService   ] [3Um_aVf] added {{w4jwP5s}{w4jwP5sqS-e0c3gXl77SVw}{yO6PX1agSA-j_DxOeNP6EA}{10.244.74.3}{10.244.74.3:9300},}, reason: zen-disco-node-join[{w4jwP5s}{w4jwP5sqS-e0c3gXl77SVw}{yO6PX1agSA-j_DxOeNP6EA}{10.244.74.3}{10.244.74.3:9300}]
[2016-11-24T15:43:42,667][INFO ][o.e.c.s.ClusterService   ] [3Um_aVf] added {{hJvwghk}{hJvwghkOSzaWhXSzs9sTwA}{DhWgc6hYTnW-Sq57xCXZwg}{10.244.25.3}{10.244.25.3:9300},}, reason: zen-disco-node-join[{hJvwghk}{hJvwghkOSzaWhXSzs9sTwA}{DhWgc6hYTnW-Sq57xCXZwg}{10.244.25.3}{10.244.25.3:9300}]
```

### Access the service

*Don't forget* that services in Kubernetes are only acessible from containers in the cluster. For different behavior you should [configure the creation of an external load-balancer](http://kubernetes.io/v1.1/docs/user-guide/services.html#type-loadbalancer). While it's supported within this example service descriptor, its usage is out of scope of this document, for now.

```
$ kubectl get svc elasticsearch
NAME            CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
elasticsearch   10.100.68.199   <pending>     9200/TCP   14m
```

From any host on your cluster (that's running `kube-proxy`), run:

```
curl http://10.100.68.199:9200
```

You should see something similar to the following:

```json
{
  "name" : "neU0DK_",
  "cluster_name" : "myesdb",
  "cluster_uuid" : "FPZ10WapQyud3hgl1ixBoA",
  "version" : {
    "number" : "5.0.1",
    "build_hash" : "080bb47",
    "build_date" : "2016-11-11T22:08:49.812Z",
    "build_snapshot" : false,
    "lucene_version" : "6.2.1"
  },
  "tagline" : "You Know, for Search"
}
```

Or if you want to see cluster information:

```
curl http://10.100.68.199:9200/_cluster/health?pretty
```

You should see something similar to the following:

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

## Clean up with Curator

Additionally, you can run a Scheduled Job running [Curator](https://github.com/elastic/curator) to clean up your indices (or do other actions on your ES).

For this you need to deploy a Config Map (which configures the Curator) and the Scheduled Job:

```
kubectl create -f es-curator-configmap.yaml
kubectl create -f es-curator.yaml
```

The pod is set to run once a day at 1 minute past midnight and delete indices that are older than 3 days.

You can change the schedule by editing the Cron notation in the `es-curator.yaml`.

You can change the action (e.g. delete older than 3 days) by editing the `es-curator-configmap.yaml`. The definition of the `action_file.yaml` is quite self-explaining for simple set ups. For more advanced configuration options, please consult the [Curator Documentation](https://www.elastic.co/guide/en/elasticsearch/client/curator/current/index.html).

If you want to remove Curator again, just run:

```
kubectl delete scheduledjob curator
kubectl delete configmap curator-config
``` 
