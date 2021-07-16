function provideAvailableLicenseOption() {
  $importAvaLicOption = Import-Csv -Path filesystem::.\skuFriendlyName.csv
  $avaListOption = @()
  $counter = 0
  foreach ($option in $importAvaLicOption) {
    $counter ++
    $avaListOption += New-Object -TypeName psobject -Property @{counter = $counter; skupartnumber = $option.skupartnumber; productName = $option.ProductName }
  }
  Return $avaListOption
}

function UILicenseOption() {
  do {
    Clear-Host
    $licenseOptions = provideAvailableLicenseOption
    $optionArrary = @()
    Write-Host "Please choose product name" -ForegroundColor Yellow
    foreach ($option in $licenseOptions) {
      $optionArrary += $option.counter
      Write-Host $option.counter ":" $option.ProductName
    }
    Write-Host ""
    $enteredOption = Read-Host "Input your option: "
  } until ($optionArrary -contains $enteredOption)
  $selectedOption = $licenseOptions | Where-Object {$_.counter -eq $enteredOption}
  return $selectedOption
}
UILicenseOption