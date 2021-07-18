function createCsvFile($fileName, $productName) {
  # Process file name - add timestamp to file name
  $fileLogDate = (Get-Date -Format yyyy-mm-dd_HH-mm-ss)
  $procedFileName = "$fileName" + "_" + "$productName" + "_" + "$fileLogDate.csv" # csv file name
  # Create csv file for repot
  $finalFileName = (New-Item -Path filesystem::.\ -Name $procedFileName -ItemType "file").Name
  Return $finalFileName
}

function importExportedCsv($finalFileName) {
  $importExpCsv = Import-csv -Path filesystem::.\$finalFileName
  return $importExpCsv
}

# Export csv file for user with specified sku
function getUserWithSpecifiedSku($skuPartNumber) {
  # Export user list with specified license
  $userWithSkuList = Get-MsolUser -All | Where-Object { $_.Licenses.AccountSku.SkuPartNumber -eq $skuPartNumber } | Select-Object UserPrincipalName, Licenses
  # Empty hash table to store proccessed data
  $userAndSku = @()
  foreach ($user in $userWithSkuList) {
    $userpn = $user.UserPrincipalName
    # Get specified sku name (sku name is diffrent to product name)
    $userSpecifiedSku = $user.licenses.accountsku.skupartnumber | Where-Object { $_ -eq $skuPartNumber }
    $hashTableProcData = [PSCustomObject]@{userPN = $userpn; skupartnumber = $userSpecifiedSku }
    $userAndSku += $hashTableProcData
  }
  # Process key, value to more friendly name
  return $userAndSku
}

# Provide license option base on skuFriendlyName.csv
function provideAvailableLicenseOption() {
  $importAvaLicOption = Import-Csv -Path filesystem::.\skuFriendlyName.csv
  $counter = 0
  $avaListOption = @()
  # add counter into hash table for UILicenseOption option
  foreach ($option in $importAvaLicOption) {
    $counter ++
    $hashTableProcData = [PSCustomObject]@{counter = $counter; skuPartNumber = $option.skuPartNumber; productName = $option.productName }
    $avaListOption += $hashTableProcData
  }
  Return $avaListOption
}

# Combine user principal name, skupartnumber and product name for further process
function getUserSkuProductName($userAndSku, $avaListOption) {
  $userSkuProductName = @()
  foreach ($user in $userAndSku) {
    $productName = $avaListOption | Where-Object { $avaListOption.skuPartNumber -eq $skuPartNumber }
    $productName = $productName | Select-Object productName
    $hashTableProcData = [PSCustomObject]@{userPN = $user.userPN; skuPartNumber = $user.skuPartNumber; productName = $productName }
    $userSkuProductName += $hashTableProcData
  }
  return $userSkuProductName
}

$sku = "MICROSOFT_REMOTE_ASSIST"
$userAndSku = getUserWithSpecifiedSku $sku
$avaListOption = provideAvailableLicenseOption
$userSkuProductName = getUserSkuProductName $userAndSku $avaListOption
$userSkuProductName | Export-Csv filesystem::.\ak.csv -Append -Force -NoTypeInformation
