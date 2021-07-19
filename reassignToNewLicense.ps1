##################################################################################################
# Function #
##################################################################################################
# Make sure get-credential work
function getCredential() {
  $getTheCredentials = Get-Credential
  # Check if getCredential got any info or not
  if ($?) {
    return $true
  }
  else {
    return $false
  }
  Return $getTheCredentials
}

# Check login state
function loginService($logonCredential) {
  Connect-MsolService -Credential $logonCredential -ErrorAction SilentlyContinue
  # Check if login success or not
  Get-MsolDomain -ErrorAction SilentlyContinue
  if ($?) {
    return $true
  }
  else {
    return $false
  }
}

function makeSureGetCredentialWork() {

}

function readKey() {
  $keyStroke = [System.Console]::ReadKey($true)
  $keyStroke = ($keyStroke).key
  return $keyStroke
}

# Provide license option base on skuFriendlyName.csv
function provideAvailableLicenseOption() {
  $importAvaLicOption = Import-Csv -Path filesystem::.\skuFriendlyName.csv
  $counter = 0
  $avaListOption = @()
  # add counter into hash table for UILicenseOption option
  foreach ($option in $importAvaLicOption) {
    $counter ++
    $hashTableProcData = [PSCustomObject]@{
      counter      = $counter
      accountSkuId = $option.accountSkuId
      productName  = $option.productName 
    }
    $avaListOption += $hashTableProcData
  }
  Return $avaListOption
}

# Export csv file for user with specified sku
function getUserWithSpecifiedSku($accountSkuId) {
  # Export user list with specified license
  $userWithSkuList = Get-MsolUser -All | Where-Object { $_.Licenses.AccountSkuId -eq $accountSkuId } | Select-Object UserPrincipalName, Licenses
  # Empty hash table to store proccessed data
  $userAndSku = @()
  foreach ($user in $userWithSkuList) {
    $userpn = $user.UserPrincipalName
    # Get specified sku name (sku name is diffrent to product name)
    $userSpecifiedSku = $user.licenses.accountSkuId | Where-Object { $_ -eq $accountSkuId }
    $hashTableProcData = [PSCustomObject]@{
      userPN       = $userpn
      accountSkuId = $userSpecifiedSku 
    }
    $userAndSku += $hashTableProcData
  }
  # Process key, value to more friendly name
  return $userAndSku
}

# Combine user principal name, skupartnumber and product name for further process
function getUserSkuProductName($userAndSku, $avaListOption) {
  $userSkuProductName = @()
  foreach ($user in $userAndSku) {
    $productName = ($avaListOption | Where-Object { $_.accountSkuId -eq $user.accountSkuId }).productName
    $hashTableProcData = [PSCustomObject]@{
      userPN       = $user.userPN
      accountSkuId = $user.accountSkuId
      productName  = $productName 
    }
    $userSkuProductName += $hashTableProcData
  }
  return $userSkuProductName
}

# Create csv file function
function createCsvFile($fileName, $productName) {
  # Process file name - add timestamp to file name
  $fileLogDate = (Get-Date -Format yy-MM-dd_HH-mm-ss)
  $procedFileName = "$fileName" + "_" + "$productName" + "_" + "$fileLogDate.csv" # csv file name
  # Create csv file for repot
  $finalFileName = (New-Item -Path filesystem::.\ -Name $procedFileName -ItemType "file").Name
  Return $finalFileName
}

function importExportedCsv($fileName) {
  $importExpCsv = Import-csv -Path filesystem::.\$fileName
  return $importExpCsv
}

# Combine assign with exported list so the action function can be simplifed
function exportAssPlan($selectedProductAssign, $exportUserWithSpecLic) {
  $exportedUserWithSpecLic = Import-Csv -Path filesystem::.\$exportUserWithSpecLic
  $combinedList = @()
  foreach ($user in $exportedUserWithSpecLic) {
    $hashTableProcData = [PSCustomObject]@{
      userPN              = $user.userPN
      currentAccountSkuId = $user.accountSkuId
      currentProductName  = $user.productName
      AssignProductName   = $selectedProductAssign.productName
    }
    $combinedList += $hashTableProcData
  }
  Return $combinedList
}

