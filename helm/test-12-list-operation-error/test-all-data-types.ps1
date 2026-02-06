# Comprehensive test script for all list functions against all data types

$testFunctions = @(
    @{name="testFirst"; func="first"},
    @{name="testMustFirst"; func="mustFirst"},
    @{name="testRest"; func="rest"},
    @{name="testMustRest"; func="mustRest"},
    @{name="testLast"; func="last"},
    @{name="testMustLast"; func="mustLast"},
    @{name="testInitial"; func="initial"},
    @{name="testMustInitial"; func="mustInitial"},
    @{name="testAppend"; func="append"},
    @{name="testMustAppend"; func="mustAppend"},
    @{name="testPrepend"; func="prepend"},
    @{name="testMustPrepend"; func="mustPrepend"},
    @{name="testConcat"; func="concat"},
    @{name="testReverse"; func="reverse"},
    @{name="testMustReverse"; func="mustReverse"},
    @{name="testUniq"; func="uniq"},
    @{name="testMustUniq"; func="mustUniq"},
    @{name="testWithout"; func="without"},
    @{name="testMustWithout"; func="mustWithout"},
    @{name="testHas"; func="has"},
    @{name="testMustHas"; func="mustHas"},
    @{name="testCompact"; func="compact"},
    @{name="testMustCompact"; func="mustCompact"},
    @{name="testIndex"; func="index"},
    @{name="testSlice"; func="slice"},
    @{name="testMustSlice"; func="mustSlice"}
)

$dataTypes = @(
    "nilList",
    "emptyList",
    "stringValue",
    "numberValue",
    "boolValue",
    "dictValue",
    "validList",
    "shortList"
)

$results = @()
$totalTests = 0
$passedTests = 0
$failedTests = 0

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "COMPREHENSIVE LIST FUNCTION TESTING" -ForegroundColor Cyan
Write-Host "Testing each function against all data types" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

foreach ($test in $testFunctions) {
    $funcName = $test.name
    $funcDisplayName = $test.func

    Write-Host "Testing function: $funcDisplayName" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Yellow

    foreach ($dataType in $dataTypes) {
        $totalTests++

        # Create a temporary template that uses the specified data type
        $tempValues = "testDataType: $dataType"

        # Run helm template with the test enabled
        $output = helm template .\helm\test-12-list-operation-error\ --set "$funcName=true" --set "testDataType=$dataType" 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Host "  $dataType : PASS" -ForegroundColor Green
            $passedTests++
            $result = "PASS"
            $error = ""
        } else {
            # Extract error message
            $errorMsg = ($output | Select-String -Pattern "error calling|runtime error|wrong type" | Select-Object -First 1).ToString()
            if ($errorMsg) {
                $errorShort = $errorMsg -replace ".*error calling $funcDisplayName[:]?\s*", "" -replace ".*runtime error:\s*", "" -replace ".*at <.*>:\s*", ""
                $errorShort = $errorShort.Substring(0, [Math]::Min(80, $errorShort.Length))
            } else {
                $errorShort = "Unknown error"
            }
            Write-Host "  $dataType : FAIL - $errorShort" -ForegroundColor Red
            $failedTests++
            $result = "FAIL"
            $error = $errorShort
        }

        $results += [PSCustomObject]@{
            Function = $funcDisplayName
            DataType = $dataType
            Result = $result
            Error = $error
        }
    }
    Write-Host ""
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SUMMARY BY FUNCTION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Group results by function
$grouped = $results | Group-Object -Property Function

foreach ($group in $grouped) {
    $funcName = $group.Name
    $failures = ($group.Group | Where-Object { $_.Result -eq "FAIL" }).Count
    $passes = ($group.Group | Where-Object { $_.Result -eq "PASS" }).Count

    Write-Host "$funcName : $passes PASS, $failures FAIL" -ForegroundColor $(if ($failures -eq 0) { "Green" } else { "Yellow" })

    # Show which data types fail
    $failedTypes = ($group.Group | Where-Object { $_.Result -eq "FAIL" } | Select-Object -ExpandProperty DataType) -join ", "
    if ($failedTypes) {
        Write-Host "  Fails on: $failedTypes" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OVERALL STATISTICS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $passedTests ($([Math]::Round($passedTests/$totalTests*100, 2))%)" -ForegroundColor Green
Write-Host "Failed: $failedTests ($([Math]::Round($failedTests/$totalTests*100, 2))%)" -ForegroundColor Red
Write-Host ""

# Save detailed results to CSV
$csvPath = ".\helm\test-12-list-operation-error\test-results-comprehensive.csv"
$results | Export-Csv -Path $csvPath -NoTypeInformation
Write-Host "Detailed results saved to: $csvPath" -ForegroundColor Green

# Create a pivot table showing which data types fail for each function
Write-Host ""
Write-Host "Creating summary matrix..." -ForegroundColor Cyan

$matrix = @()
foreach ($group in $grouped) {
    $row = [PSCustomObject]@{
        Function = $group.Name
    }
    foreach ($dt in $dataTypes) {
        $testResult = $group.Group | Where-Object { $_.DataType -eq $dt } | Select-Object -First 1
        $row | Add-Member -NotePropertyName $dt -NotePropertyValue $testResult.Result
    }
    $matrix += $row
}

$matrixPath = ".\helm\test-12-list-operation-error\test-matrix.csv"
$matrix | Export-Csv -Path $matrixPath -NoTypeInformation
Write-Host "Test matrix saved to: $matrixPath" -ForegroundColor Green
Write-Host ""
