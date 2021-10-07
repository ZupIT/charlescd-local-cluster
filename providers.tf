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

terraform {
  required_providers {
    kind          = {
      source  = "kyma-incubator/kind"
      version = ">= 0.0"
    }
    kustomization = {
      source  = "kbst/kustomization"
      version = ">= 0.5"
    }
    helm          = {
      source  = "hashicorp/helm"
      version = ">= 2.3"
    }
    kubernetes    = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.5"
    }
  }
  required_version = ">= 1.0"
}

provider "helm" {
  kubernetes {
    config_path = kind_cluster.charlescd.kubeconfig_path
  }
}

provider "kind" {}

provider "kubernetes" {
  config_path = kind_cluster.charlescd.kubeconfig_path
}

provider "kustomization" {
  kubeconfig_path = kind_cluster.charlescd.kubeconfig_path
}
