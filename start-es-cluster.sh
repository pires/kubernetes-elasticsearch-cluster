kubectl config use-context elk
kubectl create -f es-discovery-svc.yaml
kubectl create -f es-svc.yaml
kubectl create -f es-master.yaml
sleep 20
kubectl create -f es-client.yaml
sleep 30
kubectl create -f es-data.yaml
kubectl create -f kibana.yaml
sleep 30
kubectl create -f kibana-svc.yaml

kubectl scale deployment es-master --replicas 3
kubectl scale deployment es-client --replicas 2
kubectl scale deployment es-data --replicas 2
kubectl scale deployment kibana --replicas 2
sleep 30
kubectl get deployments,pods

