@description('Name of the application to be deployed')
param application string
@description('Tags to add the all resources that is being deployed')
param tags object
@description('Location to use for the resources')
param location string

var appServiceName = 'apps-${application}'
var appServicePlanName = 'plan-${application}'
var sqlServerName = 'sqlsrv-${application}'
var sqlDbName = 'sqlsrv-${application}'

// Data resources
resource sqlserver 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  tags: tags
  properties: {
    version: '12.0' 
    administrators: {
      azureADOnlyAuthentication: true
      administratorType: 'ActiveDirectory'
      principalType: 'Group'
      login: 'DbAdmins'
      sid: 'af9658eb-32a0-4359-8052-dfb4e60fa09b'
      tenantId: subscription().tenantId
    }
  }
  identity: {
     type: 'SystemAssigned'
  }

  resource firewallRule 'firewallRules@2022-05-01-preview' = {
    name: 'AllowAllWindowsAzureIps'
    properties: {
      endIpAddress: '0.0.0.0'
      startIpAddress: '0.0.0.0'
    }
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  name: sqlDbName
  parent: sqlserver
  location: location
  tags: tags
  sku: {
    name: 'Free'
  }
}

// Web App resources
resource hostingPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: 'F1'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource webSite 'Microsoft.Web/sites@2022-03-01' = {
  name: appServiceName
  location: location
  tags: tags
  properties: {
    httpsOnly: true
    serverFarmId: hostingPlan.id
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|7.0'
      minTlsVersion: '1.2'
    }
  }
  kind: 'app,linux'
  identity: {
   type: 'SystemAssigned'
  }

  resource connectionString 'config@2022-03-01' = {
    name: 'connectionstrings'
    properties: {
      DefaultConnection: {
        value: 'Server=${sqlserver.properties.fullyQualifiedDomainName}; Authentication=Active Directory Managed Identity; Encrypt=True; Database=${sqlDatabase.name}'
        type: 'SQLAzure'
      }
    }
  }
}

output sqlServerPrincipalId string = sqlserver.identity.principalId
output sqlSrvFullyQualifiedDomainName string = sqlserver.properties.fullyQualifiedDomainName
output sqlDatabaseName string = sqlDatabase.name
output appServiceName string = webSite.name
