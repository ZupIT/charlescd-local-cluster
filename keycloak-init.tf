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

resource "kubernetes_job" "keycloak_init" {
  metadata {
    name      = "keycloak-init"
    namespace = kubernetes_namespace.iam.metadata[0].name
  }
  spec {
    template {
      metadata {}
      spec {
        container {
          name              = "keycloak-admin-client"
          image             = "kurtis/keycloak-admin-client:15.0.2"
          image_pull_policy = "Always"
          volume_mount {
            mount_path = "/app/script"
            name       = "script"
          }
          env_from {
            secret_ref {
              name = kubernetes_secret.keycloak_init_env_vars.metadata[0].name
            }
          }
        }
        volume {
          name = "script"
          config_map {
            name = kubernetes_config_map.keycloak_scripts.metadata[0].name
            items {
              key  = keys(kubernetes_config_map.keycloak_scripts.data)[0]
              path = "index.js"
            }
          }
        }
        restart_policy = "Never"
      }
    }
    backoff_limit = 4
  }
  wait_for_completion = true

  depends_on = [helm_release.keycloak]
}

resource "kubernetes_config_map" "keycloak_scripts" {
  metadata {
    name      = "keycloak-scripts"
    namespace = kubernetes_namespace.iam.metadata[0].name
  }
  data = {
    "keycloak-init.js" = file("${path.cwd}/keycloak-init.js")
  }
}

resource "random_password" "charlescd_client_secret" {
  length  = 16
  special = true
}

resource "random_password" "charlescd_user_password" {
  length  = 16
  special = true
}

resource "kubernetes_secret" "keycloak_init_env_vars" {
  metadata {
    name      = "keycloak-init-env-vars"
    namespace = kubernetes_namespace.iam.metadata[0].name
  }
  data = {
    BASE_URL      = "http://keycloak.${kubernetes_namespace.iam.metadata[0].name}.svc.cluster.local/auth"
    REALM_NAME    = "master"
    CLIENT_ID     = "admin-cli"
    USERNAME      = "admin"
    PASSWORD      = random_password.keycloak_admin.result
    GRANT_TYPE    = "password"
    CLIENT_SECRET = random_password.charlescd_client_secret.result
    USER_PASSWORD = random_password.charlescd_user_password.result
  }
}
