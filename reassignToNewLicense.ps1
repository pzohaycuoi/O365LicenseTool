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
      counter = $counter
      skuPartNumber = $option.skuPartNumber
      productName = $option.productName }
    $avaListOption += $hashTableProcData
  }
  Return $avaListOption
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
    $hashTableProcData = [PSCustomObject]@{
      userPN = $userpn
      skupartnumber = $userSpecifiedSku 
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
    $productName = ($avaListOption | Where-Object { $_.skuPartNumber -eq $user.skuPartNumber }).productName
    $hashTableProcData = [PSCustomObject]@{
      userPN = $user.userPN
      skuPartNumber = $user.skuPartNumber
      productName = $productName 
    }
    $userSkuProductName += $hashTableProcData
  }
  return $userSkuProductName
}

# Create csv file function
function createCsvFile($fileName, $productName) {
  # Process file name - add timestamp to file name
  $fileLogDate = (Get-Date -Format yy-mm-dd_HH-mm-ss)
  $procedFileName = "$fileName" + "_" + "$productName" + "_" + "$fileLogDate.csv" # csv file name
  # Create csv file for repot
  $finalFileName = (New-Item -Path filesystem::.\ -Name $procedFileName -ItemType "file").Name
  Return $finalFileName
}

function importExportedCsv($fileName) {
  $importExpCsv = Import-csv -Path filesystem::.\$fileName
  Write-Host "Completed importing file: "$fileName
  return $importExpCsv
}

# Combine assign and unassign with exported list so the action function can be simplifed
function exportAssPlan($selectedProductAssign, $exportUserWithSpecLic) {
  $exportedUserWithSpecLic = Import-Csv -Path filesystem::.\$exportUserWithSpecLic
  $combinedList = @()
  foreach ($user in $exportedUserWithSpecLic) {
    $hashTableProcData = [PSCustomObject]@{
      userPN = $user.userPN
      currentSkuPartNumber = $user.skuPartNumber
      currentProductName = $user.productName
      AssignProductName = $selectedProductAssign.productName
    }
    $combinedList += $hashTableProcData
  }
  Return $combinedList
}

# Assign license to user
function assignLicense($combinedCsv, $avaListOption) {
  foreach ($user in $combinedCsv) {
    # Check if license exsit yet
    $selectedProductAssign = ($avaListOption | Where-Object { $_ -eq $user.AssignProductName}).skuPartNumber
    $checkCurLic = (Get-MsolUser -UserPrincipalName $user.userPN).licenses.accountSku.skuPartNumber | Where-Object {$_ -eq $selectedProductAssign}
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
  [System.Console]::ReadKey($true)
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
function UIExportUserWithSpecLic($skuPartNumber, $avaListOption, $fileName) {
  Write-Host "Export user with License: "$skuPartNumber.productName -ForegroundColor Yellow
  Write-Host "Exporting...."
  $userAndSku = getUserWithSpecifiedSku $skuPartNumber.skuPartnumber
  $userSkuProductName = getUserSkuProductName $userAndSku $avaListOption
  $finalFileName = createCsvFile $fileName $skuPartNumber.productName
  $userSkuProductName | Export-Csv -Path filesystem::.\$finalFileName -Force -Append -NoTypeInformation
  Write-Host "Done Exporting, file name is: "$finalFilename -ForegroundColor Yellow
  Write-Host "Press any key to continue" -ForegroundColor Yellow
  $keyStroke = readKey # Don't mind this, added this becasue system console will pipe into previous var => prevent that
  return $finalFileName
}

# clgt #
#------------------------------------------------------------------------------------------------#
function UIExportCombinedList($selectedProductAssign, $importUserProductExport, $fileName) {
  Write-Host "Exporting Plan" -ForegroundColor Yellow
  Write-Host "Exporting..."
  $combinedList = assAndUnassPlan $selectedProductAssign $importUserProductExport
  $finalFileName = createCsvFile $fileName $selectedProductExport.productName
  $combinedList | Export-Csv -Path filesystem::.\$finalFileName -Force -Append -NoTypeInformation
  Write-Host "Done Exporting, file name is: "$finalFileName -ForegroundColor Yellow
  Write-Host "Please review the plan first" -ForegroundColor Yellow
  do {
    $keyStroke = readKey
    Write-Host "Press ""Y"" to continue" -ForegroundColor Yellow
  } until ("y" -eq $keyStroke)
  return $finalFileName
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
        Write-Host "Choose user with specific license to assign to" -ForegroundColor Yellow
        Write-Host "Please choose product to export list of user with the license"
        $selectedProductExport = UILicenseOption $choseOption $avaListOption
        Clear-Host
        $exportUserWithSpecLic = UIExportUserWithSpecLic $selectedProductAssign $avaListOption "userWithLicsense"
        Clear-Host
        $exportPlan = UIExportCombinedList $selectedProductExport $exportUserWithSpecLic "assignPlan"
        Clear-Host
        Write-Host "Importing csv file: "$exportPlan -ForegroundColor Yellow
        $importUserProductExport = importExportedCsv $exportPlan
        Write-Host "Assigning: "$selectedProductAssign.productName" - to user with license: "$selectedProductExport.ProductName -ForegroundColor Yellow
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
        Write-Host "Un-assign license to user with specific license" -ForegroundColor Yellow
        Write-Host "Please choose product to Un-assign" -ForegroundColor Yellow
        $selectedProductAssign = UILicenseOption $choseOption $avaListOption
        Clear-Host
        Write-Host "Choose user with specific license to Un-assign to" -ForegroundColor Yellow
        Write-Host "Please choose product to export list of user with the license"
        $selectedProductExport = UILicenseOption $choseOption $avaListOption
        Clear-Host
        $exportUserWithSpecLic = UIExportUserWithSpecLic $selectedProductAssign $avaListOption "userWithLicsense"
        Clear-Host
        $exportPlan = UIExportCombinedList $selectedProductExport $exportUserWithSpecLic "unassignPlan"
        Clear-Host
        Write-Host "Importing csv file: "$exportPlan -ForegroundColor Yellow
        $importUserProductExport = importExportedCsv $exportPlan
        Write-Host "Un-assigning: "$selectedProductAssign.productName" - to user with license: "$selectedProductExport.ProductName -ForegroundColor Yellow
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