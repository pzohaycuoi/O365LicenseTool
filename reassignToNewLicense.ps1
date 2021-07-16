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

# Create csv file function
function createCsvFile($fileName) {
  # Process file name - add timestamp to file name
  $fileLogDate = (Get-Date -Format yyyy-mm-dd_HH-mm-ss)
  $procedFileName = "$fileName" + "_" + "$fileLogDate.csv" # csv file name
  # create File
  $finalFileName = (New-Item -Path filesystem::.\ -Name $procedFileName -ItemType "file").Name
  Return $finalFileName
}

# Export csv file for user with specified sku
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
    $userSpecifiedSku = $user.licenses.accountsku.skupartnumber | Where-Object { $_ -eq $sku }
    $userPNAndSpecifiedTable.Add($userpn, $userSpecifiedSku)
  }
  # Process key, value to more friendly name
  $userPNAndSpecifiedTable.GetEnumerator() | Select-Object -Property @{N = "UserPN"; E = { $_.Key } }, @{N = "License"; E = { $_.Value } } | 
  Export-Csv -Path filesystem::.\$fileName -Append -Force -NoTypeInformation
}

# Provide license option base on skuFriendlyName.csv
function provideAvailableLicenseOption() {
  $importAvaLicOption = Import-Csv -Path filesystem::.\skuFriendlyName.csv
  $counter = 0
  $avaLicOption = @()
  foreach ($option in $importAvaLicOption) {
    $counter ++
    $avaLicOption += New-Object -TypeName psobject -Property @{counter = $counter; SkuPartNumber = $options.SkuPartNumber; ProductName = $options.ProductName}
  }
  Return $avaLicOption
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
    $keyStroke = [System.Console]::ReadKey($true)
    $keyStroke = ($keyStroke).key
    $keyStroke
    Start-Sleep -Seconds 1
  } until ($optionArrary -contains $keyStroke)
  Return $keyStroke
}

# Assign License UI #
#------------------------------------------------------------------------------------------------#
function UIAssignLicense() {
  $optionArrary = @("A", "B")
  do {
    Clear-Host
    Write-Host "Please choose option" -ForegroundColor Yellow
    Write-Host "A: Assign license to user with specific license"
    Write-Host "B: Assign license to user from csv file"
    Write-Host -NoNewline "Input your option: "
    $keyStroke = [System.Console]::ReadKey($true)
    $keyStroke = ($keyStroke).key
    $keyStroke
    Start-Sleep -Seconds 1
  } until ($optionArrary -contains $keyStroke)
  Return $keyStroke
}

# Choose License UI #
#------------------------------------------------------------------------------------------------#
# tạo ra custom object dựa trên cái file skuFriendlyName.csv
# kiểu có bao nhiêu row thì nó tự generate ra đến đấy
function UILicenseOption() {
  $counter = 0
  $licenseOptions = provideAvailableLicenseOption
  $optionArrary = @()
  $availableOptions = [PSCustomObject]@{}
  foreach ($option in $licenseOptions) {
    $counter ++
    $optionArrary += $counter
    $availableOptions += New-Object -TypeName psobject -Property @{}
  }
}

# Assign/Un-assign user with specific license UI #
#------------------------------------------------------------------------------------------------#
function UIAssignOrUnAssign {
  param (
    OptionalParameters
  )
  
}

##################################################################################################
# ACTION GOES HERE YEY #
##################################################################################################
# EMPTY JUST LIKE MY SOUL