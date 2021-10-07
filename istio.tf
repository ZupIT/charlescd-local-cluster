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

resource "kustomization_resource" "istio" {
  manifest = jsonencode({
    "apiVersion" = "install.istio.io/v1alpha1"
    "kind"       = "IstioOperator"
    "metadata"   = {
      "name"      = "control-plane"
      "namespace" = kubernetes_namespace.istio_system.metadata[0].name
    }
    "spec"       = {
      "profile"    = "demo"
      "components" = {
        "egressGateways"  = [{ enabled = false, name = "istio-egressgateway" }]
        "ingressGateways" = [
          {
            name    = "istio-ingressgateway"
            enabled = true
            k8s     = {
              "nodeSelector" = { "ingress-ready" = "true" }
              "service"      = {
                "ports" = [
                  { name = "status-port", nodePort = 30002, port = 15021, targetPort = 15021 },
                  { name = "http2", nodePort = 30000, port = 80, targetPort = 8080 },
                  { name = "https", nodePort = 30001, port = 443, targetPort = 8443 },
                ]
              }
            }
          },
        ]
      }
      "values"     = {
        "gateways" = { "istio-ingressgateway" = { "type" = "NodePort" } }
        "global"   = {
          "defaultPodDisruptionBudget" = { "enabled" = false }
          "logging"                    = { "level" = "default:debug" }
          "proxy"                      = { "componentLogLevel" = "misc:debug", "logLevel" = "debug" }
        }
      }
    }
  })

  depends_on = [helm_release.istio_operator]
}
