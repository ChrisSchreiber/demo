resource "kubernetes_namespace" "deploy_namespace" {
  for_each = var.environments
  metadata {
    name = "${var.deploy_namespace}-${each.key}"
  }
}

data "kubernetes_secret" "harbor" {
  metadata {
    name      = var.harbor_secret
    namespace = var.harbor_namespace
  }
}

resource "kubernetes_secret" "image_pull_secret" {
  for_each = var.environments
  metadata {
    name      = "harbor"
    namespace = kubernetes_namespace.deploy_namespace[each.key].metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"
  data = {
    ".dockerconfigjson" = templatefile("${path.module}/dockercfg.tpl", {
      email = "admin@liatr.io"
      url   = "https://${var.harbor_host}"
      auth  = base64encode("admin:${data.kubernetes_secret.harbor.data.HARBOR_ADMIN_PASSWORD}")
    })
  }
}