# Combine Un-assign with exported list so the action function can be simplifed
function exportUnassPlan($selectedProductUnassign, $exportUserWithSpecLic) {
  $exportedUserWithSpecLic = Import-Csv -Path filesystem::.\$exportUserWithSpecLic
  $combinedList = @()
  foreach ($user in $exportedUserWithSpecLic) {
    $hashTableProcData = [PSCustomObject]@{
      userPN              = $user.userPN
      currentAccountSkuId = $user.accountSkuId
      currentProductName  = $user.productName
      UnAssignProductName = $selectedProductUnassign.productName
    }
    $combinedList += $hashTableProcData
  }
  Return $combinedList
}

# Assign license to user
function assignLicense($combinedCsv, $avaListOption) {
  foreach ($user in $combinedCsv) {
    $selectedProductAssign = $avaListOption | Where-Object { $_.productName -eq $user.AssignProductName }
    #  Check if license exsit yet
    $checkIfExist = (Get-MsolUser -UserPrincipalName $user.userPN).licenses.accountSkuId | Where-Object { $_ -eq $selectedProductAssign.accountSkuId }
    if ($null -eq $checkIfExist) {
      # Set-MsolUserLicense -UserPrincipalName $user.userPN -AddLicenses $selectedProductAssign.accountSkuId
    }
    elseif ($null -ne $checkIfExist) {
      Write-Host $user.userPN" already have license: "$selectedProductAssign.productName
      Continue
    }
  }
}

function unAssignLicense($userPN, $oldLicense) {
  Set-MsolUserLicense -UserPrincipalName $userPN -RemoveLicenses $oldLicense
}

##################################################################################################
# Interface #
##################################################################################################

# Login UI #
#------------------------------------------------------------------------------------------------#
function UILogin() {
  Write-Host "Press any key to Login" -ForegroundColor Yellow
  $keyStroke = readKey
  # Login Office 365
  if ($null -eq $logonCredential) {
    do {
      Clear-Host
      Write-Host "Input login information" -ForegroundColor Yellow
      do {
        $logonCredential = Get-Credential
      } until ($true -eq $logonCredential)
      Write-Host "Connecting to Office 365..."
      $loginStatus = loginService $logonCredential
    } until ($true -eq $loginStatus)
  }
  # Login Succeed
  Write-Host "Login succeed" -ForegroundColor Yellow
  Start-Sleep -Seconds 3
  Write-Host "Press any key to continue" -ForegroundColor Yellow
  $keyStroke = readKey
}

# Choose option UI #
#------------------------------------------------------------------------------------------------#
function UIChoosingOption() {
  $optionArrary = @("A", "B", "C")
  do {
    Clear-Host
    Write-Host "Please choose option" -ForegroundColor Yellow
    Write-Host "A: Assign License"
    Write-Host "B: Un-assign License"
    Write-Host "C: Assign and Un-assign License"
    Write-Host -NoNewline "Input your option: "
    $keyStroke = readKey
    Start-Sleep -Seconds 1
  } until ($optionArrary -contains $keyStroke)
  Return $keyStroke
}

# Assign/Unassign License UI #
#------------------------------------------------------------------------------------------------#
function UIAssignUnassignLicense($UIOption) {
  if ("A" -eq $UIOption) {
    $optionArrary = @("A", "B")
    do {
      Write-Host "Please choose option" -ForegroundColor Yellow
      Write-Host "A: Assign license to user with specific license"
      Write-Host "B: Assign license to user from csv file"
      Write-Host -NoNewline "Input your option: "
      $keyStroke = readKey
    } until ($optionArrary -contains $keyStroke)
    Return $keyStroke
  }
  elseif ("B" -eq $UIOption) {
    $optionArrary = @("A", "B")
    do {
      Write-Host "Please choose option" -ForegroundColor Yellow
      Write-Host "A: Un-assign license from user with specific license"
      Write-Host "B: Un-assign license from user from csv file"
      Write-Host -NoNewline "Input your option: "
      $keyStroke = readKey
    } until ($optionArrary -contains $keyStroke)
    Return $keyStroke
  }
}

