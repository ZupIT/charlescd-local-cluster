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

resource "helm_release" "rabbitmq" {
  name      = "rabbitmq"
  namespace = kubernetes_namespace.queue.metadata[0].name

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "rabbitmq"
  version    = "8.22.0"

  set {
    name  = "auth.password"
    value = random_password.rabbitmq["password"].result
  }

  set {
    name  = "auth.erlangCookie"
    value = random_password.rabbitmq["erlangCookie"].result
  }

  set {
    name  = "image.tag"
    value = "3.9"
  }
}

resource "random_password" "rabbitmq" {
  for_each = toset(["password", "erlangCookie"])
  keepers  = { database = each.key }
  length   = 16
}
