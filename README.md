# k8-crio-centos
K8 Cluster with crio as container runtime in CentOS

## To the Cluster 
kubectl apply -f https://k8s.io/examples/application/deployment.yaml
kubectl get pods -o wide

should return something like this

| NAME | READY | STATUS | RESTARTS | AGE | IP | NODE | NOMINATED NODE | READINESS GATES |
|------|-------|--------|----------|-----|----|------|----------------|-----------------|
| nginx-deployment-66b6c48dd5-hjzrq | 1/1 | Running | 0 | 11s | 192.168.33.194 | kworker1.example.com | <none> | <none> |
| nginx-deployment-66b6c48dd5-v68rc | 1/1 | Running | 0 | 11s | 192.168.136.66 | kworker2.example.com | <none> | <none> |

kubectl describe deployment nginx-deployment

