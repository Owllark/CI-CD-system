Prerequisites:
Helm v3 installed
nginx ingress controller

Deploy steps:

helm repo add elastic https://helm.elastic.co
helm repo update

Elastic search:
helm install elk-elasticsearch elastic/elasticsearch -f elasticsearch-values.yaml --namespace logging --create-namespace

Retrieving elastic search credentials:
kubectl get secret -n logging elasticsearch-master-credentials -o jsonpath='{.data}' |  base64 --decode

Kibana:
helm install elk-kibana elastic/kibana -f kibana-values.yamls -n logging

Logstash:
helm install elk-logstash elastic/logstash -f logstash-values.yaml --set elasticsearch.username=<username> --set elasticsearch.password=<password> -n logging

Fliebeat:
helm install elk-filebeat elastic/filebeat -f filebeat-values.yaml -n logging

Applying ingress(accessible via elk.owllark.mooo.com):
kubectl apply -f elk-ingress.yaml -n logging