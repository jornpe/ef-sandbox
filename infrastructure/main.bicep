targetScope = 'subscription'
@description('Name of the project, used in most resource names')
param application string = 'ef-test-project'
@description('Sql admin group id')
param sqlAdminGroupId string
@description('Location to use for the resources')
param location string = 'westeurope'
@description('Name of the resource group to deploy all resources to')
param rgName string = 'rg-${application}-${location}-001'
@description('Date and time in this format: ')
param dateTime string = dateTimeAdd(utcNow('F'), 'PT2H')

@description('Tags to add the all resources that is being deployed')
param tags object = {
  CreationDate: dateTime
  Application: application
}

resource rgDeployment 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: rgName
  location: location
  tags: tags
}

module resources 'resources.bicep' = {
  scope: rgDeployment
  name: '${application}-ReourceDeployment'
  params: {
    tags: tags
    location: location
    application: application
    sqlAdminGroupId: sqlAdminGroupId
  }
}

output sqlServerPrincipalId string = resources.outputs.sqlServerPrincipalId
output sqlSrvFullyQualifiedDomainName string = resources.outputs.sqlSrvFullyQualifiedDomainName
output sqlDatabaseName string = resources.outputs.sqlDatabaseName
output appServiceName string = resources.outputs.appServiceName
