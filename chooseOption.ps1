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
$a = UIChoosingOption
$a