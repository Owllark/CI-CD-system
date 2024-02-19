#!/bin/bash

source ./utils.sh

handle_error() {
  echo "Error occurred in command: $1"
  
  exit 1
}

ELK_USERNAME=""
ELK_PASSWORD=""

trap 'handle_error $BASH_COMMAND' ERR

if [ ! -e "config.json" ]; then
     echo "Error: config.json not found"
     exit 1
fi

kubectl create namespace logging --dry-run=client -o yaml | kubectl apply -f -
kubectl config set-context --current --namespace=logging

helm repo add elastic https://helm.elastic.co
helm repo update

files=("elasticsearch-values.yaml" "kibana-values.yaml" "logstash-values.yaml" "filebeat-values.yaml")
DIR_RENDERED="_rendered_"
declare -A params
utils_parse_json params config.json
utils_substitute_placeholders params $DIR_RENDERED "${files[@]}"


# during helm upgrade elasticsearch generates new random password and changes credentials secret 
# but actually doesn't apply new password to its own configuration, so here if elasticsearch already installed 
# parameter secret.password is set to existing password value, and credentials secret won't be changed
if [ "$(helm list -q -f elk-elasticsearch)" == "elk-elasticsearch" ]; then
  password=$(kubectl get secret elasticsearch-master-credentials -o jsonpath='{.data.password}' |  base64 --decode)
  helm upgrade elk-elasticsearch elastic/elasticsearch -f $DIR_RENDERED/elasticsearch-values.yaml --set secret.password="$password"
else
  helm install elk-elasticsearch elastic/elasticsearch -f $DIR_RENDERED/elasticsearch-values.yaml 
fi


kubectl wait --for=condition=Ready pod -l app=elasticsearch-master --timeout=-1s

ELK_USERNAME=$(kubectl get secret elasticsearch-master-credentials -o jsonpath='{.data.username}' |  base64 --decode)
ELK_PASSWORD=$(kubectl get secret elasticsearch-master-credentials -o jsonpath='{.data.password}' |  base64 --decode)
echo $ELK_USERNAME $ELK_PASSWORD
echo $ELK_USERNAME $ELK_PASSWORD > elk_credentials

helm upgrade --install elk-logstash elastic/logstash -f $DIR_RENDERED/logstash-values.yaml \
--set elasticsearch.username=$ELK_USERNAME \
--set elasticsearch.password=$ELK_PASSWORD

if [ "$(helm list -q -f elk-kibana)" == "elk-kibana" ]; then
    helm uninstall elk-kibana
fi

kubectl delete secret elk-kibana-kibana-es-token --ignore-not-found
helm upgrade --install elk-kibana elastic/kibana -f $DIR_RENDERED/kibana-values.yaml

helm upgrade --install elk-filebeat elastic/filebeat -f $DIR_RENDERED/filebeat-values.yaml

kubectl wait --for=condition=Ready pod -l app=kibana --timeout=-1s
kubectl wait --for=condition=Ready pod -l app=elk-logstash-logstash --timeout=-1s

ENTITY_DIR="entities"
INDEX_NAME="my-index"
INDEX_CONFIG=$(cat $ENTITY_DIR/index-config.json)
LIFECYCLE_NAME="my-policy"
LIFECYCLE_CONFIG=$(cat $ENTITY_DIR/lifecycle-policy-config.json)
INDEX_PATTERN_CONFIG=$(cat $ENTITY_DIR/index-pattern-config.json)
INDEX_PATTERN_CONFIG_ALL=$(cat $ENTITY_DIR/index-pattern-config-all.json)

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

echo "ELK installed successfully!"

