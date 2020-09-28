# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURE KUBECTL AND RBAC ROLE PERMISSIONS
# ---------------------------------------------------------------------------------------------------------------------

# configure kubectl with the credentials of the GKE cluster
resource "null_resource" "configure_kubectl" {
  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${module.gke_cluster.name} --region ${var.region} --project ${var.project_id}"
  }

  depends_on = [google_container_node_pool.node_pool]
}

resource "kubernetes_cluster_role_binding" "user" {
  metadata {
    name = "admin-user"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "cluster-admin"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "User"
    name      = data.google_client_openid_userinfo.terraform_user.email
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    # this is a workaround for https://github.com/terraform-providers/terraform-provider-kubernetes/issues/204.
    # we have to set an empty api_group or the k8s call will fail. It will be fixed in v1.5.2 of the k8s provider.
    api_group = ""

    kind      = "ServiceAccount"
    name      = "default"
    namespace = "kube-system"
  }

  subject {
    kind      = "Group"
    name      = "system:masters"
    api_group = "rbac.authorization.k8s.io"
  }
}

