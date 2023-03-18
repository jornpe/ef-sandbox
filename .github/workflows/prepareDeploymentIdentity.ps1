param (
    [Parameter(Mandatory=$true)]
    [string]
    $SubscriptionId,
     [Parameter(Mandatory=$false)]
     [string]
     $AppRegistrationName
)

# https://learn.microsoft.com/en-us/azure/active-directory/roles/permissions-reference#privileged-role-administrator
$privilegedRoleAdministratorRoleId = "e8611ab8-c189-46e8-94e1-60213ab1f814"

# Create service principal in aad
$app = ( az ad sp create-for-rbac --role Contributor --scope /subscriptions/$SubscriptionId --name $AppRegistrationName --sdk-auth ) | ConvertFrom-Json
$app | ConvertTo-Json | Out-File -FilePath '.\Github-Secret.json'
Write-Host "App registration complete, credentials saved to $PSScriptRoot\Github-Secret.json" -ForegroundColor Green

# Add roles to the service principal
$sp = ( az ad sp list --display-name $AppRegistrationName ) | ConvertFrom-Json
az role assignment create --role Microsoft.Authorization/roleAssignments.Read.Write --scope /subscriptions/$SubscriptionId --assignee $sp.appId | Out-Null

# Get assign-sp-ad-roles.ps1 path and use it to assign 
$rolesAssignmentScriptPath = (get-item $PSScriptRoot).parent.parent.FullName + "\infrastructure\assign-sp-ad-roles.ps1"
. $rolesAssignmentScriptPath -roleDefinitionId $privilegedRoleAdministratorRoleId -principalId $sp.id
