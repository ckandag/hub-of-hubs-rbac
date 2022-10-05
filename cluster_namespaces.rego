package rbac.clusternamespaces


default allow = false

allow {
    user := input.user
    managedcluster := input.managedcluster
    namespace := input.namespace
    access_allowed[[user, managedcluster, namespace]]
}

access_allowed[[user, managedcluster, namespace]] {
    some i, j
    user := data.policyrolebindings[i].acl[j].user
    managedcluster := data.policyrolebindings[i].acl[j].managedcluster
    namespace = data.policyrolebindings[i].acl[j].namespace
}


