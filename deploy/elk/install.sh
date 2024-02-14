ELK_USERNAME=""
ELK_PASSWORD=""

kubectl create namespace logging;
kubectl config set-context --current --namespace=logging

helm repo add elastic https://helm.elastic.co
helm repo update

helm install elk-elasticsearch elastic/elasticsearch -f elasticsearch-values.yaml 

kubectl wait --for=condition=Ready pod -l app=elasticsearch-master --timeout=-1s

ELK_USERNAME=$(kubectl get secret elasticsearch-master-credentials -o jsonpath='{.data.username}' |  base64 --decode)
ELK_PASSWORD=$(kubectl get secret elasticsearch-master-credentials -o jsonpath='{.data.password}' |  base64 --decode)
echo $ELK_USERNAME $ELK_PASSWORD
echo $ELK_USERNAME $ELK_PASSWORD > elk_credentials

helm install elk-logstash elastic/logstash -f logstash-values.yaml --set elasticsearch.username=$ELK_USERNAME --set elasticsearch.password=$ELK_PASSWORD
helm install elk-kibana elastic/kibana -f kibana-values.yaml
helm install elk-filebeat elastic/filebeat -f filebeat-values.yaml

kubectl wait --for=condition=Ready pod -l app=kibana --timeout=-1s
kubectl wait --for=condition=Ready pod -l app=elk-logstash-logstash --timeout=-1s

kubectl apply -f elk-ingress.yaml

INDEX_NAME="my-index"
INDEX_CONFIG=$(cat index-config.json)
LIFECYCLE_NAME="my-policy"
LIFECYCLE_CONFIG=$(cat lifecycle-policy-config.json)
INDEX_PATTERN_CONFIG=$(cat index-pattern-config.json)
INDEX_PATTERN_CONFIG_ALL=$(cat index-pattern-config-all.json)
echo $INDEX_CONFIG

kubectl apply -f curl-pod.yaml
kubectl wait --for=condition=Ready pod -l app=curl --timeout=-1s

kubectl exec --stdin --tty curl-pod -- curl -X PUT "https://elasticsearch-master:9200/_ilm/policy/$LIFECYCLE_NAME" \
-u "$ELK_USERNAME:$ELK_PASSWORD" \
-H 'Content-Type: application/json' \
-H 'kbn-xsrf: true' \
--data "$LIFECYCLE_CONFIG" \
--insecure

kubectl exec --stdin --tty curl-pod -- curl -X PUT "https://elasticsearch-master:9200/$INDEX_NAME" \
-u "$ELK_USERNAME:$ELK_PASSWORD" \
-H 'Content-Type: application/json' \
-H 'kbn-xsrf: true' \
--data "$INDEX_CONFIG" \
--insecure

kubectl exec --stdin --tty curl-pod -- curl -X POST http://elk-kibana-kibana:5601/api/saved_objects/index-pattern/index-pattern-1 \
-u "$ELK_USERNAME:$ELK_PASSWORD" \
-H 'Content-Type: application/json' \
-H 'kbn-xsrf: true' \
--data "$INDEX_PATTERN_CONFIG" \
--insecure

kubectl exec --stdin --tty curl-pod -- curl -X POST http://elk-kibana-kibana:5601/api/saved_objects/index-pattern/index-pattern-2 \
-u "$ELK_USERNAME:$ELK_PASSWORD" \
-H 'Content-Type: application/json' \
-H 'kbn-xsrf: true' \
--data "$INDEX_PATTERN_CONFIG_ALL" \
--insecure

kubectl delete pod curl-pod

