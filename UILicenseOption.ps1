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
