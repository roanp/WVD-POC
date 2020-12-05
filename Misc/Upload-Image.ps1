

<# 

This is not a script but a set of commands to run in order

Do not run this straigh from powershel but lauch on ISE or Code and run line by line

Also Make sure you are connected to azure and select the select the subscription you want the IMg goin to

As well make sure your image has been sysprepd.

#>

#Region Variables
$VhdxPath = "C:\RSDH.VHDX"
$VhdPath = "C:\RSDH.VHD" <#Path for your VDH#>
$ResourceGroup = 'RG-AE-Infra-Core'
$OSDiskName = 'IMG-AE-WVD'
$ResourceGroup = 'RG-AE-Infra-Core'
$OSDiskName = 'IMG-AE-WVD'

#EndRegion Variables

#Region Corvert VDHX to VHD
Convert-VHD –Path $VhdxPath –DestinationPath $VhdPath -VHDType Fixed

#EndRegion


#Region  Upload to Azure 
$vhdSizeBytes = (Get-Item $VhdPath).length
$diskconfig = New-AzDiskConfig -SkuName 'Standard_LRS' -OsType 'Windows' -HyperVGeneration "V1" -UploadSizeInBytes $vhdSizeBytes -Location 'australiaeast' -CreateOption 'Upload'

New-AzDisk -ResourceGroupName $ResourceGroup -DiskName $OSDiskName -Disk $diskconfig
$diskSas = Grant-AzDiskAccess -ResourceGroupName $ResourceGroup  -DiskName $OSDiskName -DurationInSecond 86400 -Access 'Write'
$disk = Get-AzDisk -ResourceGroupName $ResourceGroup  -DiskName  $OSDiskName
AzCopy copy $VhdPath $diskSas.AccessSAS --blob-type PageBlob
Revoke-AzDiskAccess -ResourceGroupName $ResourceGroup -DiskName $OSDiskName
#EndRegion


#Region creating the IMAGE

$rgName = 'RG-AE-Infra-Core'
$location = "australiaeast"
$imageName = "IMG-AE-W2019-RPF-Desktop"
$diskID = $disk.Id
$imageConfig = New-AzImageConfig -Location $location
$imageConfig = Set-AzImageOsDisk -Image $imageConfig -OsState Generalized -OsType Windows -ManagedDiskId $diskID
New-AzImage -ImageName $imageName -ResourceGroupName $rgName -Image $imageConfig

#End Region