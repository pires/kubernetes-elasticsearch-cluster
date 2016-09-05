kubectl config use-context elk
kubectl delete deployment es-data --cascade
kubectl delete deployment es-client --cascade
kubectl delete deployment es-master --cascade
kubectl delete deployment kibana --cascade
kubectl delete rc --all --cascade
kubectl delete pod --all --cascade
kubectl delete svc --all
kubectl get pods



