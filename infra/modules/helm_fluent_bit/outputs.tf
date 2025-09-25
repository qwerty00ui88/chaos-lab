output "namespace" {
  value = kubernetes_namespace.this.metadata[0].name
}

output "release_name" {
  value = helm_release.fluent_bit.name
}
