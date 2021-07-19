do {
  Add-Type -AssemblyName System.Windows.Forms
  $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog
  $FileBrowser.filter = "Csv (*.csv)| *.csv"
  [void]$FileBrowser.ShowDialog()
  $filePath = $FileBrowser.FileName
} until ("" -ne $filePath)

