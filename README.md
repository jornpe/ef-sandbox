# Entity frameowrk test repo

This repo is setup for testing entity framework migrations in gihub actions pipeline along with getting familliar with entity framework. 

## Goals
- Do EF migrations vis pipeline
- Setting up a function app in azure with managed identity for azure sql database access
- Setup local test flow where a db will be seeded with test data when running
- Unit testing with test database in pipeline

## Setting up infrastructure code
Used this article as a good guide: [E2E DevOps for Azure SQL with Managed Identities](https://medium.com/medialesson/e2e-devops-for-azure-sql-with-managed-identities-f2231c7e964c)

Create a group for db admins:

``` Powershell
az ad group create --display-name DbAdmins --mail-nickname DbAdmins
```

Add the service principal used for deployment to the group:
Object id is the object id for the service principal, not the pp registration itself. 
The object id can be found under the registration in Enterprise Application

``` Powershell
az ad group member add --group DbAdmins --member-id <Object id>
```

The sql server needs aad Directory Reader role so it can read service principal data from the aad. 
A Global Administrator or Privileged Role Administrator and grant this role, so the sp that i  used for the pipeline needs Privileged Role Administrator. 
This can eb done manually from 'aad -> Roles and administrators -> Search for Privileged Role Administrator -> add the sp to this role' 


Steps:
- Add system assigned identity for app service
- Add a dbadmin group as Azure Active Directory admin
- Enable "Support only aad authentication for the server

