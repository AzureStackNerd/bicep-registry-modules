metadata name = 'Data Protection Backup Vault Backup Instances'
metadata description = 'This module deploys a Data Protection Backup Vault Backup Instance.'

@description('Conditional. The name of the parent Backup Vault. Required if the template is used in a standalone deployment.')
param backupVaultName string

@description('Required. The name of the backup instance.')
param name string

@description('Optional. The friendly name of the backup instance.')
param friendlyName string?

@description('Required. Gets or sets the data source information.')
param dataSourceInfo dataSourceInfoType

@description('Required. Gets or sets the policy information.')
param policyInfo policyInfoType

resource backupVault 'Microsoft.DataProtection/backupVaults@2023-05-01' existing = {
  name: backupVaultName

  resource backupPolicy 'backupPolicies@2023-05-01' existing = {
    name: policyInfo.policyName
  }
}

module backupInstance_dataSourceResource_rbac 'modules/nested_dataSourceResourceRoleAssignment.bicep' = {
  name: '${deployment().name}-RBAC'
  scope: resourceGroup(split(dataSourceInfo.resourceID, '/')[4])
  params: {
    resourceId: dataSourceInfo.resourceID
    principalId: backupVault.identity.principalId
  }
}

resource backupInstance 'Microsoft.DataProtection/backupVaults/backupInstances@2024-04-01' = {
  name: name
  parent: backupVault
  properties: {
    friendlyName: friendlyName
    objectType: 'BackupInstance'
    dataSourceInfo: union(dataSourceInfo, { objectType: 'Datasource' })
    policyInfo: {
      policyId: backupVault::backupPolicy.id
      policyParameters: policyInfo.policyParameters
    }
  }
  dependsOn: [
    backupInstance_dataSourceResource_rbac
  ]
}

@description('The name of the backup instance.')
output name string = backupInstance.name

@description('The resource ID of the backup instance.')
output resourceId string = backupInstance.id

@description('The name of the resource group the backup instance was created in.')
output resourceGroupName string = resourceGroup().name

// =============== //
//   Definitions   //
// =============== //

@export()
@description('The type for backup instance data source info properties.')
type dataSourceInfoType = {
  @description('Required. The data source type of the resource.')
  datasourceType: string

  @description('Required. The resource ID of the resource.')
  resourceID: string

  @description('Required. The location of the data source.')
  resourceLocation: string

  @description('Required. Unique identifier of the resource in the context of parent.')
  resourceName: string

  @description('Required. The resource type of the data source.')
  resourceType: string

  @description('Required. The Uri of the resource.')
  resourceUri: string
}

@export()
@description('The type for backup instance policy info properties.')
type policyInfoType = {
  @description('Required. The name of the backup instance policy.')
  policyName: string

  @description('Required. Policy parameters for the backup instance.')
  policyParameters: object
}
