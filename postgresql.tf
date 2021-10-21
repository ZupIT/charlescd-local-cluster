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
  databases = [
    "charlescd_moove",
    "charlescd_villager",
    "charlescd_butler",
    "charlescd_hermes",
    "charlescd_compass",
    "keycloak",
  ]
  database  = {
  for db in local.databases : db => {
    database = "${db}_db"
    user     = db
    password = random_password.databases[db].result
  }
  }
}

resource "random_password" "databases" {
  for_each = toset(local.databases)
  keepers  = { database = each.key }
  length   = 16
  special  = false
}

resource "helm_release" "postgresql" {
  name      = "postgresql"
  namespace = kubernetes_namespace.database.metadata[0].name

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  version    = "10.12.4"

  set {
    name  = "initdbScriptsSecret"
    value = kubernetes_secret.userdata.metadata[0].name
  }

  set {
    name  = "fullnameOverride"
    value = "postgresql"
  }

  set {
    name  = "image.tag"
    value = "11.13.0-debian-10-r65"
  }
}

resource "kubernetes_secret" "userdata" {
  metadata {
    name      = "userdata"
    namespace = kubernetes_namespace.database.metadata[0].name
  }
  data = {
    "userdata.sql" = <<-EOT
      %{ for db in local.databases ~}
      create database ${local.database[db]["database"]};
      create user ${local.database[db]["user"]} with encrypted password '${local.database[db]["password"]}';
      alter user ${local.database[db]["user"]} with superuser;
      grant all privileges on database ${local.database[db]["database"]} to ${local.database[db]["user"]};
      %{ endfor ~}
    EOT
  }
}
