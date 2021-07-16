function createCsvFile($fileName) {
  # Process file name - add timestamp to file name
  $fileLogDate = (Get-Date -Format yyyy-mm-dd_HH-mm-ss)
  $procedFileName = "$fileName" + "_" + "$fileLogDate.csv" # csv file name
  # create File
  $finalFileName = (New-Item -Path filesystem::.\ -Name $procedFileName -ItemType "file").Name
  Return $finalFileName
}

function getUserWithSpecifiedSku($sku) {
  # Create csv file for repot
  $fileName = createCsvFile "userList_$sku"
  # Export user list with specified license
  $userWithSkuList = Get-MsolUser -All | Where-Object { $_.Licenses.AccountSku.SkuPartNumber -eq $sku } | Select-Object UserPrincipalName, Licenses
  # Empty hash table to store proccessed data
  $userPNAndSpecifiedTable = @{}
  foreach ($user in $userWithSkuList) {
    $userpn = $user.UserPrincipalName
    # Get specified sku name (sku name is diffrent to product name)
    $userSpecifiedSku = $user.licenses.accountsku.skupartnumber | Where-Object {$_ -eq $sku}
    $userPNAndSpecifiedTable.Add($userpn, $userSpecifiedSku)
  }
  # Process key, value to more friendly name
  $userPNAndSpecifiedTable.GetEnumerator() | Select-Object -Property @{N="UserPN";E={$_.Key}}, @{N="License";E={$_.Value}} | 
                                            Export-Csv -Path filesystem::.\$fileName -Append -Force -NoTypeInformation
}
$sku = "MICROSOFT_REMOTE_ASSIST"
getUserWithSpecifiedSku $sku