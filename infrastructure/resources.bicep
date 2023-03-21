@description('Name of the application to be deployed')
param application string
@description('Tags to add the all resources that is being deployed')
param tags object
@description('Location to use for the resources')
param location string
@description('Sql admin group id')
param sqlAdminGroupId string

var appServiceName = 'apps-${application}'
var appServicePlanName = 'plan-${application}'
var sqlServerName = 'sqlsrv-${application}'
var sqlDbName = 'sqlsrv-${application}'
var sqlAdminGroup = 'DbAdmins'

// Get the id of the sqlAdminGroup Group to use when deploying SQL server
// resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
//   name: 'GetSqlAdminGroup'
//   location: location
//   kind: 'AzurePowerShell'
//   properties: {
//     azPowerShellVersion: '8.3'
//     timeout: 'PT30M'
//     arguments: '-sqlAdminGroup \\"${sqlAdminGroup}\\"'
//     scriptContent: '''
//       param([string] $sqlAdminGroup)
//       $adminGroupId = ( az ad group show --group  $sqlAdminGroup  | ConvertFrom-Json ).id
//       $DeploymentScriptOutputs = @{}
//       $DeploymentScriptOutputs[\'SqlAdminGroup\'] = $adminGroupId
//     '''
//     cleanupPreference: 'Always'
//     retentionInterval: 'P1D'
//   }
// }

// Deploy SQL server
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
      login: sqlAdminGroup
      sid: sqlAdminGroupId
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

// Database
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

// App service
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