# Choose License UI #
#------------------------------------------------------------------------------------------------#
# tạo ra custom object dựa trên cái file skuFriendlyName.csv
# kiểu có bao nhiêu row thì nó tự generate ra đến đấy
function UILicenseOption($choseOption, $avaListOption) {
  do {
    $optionArrary = @()
    foreach ($option in $avaListOption) {
      $optionArrary += $option.counter
      Write-Host $option.counter ":" $option.ProductName
    }
    Write-Host ""
    $enteredOption = Read-Host "Input your option: "
  } until ($optionArrary -contains $enteredOption)
  $selectedOption = $avaListOption | Where-Object { $_.counter -eq $enteredOption }
  return $selectedOption
}

# Export csv UI#
#------------------------------------------------------------------------------------------------#
function UIExportUserWithSpecLic($accountSkuId, $avaListOption, $fileName) {
  Write-Host "Export user with License: "$skuPartNumber.productName -ForegroundColor Yellow
  Write-Host "Exporting...."
  $userAndSku = getUserWithSpecifiedSku $accountSkuId.accountSkuId
  $userSkuProductName = getUserSkuProductName $userAndSku $avaListOption
  $finalFileName = createCsvFile $fileName $accountSkuId.productName
  $userSkuProductName | Export-Csv -Path filesystem::.\$finalFileName -Force -Append -NoTypeInformation
  Write-Host "Done Exporting, file name is: "$finalFilename -ForegroundColor Yellow
  Write-Host "Press any key to continue" -ForegroundColor Yellow
  $keyStroke = readKey # Don't mind this, added this becasue system console will pipe into previous var => prevent that
  return $finalFileName
}

# Export assign plan combined csv #
#------------------------------------------------------------------------------------------------#
function UIExportAssCombinedList($selectedProductAssign, $importUserProductExport, $fileName) {
  Write-Host "Exporting Plan" -ForegroundColor Yellow
  Write-Host "Exporting..."
  $combinedList = exportAssPlan $selectedProductAssign $importUserProductExport
  $finalFileName = createCsvFile $fileName $selectedProductAssign.productName
  $combinedList | Export-Csv -Path filesystem::.\$finalFileName -Force -Append -NoTypeInformation
  Write-Host "Done Exporting, file name is: "$finalFileName -ForegroundColor Yellow
  Write-Host "Please review the plan first" -ForegroundColor Yellow
  Write-Host "Press any key to promt confirm line" -ForegroundColor Yellow
  do {
    $keyStroke = readKey
    Write-Host "Press ""Y"" to continue" -ForegroundColor Yellow
  } until ("y" -eq $keyStroke)
  return $finalFileName
}

# Export Uassign plan combined csv #
#------------------------------------------------------------------------------------------------#
function UIExportUnassCombinedList($selectedProductUnassign, $importUserProductExport, $fileName) {
  Write-Host "Exporting Plan" -ForegroundColor Yellow
  Write-Host "Exporting..."
  $combinedList = exportUnassPlan $selectedProductUnassign $importUserProductExport
  $finalFileName = createCsvFile $fileName $selectedProductUnassign.productName
  $combinedList | Export-Csv -Path filesystem::.\$finalFileName -Force -Append -NoTypeInformation
  Write-Host "Done Exporting, file name is: "$finalFileName -ForegroundColor Yellow
  Write-Host "Please review the plan first" -ForegroundColor Yellow
  Write-Host "Press any key to promt confirm line" -ForegroundColor Yellow
  do {
    $keyStroke = readKey
    Write-Host "Press ""Y"" to continue" -ForegroundColor Yellow
  } until ("y" -eq $keyStroke)
  return $finalFileName
}

