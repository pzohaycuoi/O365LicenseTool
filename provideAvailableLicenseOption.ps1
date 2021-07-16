function provideAvailableLicenseOption() {
  $importAvaLicOption = Import-Csv -Path filesystem::.\skuFriendlyName.csv
  # Empty PSObject to import data into
  $avaOptionObject = @()
  foreach ($option in $importAvaLicOption) {
    $avaOptionObject += New-Object -TypeName PSObject -Property @{skuPartName = $option.skuPartName; productName = $option.productName}
  }
  $avaOptionObject
}
provideAvailableLicenseOption