function createCsvFile($fileName) {
  # Process file name - add timestamp to file name
  $fileLogDate = (Get-Date -Format yyyy-mm-dd_HH-mm-ss)
  $fileName
  $procedFileName = "$fileName"+"_"+"$fileLogDate.csv" # csv file name
  # create File
  $finalFileName = (New-Item -Path filesystem::.\ -Name $procedFileName -ItemType "file").Name
  Return $finalFileName
}
$filename = "concac"
createCsvFile $filename