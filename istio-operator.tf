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

resource "helm_release" "istio_operator" {
  name      = "istio-operator"
  namespace = kubernetes_namespace.istio_system.metadata[0].name

  repository = "https://charts.kurtis.dev.br/"
  chart      = "istio-operator"
  version    = "1.7.0"

  set {
    name  = "operatorNamespace"
    value = "istio-operator"
  }

  set {
    name  = "watchedNamespaces"
    value = kubernetes_namespace.istio_system.metadata[0].name
  }

  set {
    name  = "hub"
    value = "docker.io/istio"
  }

  set {
    name  = "tag"
    value = "1.7.4-distroless"
  }
}