# Import csv UI #
#------------------------------------------------------------------------------------------------#
function UIImportCsv($csvFile) {
  Write-Host "Importing csv file: "$exportPlan -ForegroundColor Yellow
  $importedCsv = importExportedCsv $csvFile
  Write-Host "Completed importing file: "$fileName
  Return $importedCsv
}

# Assign license UI #
#------------------------------------------------------------------------------------------------#
function UIAssignLic($combinedCsv, $avaListOption) {
  Write-Host "Assigning license..."
  assignLicense $combinedCsv $avaListOption
  Write-Host "Done" -ForegroundColor Yellow
  $keyStroke = readKey
}

##################################################################################################
# ACTION GOES HERE YEY #
##################################################################################################
# UILogin
$avaListOption = provideAvailableLicenseOption
$choseOption = UIChoosingOption
switch ($choseOption) {
  "A" {
    Clear-Host
    Write-Host "Assign Licsense" -ForegroundColor Yellow
    $importFromOption = UIAssignUnassignLicense $choseOption
    switch ($importFromOption) {
      "A" {
        Clear-Host
        Write-Host "Assign license to user with specific license" -ForegroundColor Yellow
        Write-Host "Please choose product to assign" -ForegroundColor Yellow
        $selectedProductAssign = UILicenseOption $choseOption $avaListOption
        Clear-Host
        Write-Host "Choose users with specific license to assign to" -ForegroundColor Yellow
        Write-Host "Please choose product to export list of user with the license" -ForegroundColor Yellow
        $selectedProductExport = UILicenseOption $choseOption $avaListOption
        Clear-Host
        $exportUserWithSpecLic = UIExportUserWithSpecLic $selectedProductExport $avaListOption "userWithLicsense"
        Clear-Host
        $exportPlan = UIExportAssCombinedList $selectedProductAssign $exportUserWithSpecLic "assignPlan"
        Clear-Host
        $importPlan = UIImportCsv $exportPlan
        Write-Host "Assigning: "$selectedProductAssign.productName -ForegroundColor Yellow
        Write-Host "To user with license: "$selectedProductExport.ProductName -ForegroundColor Yellow
        UIAssignLic $importPlan $avaListOption 
      }
      "B" {
        Clear-Host
        Write-Host "Assign license to user from csv file" -ForegroundColor Yellow
        
        Write-Host "Please choose product to assign" -ForegroundColor Yellow
        $selectedOption = UILicenseOption $choseOption $avaListOption
      }
    }
  }
  "B" {
    Clear-Host
    Write-Host "Un-assign Licsense" -ForegroundColor Yellow
    $importFromOption = UIAssignUnassignLicense $choseOption
    switch ($importFromOption) {
      "A" {
        Clear-Host
        Write-Host "Un-Assign license to user with specific license" -ForegroundColor Yellow
        Write-Host "Please choose product to Un-assign" -ForegroundColor Yellow
        $selectedProductUnassign = UILicenseOption $choseOption $avaListOption
        Clear-Host
        Write-Host "Choose users with specific license to Un-assign from" -ForegroundColor Yellow
        Write-Host "Please choose product to export list of user with the license" -ForegroundColor Yellow
        $selectedProductExport = UILicenseOption $choseOption $avaListOption
        Clear-Host
        $exportUserWithSpecLic = UIExportUserWithSpecLic $selectedProductExport $avaListOption "userWithLicsense"
        Clear-Host
        $exportPlan = UIExportUnassCombinedList $selectedProductUnassign $exportUserWithSpecLic "assignPlan"
        Clear-Host
        $importPlan = UIImportCsv $exportPlan
        Write-Host "Un-Assigning: "$selectedProductUnassign.productName -ForegroundColor Yellow
        Write-Host "From user with license: "$selectedProductExport.ProductName -ForegroundColor Yellow
        UIAssignLic $importPlan $avaListOption 
      }
      "B" {
        $selectedOption = UILicenseOption $choseOption $avaListOption
      }
    }
  }
  "C" {
    Clear-Host
    Write-Host "Assign and Un-assign Licsense" -ForegroundColor Yellow
  }
}