param (
    [Parameter(Mandatory=$true)]
    [string]
    $roleDefinitionId,
     [Parameter(Mandatory=$false)]
     [string]
     $principalId
)

try {
    $token = $(az account get-access-token --resource https://graph.microsoft.com --query accessToken --output tsv)
}
catch {
    Write-Error "Could not login"
    exit 1
}

$headers = @{
    'Content-Type' = 'application/json'; 
    'Authorization' = 'Bearer ' + $token 
}

$body=@"
{ 
    "@odata.type": "#microsoft.graph.unifiedRoleAssignment",
    "roleDefinitionId": "$($roleDefinitionId)",
    "principalId": "$($principalId)",
    "directoryScopeId": "/"
}
"@

$urlListRoleAssignments = 'https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignments?$filter=roleDefinitionId eq ' + "'" + $roleDefinitionId + "'"

$response = Invoke-RestMethod -Method GET -Headers $headers -Uri $urlListRoleAssignments

foreach ($principal in $response.value) {
    if ( $principal.principalId -eq $principalId ) {
        Write-Host "Role is already assigned to the service principal"
        exit 0
    }
}

$urlSetRoleAssignment = "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignments"

Write-Host $token

Invoke-RestMethod -Method POST -Headers $headers -Uri $urlSetRoleAssignment -Body $body
Write-Host "Successfully added role to service principal"

# Wait 30 sec so that the new permission gets set cprroin aad
Start-Sleep -Seconds 30
