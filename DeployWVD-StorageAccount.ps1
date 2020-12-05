


#Login with an Azure AD credential that has either storage account owner or contributer Azure role assignment
Connect-AzAccount

#Define parameters
$SubscriptionId = "bf3e61e9-2044-4133-aec6-32c31af41210"
$ResourceGroupName = "RG-AE-WVD"
$StorageAccountName = "saeuswvd001"
$AdOU = "OU=AzFilesShare,OU=Servers,OU=RoanPaesTech,DC=Rpaes,DC=Corp" 
$ShareName = "profile"
$PrincipalName = "" #An admin user within the organization so they can set up the NTFS permissions.
$location = "eastus"
$WvdGroupName = "Windows Virtual Desktop Users"

#Select the target subscription for the current session
Select-AzSubscription -SubscriptionId $SubscriptionId 


#region Create the Resource group
New-AzResourceGroup -Name $ResourceGroupName -Location $Location  
#endregion


#region Create the storage account
New-AzStorageAccount -ResourceGroupName $ResourceGroupName `
  -Name $StorageAccountName `
  -Location $Location `
  -SkuName Standard_LRS `
  -Kind StorageV2
#endregion


#region Ad join the storage account
# Register the target storage account with your active directory environment under the target OU (for example: specify the OU with Name as "UserAccounts" or DistinguishedName as "OU=UserAccounts,DC=CONTOSO,DC=COM"). 
# You can use to this PowerShell cmdlet: Get-ADOrganizationalUnit to find the Name and DistinguishedName of your target OU. If you are using the OU Name, specify it with -OrganizationalUnitName as shown below. If you are using the OU DistinguishedName, you can set it with -OrganizationalUnitDistinguishedName. You can choose to provide one of the two names to specify the target OU.
# You can choose to create the identity that represents the storage account as either a Service Logon Account or Computer Account (default parameter value), depends on the AD permission you have and preference. 
# Run Get-Help Join-AzStorageAccountForAuth for more details on this cmdlet.

#Install the module from https://github.com/Azure-Samples/azure-files-samples/releases/latest/
#Then extract the ZIP file, access the folder where the files where extracted and run the .\CopyToPSPath.ps1 file

Import-Module -Name AzFilesHybrid

Join-AzStorageAccountForAuth `
        -ResourceGroupName $ResourceGroupName `
        -StorageAccountName $StorageAccountName `
        -DomainAccountType "ComputerAccount" -OverwriteExistingADObject <# Default is set as ComputerAccount #> `
        -OrganizationalUnitDistinguishedName $AdOU  <# If you don't provide the OU name as an input parameter, the AD identity that represents the storage account is created under the root directory. #> `
        #-EncryptionType "<AES,RC4/AES/RC4>" <# Specify the encryption agorithm used for Kerberos authentication. Default is configured as "'RC4','AES256'" which supports both 'RC4' and 'AES256' encryption. #>

#endregion

#region Creating the share
$StorageAccountPassword = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value
$StorageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountPassword
New-AzStorageShare -Name $ShareName -Context $StorageContext 
#endregion



#region Role Permissions to the share
$FileShareContributorRole = Get-AzRoleDefinition "Storage File Data SMB Share Elevated Contributor" #Use one of the built-in roles: Storage File Data SMB Share Reader, Storage File Data SMB Share Contributor, Storage File Data SMB Share Elevated Contributor
#Constrain the scope to the target file share
$scope = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Storage/storageAccounts/$StorageAccountName/fileServices/default/fileshares/$ShareName"
#Assign the custom role to the target identity with the specified scope.
$RoleId = (Get-AzADGroup -SearchString $WvdGroupName).ID
New-AzRoleAssignment -ObjectId $RoleId -RoleDefinitionName $FileShareContributorRole.Name -Scope $scope

#endregion




#region NTFS perms
$StorageAccountPassword = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value
$StorageAccountNameURI = $StorageAccountName+".file.core.windows.net"
$StorageSharePathURL = "\\"+$StorageAccountNameURI+"\"+$ShareName
$connectTestResult = Test-NetConnection -ComputerName $StorageAccountNameURI -Port 445

net use z: $StorageSharePathURL /user:Azure\$StorageAccountName $StorageAccountPassword

cmd /c icacls Z: /grant "Windows Virtual Desktop Users:(OI)(CI)(IO)(M)" #make sure the group name is correct.
cmd /c icacls z: /grant "Creator Owner:(OI)(CI)(IO)(M)"
cmd /c icacls z: /remove "Authenticated Users"
cmd /c icacls z: /remove "Builtin\Users"



#endregion

#region Create utility folder and push Utility Files
New-Item -ItemType Directory -Path  $StorageSharePathURL -Name "Utility"
Copy-Item  -Path .\FsLogix\Redirections.xml -Destination "$StorageSharePathURL\Utility" -Force
Copy-Item  -Path .\Misc\layoutmodification.xml -Destination "$StorageSharePathURL\Utility" -Force
cmd /c icacls "$StorageSharePathURL\Utility" /remove "Windows Virtual Desktop Users"
cmd /c icacls "$StorageSharePathURL\Utility" /grant "Windows Virtual Desktop Users:(OI)(CI)(IO)(M)" 

#endregion