do {
  Add-Type -AssemblyName System.Windows.Forms
  $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog
  $FileBrowser.filter = "Csv (*.csv)| *.csv"
  [void]$FileBrowser.ShowDialog()
  $filePath = $FileBrowser.FileName
  if ($filePath -eq $null) {
    echo "cac"
  } else {
    echo "loz"
  }
} until ($null -eq $filePath)

