$lines = Get-Content C:\FlutterProject\go_shop\test_output.txt
$total = $lines.Count
for ($i = 0; $i -lt $total; $i++) {
    if ($lines[$i] -match "\[E\]\s*$") {
        Write-Host "=== FAILED ===" -ForegroundColor Red
        Write-Host $lines[$i]
        $end = [Math]::Min($i + 35, $total - 1)
        for ($j = $i+1; $j -le $end; $j++) {
            $line = $lines[$j]
            if ($line -match "^\d{2}:\d{2} \+\d+ ") { break }
            Write-Host $line
        }
        Write-Host ""
    }
}
