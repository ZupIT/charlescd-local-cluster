/**
 * Copyright 2021 ZUP IT SERVICOS EM TECNOLOGIA E INOVACAO SA
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  keycloak = {
    host = "keycloak.${local.cluster_domain}"
  }
}

resource "helm_release" "keycloak" {
  name      = "keycloak"
  namespace = kubernetes_namespace.iam.metadata[0].name

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "keycloak"
  version    = "5.0.7"

  set {
    name  = "nameOverride"
    value = "keycloak"
  }

  values = [
    yamlencode({
      image            = { repository = "bitnami/keycloak", tag = "15.0.2-debian-10-r52" }
      auth             = {
        adminUser                 = "admin"
        existingSecretPerPassword = {
          adminPassword      = { name = kubernetes_secret.keycloak_passwords.metadata[0].name }
          managementPassword = { name = kubernetes_secret.keycloak_passwords.metadata[0].name }
          databasePassword   = { name = kubernetes_secret.keycloak_passwords.metadata[0].name }
        }
      }
      ingress          = {
        enabled     = true
        hostname    = local.keycloak.host
        pathType    = "Prefix"
        annotations = {
          "kubernetes.io/ingress.class" = "istio"
        }
      }
      service          = { type = "ClusterIP" }
      extraEnvVars     = [
        { name = "KEYCLOAK_LOGLEVEL", value = "DEBUG" },
        { name = "ROOT_LOGLEVEL", value = "DEBUG" }
      ]
      postgresql       = { enabled = false }
      externalDatabase = { existingSecret = kubernetes_secret.database_env_vars.metadata[0].name }
    })
  ]

  depends_on = [helm_release.postgresql]
}

resource "random_password" "keycloak_admin" {
  length = 16
}

resource "random_password" "keycloak_management" {
  length = 16
}

resource "kubernetes_secret" "keycloak_passwords" {
  metadata {
    name      = "keycloak-passwords"
    namespace = kubernetes_namespace.iam.metadata[0].name
  }
  data = {
    adminPassword      = random_password.keycloak_admin.result
    managementPassword = random_password.keycloak_management.result
    databasePassword   = local.database["keycloak"]["password"]
  }
}

resource "kubernetes_secret" "database_env_vars" {
  metadata {
    name      = "database-env-vars"
    namespace = kubernetes_namespace.iam.metadata[0].name
  }
  data = {
    KEYCLOAK_DATABASE_HOST = "postgresql.${kubernetes_namespace.database.metadata[0].name}.svc.cluster.local"
    KEYCLOAK_DATABASE_PORT = 5432
    KEYCLOAK_DATABASE_NAME = local.database["keycloak"]["database"]
    KEYCLOAK_DATABASE_USER = local.database["keycloak"]["user"]
  }
}

resource "kubernetes_namespace" "iam" {
  metadata { name = "iam" }
}
