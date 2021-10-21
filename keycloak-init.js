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

module.exports = async function (keycloak) {
    const realm = 'charlescd';
    const publicClient = {clientId: 'charlescd-client'}
    let confidentialClient = {clientId: 'realm-charlescd'}

    // create realm if not exists
    if (!await keycloak.realms.findOne({realm})) {
        await keycloak.realms.create({id: realm, realm, enabled: true});
        console.log(`realm '${realm}' created`)
    }

    // change default realm
    keycloak.setConfig({realmName: realm});

    // create public client if not exists
    let clients = await keycloak.clients.find({clientId: publicClient.clientId});
    if (!clients || clients.length === 0) {
        await keycloak.clients.create({
            clientId: publicClient.clientId,
            directAccessGrantsEnabled: true,
            implicitFlowEnabled: true,
            publicClient: true,
            redirectUris: ["http://charles.lvh.me/*"],
            serviceAccountsEnabled: true,
            webOrigins: ["*"]
        });
        console.log(`client '${publicClient.clientId}' created`)
    }

    // create confidential client if not exists
    clients = await keycloak.clients.find({clientId: confidentialClient.clientId});
    if (!clients || clients.length === 0) {
        await keycloak.clients.create({
            clientId: confidentialClient.clientId,
            secret: process.env.CLIENT_SECRET,
            serviceAccountsEnabled: true,
            standardFlowEnabled: false,
        });
        console.log(`client '${confidentialClient.clientId}' created`)
    }

    confidentialClient = (await keycloak.clients.find({clientId: 'realm-charlescd'}))[0]

    // get service account user
    const serviceAccountUser = await keycloak.clients.getServiceAccountUser(({id: confidentialClient.id}));

    // find roles
    const realmManagementClient = (await keycloak.clients.find({clientId: 'realm-management'}))[0]
    const roles = (await keycloak.users.listAvailableClientRoleMappings({
        id: serviceAccountUser.id,
        clientUniqueId: realmManagementClient.id
    })).filter(({name}) => name === 'view-users' || name === 'manage-users')

    if (roles && roles.length > 0) {
        // assign roles
        await keycloak.users.addClientRoleMappings({
            id: serviceAccountUser.id,
            clientUniqueId: realmManagementClient.id,
            roles
        });
        console.log(`'view-users' role was assigned to client '${confidentialClient.clientId}'`)
    }

    // create admin user if not exists
    const username = "charlesadmin@admin"
    clients = await keycloak.users.find({username});
    if (!clients || clients.length === 0) {
        const {id} = (await keycloak.users.create({
            username,
            enabled: true,
            emailVerified: true,
            email: username,
            attributes: {isRoot: ["true"]},
        }))
        console.log(`user '${username}' created`)
        await keycloak.users.resetPassword({
            id,
            credential: {type: "password", value: process.env.USER_PASSWORD, temporary: false},
        });
        console.log(`credentials of '${username}' have been set`)
    }
}
