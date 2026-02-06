# Script to test all list functions with both notAList and nilList

$testFunctions = @(
    "testFirst", "testMustFirst",
    "testRest", "testMustRest",
    "testLast", "testMustLast",
    "testInitial", "testMustInitial",
    "testAppend", "testMustAppend",
    "testPrepend", "testMustPrepend",
    "testConcat",
    "testReverse", "testMustReverse",
    "testUniq", "testMustUniq",
    "testWithout", "testMustWithout",
    "testHas", "testMustHas",
    "testCompact", "testMustCompact",
    "testIndex",
    "testSlice", "testMustSlice",
    "testUntil",
    "testUntilStep",
    "testSeq",
    "testChunk"
)

$results = @()

foreach ($test in $testFunctions) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Testing: $test" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    # Test with each value type
    $output = helm template .\helm\test-12-list-operation-error\ --set "$test=true" 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "PASS - No error" -ForegroundColor Green
        $results += [PSCustomObject]@{
            Function = $test
            Result = "PASS"
            Error = ""
        }
    } else {
        $errorMsg = $output | Select-String -Pattern "error calling|runtime error|Error:" | Select-Object -First 1
        Write-Host "FAIL - $errorMsg" -ForegroundColor Red
        $results += [PSCustomObject]@{
            Function = $test
            Result = "FAIL"
            Error = $errorMsg
        }
    }
}

Write-Host ""
Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "SUMMARY" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
$results | Format-Table -AutoSize

# Save results to file
$csvPath = ".\helm\test-12-list-operation-error\test-results.csv"
$results | Export-Csv -Path $csvPath -NoTypeInformation
Write-Host ""
Write-Host "Results saved to: $csvPath" -ForegroundColor Green
