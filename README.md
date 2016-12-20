# kubernetes-elasticsearch-cluster
Elasticsearch (5.1.1) cluster on top of Kubernetes made easy.

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

* Kubernetes cluster with **alpha features enabled** (tested with v1.5.1 on top of [Vagrant + CoreOS](https://github.com/pires/kubernetes-vagrant-coreos-cluster))
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
NAME                          CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
svc/elasticsearch             10.100.125.138   <pending>     9200:31512/TCP   5m
svc/elasticsearch-discovery   10.100.86.236    <none>        9300/TCP         5m
svc/kubernetes                10.100.0.1       <none>        443/TCP          18m

NAME               DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/es-client   1         1         1            1           2m
deploy/es-data     1         1         1            1           1m
deploy/es-master   1         1         1            1           5m

NAME                           READY     STATUS    RESTARTS   AGE
po/es-client-583738243-jcnkb   1/1       Running   0          2m
po/es-data-903740887-x91q8     1/1       Running   0          1m
po/es-master-726932337-hh7p2   1/1       Running   0          5m
```

```
$ kubectl logs -f es-master-726932337-hh7p2
[2016-12-20T10:21:10,037][WARN ][o.e.c.l.LogConfigurator  ] ignoring unsupported logging configuration file [/elasticsearch/config/logging.yml], logging is configured via [/elasticsearch/config/log4j2.properties]
[2016-12-20T10:21:10,406][INFO ][o.e.n.Node               ] [] initializing ...
[2016-12-20T10:21:10,529][INFO ][o.e.e.NodeEnvironment    ] [kzMEfUH] using [1] data paths, mounts [[/data (/dev/sda9)]], net usable_space [13.7gb], net total_space [15.5gb], spins? [possibly], types [ext4]
[2016-12-20T10:21:10,530][INFO ][o.e.e.NodeEnvironment    ] [kzMEfUH] heap size [247.5mb], compressed ordinary object pointers [true]
[2016-12-20T10:21:10,531][INFO ][o.e.n.Node               ] node name [kzMEfUH] derived from node ID [kzMEfUHJRvqVc2S26QPsfg]; set [node.name] to override
[2016-12-20T10:21:10,536][INFO ][o.e.n.Node               ] version[5.1.1], pid[11], build[5395e21/2016-12-06T12:36:15.409Z], OS[Linux/4.9.0-coreos/amd64], JVM[Oracle Corporation/OpenJDK 64-Bit Server VM/1.8.0_111-internal/25.111-b14]
[2016-12-20T10:21:12,309][INFO ][o.e.p.PluginsService     ] [kzMEfUH] loaded module [aggs-matrix-stats]
[2016-12-20T10:21:12,309][INFO ][o.e.p.PluginsService     ] [kzMEfUH] loaded module [ingest-common]
[2016-12-20T10:21:12,309][INFO ][o.e.p.PluginsService     ] [kzMEfUH] loaded module [lang-expression]
[2016-12-20T10:21:12,309][INFO ][o.e.p.PluginsService     ] [kzMEfUH] loaded module [lang-groovy]
[2016-12-20T10:21:12,309][INFO ][o.e.p.PluginsService     ] [kzMEfUH] loaded module [lang-mustache]
[2016-12-20T10:21:12,310][INFO ][o.e.p.PluginsService     ] [kzMEfUH] loaded module [lang-painless]
[2016-12-20T10:21:12,310][INFO ][o.e.p.PluginsService     ] [kzMEfUH] loaded module [percolator]
[2016-12-20T10:21:12,310][INFO ][o.e.p.PluginsService     ] [kzMEfUH] loaded module [reindex]
[2016-12-20T10:21:12,310][INFO ][o.e.p.PluginsService     ] [kzMEfUH] loaded module [transport-netty3]
[2016-12-20T10:21:12,310][INFO ][o.e.p.PluginsService     ] [kzMEfUH] loaded module [transport-netty4]
[2016-12-20T10:21:12,311][INFO ][o.e.p.PluginsService     ] [kzMEfUH] loaded plugin [discovery-kubernetes]
[2016-12-20T10:21:16,379][INFO ][o.e.n.Node               ] initialized
[2016-12-20T10:21:16,379][INFO ][o.e.n.Node               ] [kzMEfUH] starting ...
[2016-12-20T10:21:16,612][INFO ][o.e.t.TransportService   ] [kzMEfUH] publish_address {10.244.101.2:9300}, bound_addresses {10.244.101.2:9300}
[2016-12-20T10:21:16,713][INFO ][o.e.b.BootstrapCheck     ] [kzMEfUH] bound or publishing to a non-loopback or non-link-local address, enforcing bootstrap checks
SLF4J: Failed to load class "org.slf4j.impl.StaticLoggerBinder".
SLF4J: Defaulting to no-operation (NOP) logger implementation
SLF4J: See http://www.slf4j.org/codes.html#StaticLoggerBinder for further details.
[2016-12-20T10:21:21,918][INFO ][o.e.c.s.ClusterService   ] [kzMEfUH] new_master {kzMEfUH}{kzMEfUHJRvqVc2S26QPsfg}{hzlw-wLmSfSao30hp-w3YA}{10.244.101.2}{10.244.101.2:9300}, reason: zen-disco-elected-as-master ([0] nodes joined)
[2016-12-20T10:21:21,939][INFO ][o.e.n.Node               ] [kzMEfUH] started
[2016-12-20T10:21:21,986][INFO ][o.e.g.GatewayService     ] [kzMEfUH] recovered [0] indices into cluster_state
[2016-12-20T10:24:14,881][INFO ][o.e.c.s.ClusterService   ] [kzMEfUH] added {{ziL1qi3}{ziL1qi3QQK2B84oaT6_DCg}{-BoojyYcTEqZ1Q46tgqA_w}{10.244.7.2}{10.244.7.2:9300},}, reason: zen-disco-node-join[{ziL1qi3}{ziL1qi3QQK2B84oaT6_DCg}{-BoojyYcTEqZ1Q46tgqA_w}{10.244.7.2}{10.244.7.2:9300}]
[2016-12-20T10:25:30,228][INFO ][o.e.c.s.ClusterService   ] [kzMEfUH] added {{Fusi2uq}{Fusi2uqLQGCuVXZ5XqUmFw}{ptkp6cIPQF2zX4rSRdWBmw}{10.244.81.2}{10.244.81.2:9300},}, reason: zen-disco-node-join[{Fusi2uq}{Fusi2uqLQGCuVXZ5XqUmFw}{ptkp6cIPQF2zX4rSRdWBmw}{10.244.81.2}{10.244.81.2:9300}]
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
deploy/es-client   2         2         2            2           5m
deploy/es-data     2         2         2            2           4m
deploy/es-master   3         3         3            3           8m

NAME                           READY     STATUS    RESTARTS   AGE
po/es-client-583738243-jcnkb   1/1       Running   0          5m
po/es-client-583738243-t80cp   1/1       Running   0          1m
po/es-data-903740887-h7cqd     1/1       Running   0          35s
po/es-data-903740887-x91q8     1/1       Running   0          4m
po/es-master-726932337-1l6hd   1/1       Running   0          2m
po/es-master-726932337-bpkjk   1/1       Running   0          2m
po/es-master-726932337-hh7p2   1/1       Running   0          8m
```

Let's take another look at the logs of one of the Elasticsearch `master` nodes:

```
$ kubectl logs -f es-master-726932337-hh7p2
[2016-12-20T10:21:10,037][WARN ][o.e.c.l.LogConfigurator  ] ignoring unsupported logging configuration file [/elasticsearch/config/logging.yml], logging is configured via [/elasticsearch/config/log4j2.properties]
[2016-12-20T10:21:10,406][INFO ][o.e.n.Node               ] [] initializing ...
[2016-12-20T10:21:10,529][INFO ][o.e.e.NodeEnvironment    ] [kzMEfUH] using [1] data paths, mounts [[/data (/dev/sda9)]], net usable_space [13.7gb], net total_space [15.5gb], spins? [possibly], types [ext4]
[2016-12-20T10:21:10,530][INFO ][o.e.e.NodeEnvironment    ] [kzMEfUH] heap size [247.5mb], compressed ordinary object pointers [true]
[2016-12-20T10:21:10,531][INFO ][o.e.n.Node               ] node name [kzMEfUH] derived from node ID [kzMEfUHJRvqVc2S26QPsfg]; set [node.name] to override
[2016-12-20T10:21:10,536][INFO ][o.e.n.Node               ] version[5.1.1], pid[11], build[5395e21/2016-12-06T12:36:15.409Z], OS[Linux/4.9.0-coreos/amd64], JVM[Oracle Corporation/OpenJDK 64-Bit Server VM/1.8.0_111-internal/25.111-b14]
[2016-12-20T10:21:12,309][INFO ][o.e.p.PluginsService     ] [kzMEfUH] loaded module [aggs-matrix-stats]
[2016-12-20T10:21:12,309][INFO ][o.e.p.PluginsService     ] [kzMEfUH] loaded module [ingest-common]
[2016-12-20T10:21:12,309][INFO ][o.e.p.PluginsService     ] [kzMEfUH] loaded module [lang-expression]
[2016-12-20T10:21:12,309][INFO ][o.e.p.PluginsService     ] [kzMEfUH] loaded module [lang-groovy]
[2016-12-20T10:21:12,309][INFO ][o.e.p.PluginsService     ] [kzMEfUH] loaded module [lang-mustache]
[2016-12-20T10:21:12,310][INFO ][o.e.p.PluginsService     ] [kzMEfUH] loaded module [lang-painless]
[2016-12-20T10:21:12,310][INFO ][o.e.p.PluginsService     ] [kzMEfUH] loaded module [percolator]
[2016-12-20T10:21:12,310][INFO ][o.e.p.PluginsService     ] [kzMEfUH] loaded module [reindex]
[2016-12-20T10:21:12,310][INFO ][o.e.p.PluginsService     ] [kzMEfUH] loaded module [transport-netty3]
[2016-12-20T10:21:12,310][INFO ][o.e.p.PluginsService     ] [kzMEfUH] loaded module [transport-netty4]
[2016-12-20T10:21:12,311][INFO ][o.e.p.PluginsService     ] [kzMEfUH] loaded plugin [discovery-kubernetes]
[2016-12-20T10:21:16,379][INFO ][o.e.n.Node               ] initialized
[2016-12-20T10:21:16,379][INFO ][o.e.n.Node               ] [kzMEfUH] starting ...
[2016-12-20T10:21:16,612][INFO ][o.e.t.TransportService   ] [kzMEfUH] publish_address {10.244.101.2:9300}, bound_addresses {10.244.101.2:9300}
[2016-12-20T10:21:16,713][INFO ][o.e.b.BootstrapCheck     ] [kzMEfUH] bound or publishing to a non-loopback or non-link-local address, enforcing bootstrap checks
SLF4J: Failed to load class "org.slf4j.impl.StaticLoggerBinder".
SLF4J: Defaulting to no-operation (NOP) logger implementation
SLF4J: See http://www.slf4j.org/codes.html#StaticLoggerBinder for further details.
[2016-12-20T10:21:21,918][INFO ][o.e.c.s.ClusterService   ] [kzMEfUH] new_master {kzMEfUH}{kzMEfUHJRvqVc2S26QPsfg}{hzlw-wLmSfSao30hp-w3YA}{10.244.101.2}{10.244.101.2:9300}, reason: zen-disco-elected-as-master ([0] nodes joined)
[2016-12-20T10:21:21,939][INFO ][o.e.n.Node               ] [kzMEfUH] started
[2016-12-20T10:21:21,986][INFO ][o.e.g.GatewayService     ] [kzMEfUH] recovered [0] indices into cluster_state
[2016-12-20T10:24:14,881][INFO ][o.e.c.s.ClusterService   ] [kzMEfUH] added {{ziL1qi3}{ziL1qi3QQK2B84oaT6_DCg}{-BoojyYcTEqZ1Q46tgqA_w}{10.244.7.2}{10.244.7.2:9300},}, reason: zen-disco-node-join[{ziL1qi3}{ziL1qi3QQK2B84oaT6_DCg}{-BoojyYcTEqZ1Q46tgqA_w}{10.244.7.2}{10.244.7.2:9300}]
[2016-12-20T10:25:30,228][INFO ][o.e.c.s.ClusterService   ] [kzMEfUH] added {{Fusi2uq}{Fusi2uqLQGCuVXZ5XqUmFw}{ptkp6cIPQF2zX4rSRdWBmw}{10.244.81.2}{10.244.81.2:9300},}, reason: zen-disco-node-join[{Fusi2uq}{Fusi2uqLQGCuVXZ5XqUmFw}{ptkp6cIPQF2zX4rSRdWBmw}{10.244.81.2}{10.244.81.2:9300}]
[2016-12-20T10:26:49,771][INFO ][o.e.c.s.ClusterService   ] [kzMEfUH] added {{_tzHPsf}{_tzHPsfYRy2nxyK1ULXfSw}{I39b_zLiSg-mr0V6c3BLjw}{10.244.7.3}{10.244.7.3:9300},}, reason: zen-disco-node-join[{_tzHPsf}{_tzHPsfYRy2nxyK1ULXfSw}{I39b_zLiSg-mr0V6c3BLjw}{10.244.7.3}{10.244.7.3:9300}]
[2016-12-20T10:26:49,923][WARN ][o.e.d.z.ElectMasterService] [kzMEfUH] value for setting "discovery.zen.minimum_master_nodes" is too low. This can result in data loss! Please set it to at least a quorum of master-eligible nodes (current value: [1], total number of master-eligible nodes used for publishing in this round: [2])
[2016-12-20T10:26:50,238][INFO ][o.e.c.s.ClusterService   ] [kzMEfUH] added {{fz9Zhvc}{fz9Zhvc4RhKTHps_nkskYw}{xjOK6N6dSPqQP4ha1-5iwg}{10.244.81.3}{10.244.81.3:9300},}, reason: zen-disco-node-join[{fz9Zhvc}{fz9Zhvc4RhKTHps_nkskYw}{xjOK6N6dSPqQP4ha1-5iwg}{10.244.81.3}{10.244.81.3:9300}]
[2016-12-20T10:27:44,387][INFO ][o.e.c.s.ClusterService   ] [kzMEfUH] added {{GaShDXd}{GaShDXdMRSmECRgSG8hrXw}{laIik6PaQ7Sq9Buhq2CoCQ}{10.244.101.3}{10.244.101.3:9300},}, reason: zen-disco-node-join[{GaShDXd}{GaShDXdMRSmECRgSG8hrXw}{laIik6PaQ7Sq9Buhq2CoCQ}{10.244.101.3}{10.244.101.3:9300}]
[2016-12-20T10:28:19,928][INFO ][o.e.c.s.ClusterService   ] [kzMEfUH] added {{5Ul1Jw6}{5Ul1Jw6jT_Kfqz5TXZ6Tug}{5ZIVDX17Qyit_3c_djEVOw}{10.244.101.4}{10.244.101.4:9300},}, reason: zen-disco-node-join[{5Ul1Jw6}{5Ul1Jw6jT_Kfqz5TXZ6Tug}{5ZIVDX17Qyit_3c_djEVOw}{10.244.101.4}{10.244.101.4:9300}]
```

### Access the service

*Don't forget* that services in Kubernetes are only acessible from containers in the cluster. For different behavior you should [configure the creation of an external load-balancer](http://kubernetes.io/v1.1/docs/user-guide/services.html#type-loadbalancer). While it's supported within this example service descriptor, its usage is out of scope of this document, for now.

```
$ kubectl get svc elasticsearch
NAME            CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
elasticsearch   10.100.125.138   <pending>     9200:31512/TCP   9m
```

From any host on your cluster (that's running `kube-proxy`), run:

```
curl http://10.100.125.138:9200
```

You should see something similar to the following:

```json
{
  "name" : "GaShDXd",
  "cluster_name" : "myesdb",
  "cluster_uuid" : "uaEaQCm2Qhmx3rBKRj8klg",
  "version" : {
    "number" : "5.1.1",
    "build_hash" : "5395e21",
    "build_date" : "2016-12-06T12:36:15.409Z",
    "build_snapshot" : false,
    "lucene_version" : "6.3.0"
  },
  "tagline" : "You Know, for Search"
}
```

Or if you want to see cluster information:

```
curl http://10.100.125.138:9200/_cluster/health?pretty
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

Additionally, you can run a [CronJob](http://kubernetes.io/docs/user-guide/cron-jobs/) that will periodically run [Curator](https://github.com/elastic/curator) to clean up your indices (or do other actions on your cluster).

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

- You can change the schedule by editing the cron notation in `es-curator.yaml`.
- You can change the action (e.g. delete older than 3 days) by editing the `es-curator-config.yaml`.
- The definition of the `action_file.yaml` is quite self-explaining for simple set-ups. For more advanced configuration options, please consult the [Curator Documentation](https://www.elastic.co/guide/en/elasticsearch/client/curator/current/index.html).

If you want to remove the curator job, just run:

```
kubectl delete cronjob curator
kubectl delete configmap curator-config
``` 
