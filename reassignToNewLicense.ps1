##################################################################################################
# Function #
##################################################################################################

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
  $avaListOption = @()
  $counter = 0
  # add counter into hash table for UILicenseOption option
  foreach ($option in $importAvaLicOption) {
    $counter ++
    $avaListOption += New-Object -TypeName psobject -Property @{counter = $counter; skupartnumber = $option.skupartnumber; productName = $option.ProductName }
  }
  Return $avaListOption
}

# Export csv file for user with specified sku
function getUserWithSpecifiedSku($sku) {
  # Export user list with specified license
  $userWithSkuList = Get-MsolUser -All | Where-Object { $_.Licenses.AccountSku.SkuPartNumber -eq $sku } | Select-Object UserPrincipalName, Licenses
  # Empty hash table to store proccessed data
  $userAndSku = @()
  foreach ($user in $userWithSkuList) {
    $userpn = $user.UserPrincipalName
    # Get specified sku name (sku name is diffrent to product name)
    $userSpecifiedSku = $user.licenses.accountsku.skupartnumber | Where-Object { $_ -eq $sku }
    $userAndSku += New-Object -TypeName psobject -Property @{userPN = $userpn; skupartnumber = $userSpecifiedSku}
  }
  # Process key, value to more friendly name
  return $userAndSku
}

# Combine user principal name, skupartnumber and product name for further process
function getUserSkuProductName($userAndSku, $avaListOption) {
  $userSkuProductName = @()
  foreach ($user in $userAndSku) {
    $productName = $userAndSku | Where-Object {$_.skupartnumber -eq $user.skupartnumber}
    $userSkuProductName += New-Object -TypeName psobject @{userPN = $user.userPN; skupartnumber = $user.skupartnumber; productName = $productName.productName}
  }
  return $userSkuProductName
}

# Create csv file function
function createCsvFile($fileName, $productName) {
  # Process file name - add timestamp to file name
  $fileLogDate = (Get-Date -Format yyyy-mm-dd_HH-mm-ss)
  $procedFileName = "$fileName" + "_" + "$productName" + "_" + "$fileLogDate.csv" # csv file name
  # Create csv file for repot
  $finalFileName = (New-Item -Path filesystem::.\ -Name $procedFileName -ItemType "file").Name
  Return $finalFileName
}

function assignLicense($userPN, $newLicense) {
  Set-MsolUserLicense -UserPrincipalName $userPN -AddLicenses $newLicense
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
  Write-Host "Press any button to Login" -ForegroundColor Yellow
  [System.Console]::ReadKey($true)
  # Login Office 365
  if ($null -eq $logonCredential) {
    do {
      Clear-Host
      Write-Host "Input login information" -ForegroundColor Yellow
      $logonCredential = Get-Credential
      Write-Host "Connecting to Office 365..."
      $loginStatus = loginService $logonCredential
    } until ($true -eq $loginStatus)
  }
  # Login Succeed
  Write-Host "Login succeed" -ForegroundColor Yellow
  Start-Sleep -Seconds 3
  Write-Host "Press any button to continue" -ForegroundColor Yellow
  [System.Console]::ReadKey($true)
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
      Clear-Host
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
      Clear-Host
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
function UILicenseOption($choseOption, $licenseOptions) {
  do {
    Clear-Host
    $optionArrary = @()
    if ("A" -eq $choseOption) { 
      Write-Host "Assigning license" -ForegroundColor Yellow
      Write-Host "Please choose product to assign" -ForegroundColor Yellow
    }
    elseif ("B" -eq $choseOption) {
      Write-Host "Un-assigning license" -ForegroundColor Yellow
      Write-Host "Please choose product to un-assign" -ForegroundColor Yellow
    }
    foreach ($option in $licenseOptions) {
      $optionArrary += $option.counter
      Write-Host $option.counter ":" $option.ProductName
    }
    Write-Host ""
    $enteredOption = Read-Host "Input your option: "
  } until ($optionArrary -contains $enteredOption)
  $selectedOption = $licenseOptions | Where-Object { $_.counter -eq $enteredOption }
  $selectedOption
  return $selectedOption
}

# Export csv UI#
#------------------------------------------------------------------------------------------------#
function UIExportUserWithSpecLic($sku, $licenseOptions, $fileName) {
  $userAndSku = getUserWithSpecifiedSku $sku
  $userSkuProductName = getUserSkuProductName $userAndSku $licenseOptions
  $finalFileName = createCsvFile $fileName $userSkuProductName.productName
  $userSkuProductName | Export-csv -Path filesystem::.\$finalFileName -Force -NoTypeInformation -Append
}


##################################################################################################
# ACTION GOES HERE YEY #
##################################################################################################
UILogin
$licenseOptions = provideAvailableLicenseOption
$functionOption = UIChoosingOption
switch ($functionOption) {
  "A" {
    $importFromOption = UIAssignUnassignLicense $functionOption
    switch ($importFromOption) {
      "A" {
        $LicenseToExport = UILicenseOption $functionOption $licenseOptions
        $userAndSku = 
        
      }
      "B" {
        $LicenseToExport = UILicenseOption $functionOption $licenseOptions
      }
    }
  }
  "B" {
    $importFromOption = UIAssignUnassignLicense $functionOption
    switch ($importFromOption) {
      "A" {
        $LicenseToExport = UILicenseOption $functionOption $licenseOptions
      }
      "B" {
        $LicenseToExport = UILicenseOption $functionOption $licenseOptions
      }
    }
  }
  "C" {

  }
}