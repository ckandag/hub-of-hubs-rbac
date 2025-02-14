# hub-of-hubs-rbac

[![License](https://img.shields.io/github/license/stolostron/hub-of-hubs-rbac)](/LICENSE)

[Open Policy Agent](https://www.openpolicyagent.org)-based RBAC for [Hub-of-Hubs](https://github.com/stolostron/hub-of-hubs).

## Run the server

1. Generate a certificate `tls.crt' and a key `tls.key`. For testing purposes only, you can generate self signed certificates:

```
mkdir certs
openssl genrsa -out ./certs/tls.key 2048
openssl req -new -x509 -key ./certs/tls.key -out ./certs/tls.crt -days 365 -subj '/O=example Inc./CN=example.com'
```

```
make run
```

## Run client queries

### Complie API with partial evaluation
```
USER=user1 MC=mc-test-1 envsubst < query_clusterns_unknown.json | curl -ks https://localhost:8181/v1/compile?pretty -H 'Content-Type: application/json' -d @-
```

### Data API


Data:

```
curl -ks https://localhost:8181/v1/data/permissions?pretty -H 'Content-Type: application/json'
```

Update data:

```
USER=user55 envsubst < patch_ns_access.json | curl -k -X PATCH https://localhost:8181/v1/data/permissions -H 'Content-Type: application/json'  -d @- 
```


## Test

```
make test
```

## Run in Docker

```
docker run -p 8181:8181 <the docker image>
```

## Deploy to a Kubernetes cluster

The following environment variables are required for the most tasks below:

* `REGISTRY`, for example `docker.io/vadimeisenbergibm`.
* `IMAGE_TAG`, for example `v0.1.0`.

1.  Create a secret for RBAC data

    ```
    kubectl create secret generic opa-data -n open-cluster-management --from-file=data.json --from-file=role_bindings.yaml --from-file=opa_authorization.rego
    ```

1.  Deploy the component:

    ```
    COMPONENT=$(basename $(pwd)) envsubst < deploy/operator.yaml.template | kubectl apply -n open-cluster-management -f -
    ```

## Update role bindings or role definitions

To update role bindings, edit [role_bindings.yaml](role_bindings.yaml) and add your user
(the user name that appears in the top right corner, when you login into OpenShift console).

❗Do not delete the existing role bindings for service accounts (used by Hub-of-Hubs components), add your role bindings.

The role definitions appear in [testdata/data.json](testdata/data.json).

Run the following commands:

```
kubectl delete secret opa-data -n open-cluster-management --ignore-not-found
kubectl create secret generic opa-data -n open-cluster-management --from-file=testdata/data.json --from-file=role_bindings.yaml --from-file=opa_authorization.rego
kubectl rollout restart deployment hub-of-hubs-rbac -n open-cluster-management
```

### Security measures

1. Network policy allows access only from open-cluster-management namespace
1. The OPA server runs in TLS mode, with certificates generated/rotated by OpenShift
    1. `service.beta.openshift.io/serving-cert-secret-name: hub-of-hubs-rbac-certs`
    1. `service.beta.openshift.io/inject-cabundle`
1. Immutable pods
    1. The OPA authorization allows only GET methods (POST are allowed only for /v1/compile paths - partial evaluation, and /v1/data/rbac/clusters/allow), so no update of policies/data is possible through REST API
    1. The data of the policies (roles, role bindings, OPA authorization) are in a secret
    1. The admin must perform rolling update of the pods

### Working with Kubernetes deployment

Show log:

```
kubectl logs -l name=$(basename $(pwd)) -n open-cluster-management
```

Execute commands inside the container:

```
kubectl exec -it $(kubectl get pod -l name=$(basename $(pwd)) -o jsonpath='{.items[0].metadata.name}' -n open-cluster-management) \
-n open-cluster-management -- curl -ks https://localhost:8181/v1/data/rbac/sod?pretty -H 'Content-Type: application/json'
```

```
kubectl exec -it $(kubectl get pod -l name=$(basename $(pwd)) -o jsonpath='{.items[0].metadata.name}' -n open-cluster-management) -n open-cluster-management --  curl -ks https://localhost:8181/v1/compile?pretty -H 'Content-Type: application/json' -d '{"query":"data.rbac.clusters.allow == true","input":{"user":"VADIME"},"unknowns":["input.cluster"]}'
```

## References

* OPA and SQL https://blog.openpolicyagent.org/write-policy-in-opa-enforce-policy-in-sql-d9d24db93bf4
* OPA and SQL example in elastic search https://github.com/open-policy-agent/contrib/tree/efb4466b7d23ae6356ea8337c3a1e2632e93d7b3/data_filter_elasticsearch
* https://github.com/open-policy-agent/opa/issues/947
* Explanation regarding using ConfigMaps/Secrets: https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#should-i-use-a-configmap-or-a-custom-resource
* Explanation about Rolling Update: https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/
