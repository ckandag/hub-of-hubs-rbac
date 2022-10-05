package rbac.namespaces

namespaces {
    user := input.user
    managedcluster := input.managedcluster
    namespaces_for_cluster[[user, managedcluster]]
}

namespaces_for_cluster[[user, managedcluster]] {
    some i, j
    user := data.policyrolebindings[i].acl[j].user
    managedcluster := data.policyrolebindings[i].acl[j].managedcluster
    namespace := data.policyrolebindings[i].acl[j].namespace
}


