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

resource "helm_release" "redis" {
  name      = "redis"
  namespace = kubernetes_namespace.cache.metadata[0].name

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "redis"
  version    = "15.3.2"

  set {
    name  = "nameOverride"
    value = "redis"
  }

  set {
    name  = "architecture"
    value = "standalone"
  }

  set {
    name  = "auth.existingSecret"
    value = kubernetes_secret.redis.metadata[0].name
  }

  set {
    name  = "auth.existingSecretPasswordKey"
    value = "password"
  }

  set {
    name  = "image.tag"
    value = "6.2.6-debian-10-r10"
  }
}

resource "random_password" "redis" {
  special = false
  length  = 16
}

resource "kubernetes_secret" "redis" {
  metadata {
    name      = "redis"
    namespace = kubernetes_namespace.cache.metadata[0].name
  }
  data = {
    password = random_password.redis.result
  }
}
