package rbac.clusternamespaces


default allow = false

allow {
    user := input.user
    managedcluster := input.managedcluster
    namespace := input.namespace
    access_allowed[[user, managedcluster, namespace]]
}

access_allowed[[user, managedcluster, namespace]] {
    some i
	user := data.permissions[i].user
    managedcluster := data.permissions[i].managedcluster
	namespace = data.permissions[i].namespaces[_]    
}


