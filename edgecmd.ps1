Set-StrictMode -Version Latest
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

$ErrorActionPreference = 'Stop'

function Read-RequiredText {
    param([string]$Prompt)

    do {
        $value = Read-Host $Prompt

        if ([string]::IsNullOrWhiteSpace($value)) {
            Write-Host "Value cannot be empty." -ForegroundColor Yellow
            continue
        }

        $trimmed = $value.Trim()
        if ($trimmed.ToLowerInvariant() -eq 'q') {
            return $null
        }

        return $trimmed
    } while ($true)
}

function Read-OptionalText {
    param([string]$Prompt)

    $value = Read-Host "$Prompt (press Enter to skip)"
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $null
    }

    $trimmed = $value.Trim()
    if ($trimmed.ToLowerInvariant() -eq 'q') {
        return $null
    }

    return $trimmed
}

function Read-RequiredNumber {
    param([string]$Prompt)

    do {
        $raw = Read-Host $Prompt

        if ([string]::IsNullOrWhiteSpace($raw)) {
            Write-Host "Value cannot be empty." -ForegroundColor Yellow
            continue
        }

        $trimmed = $raw.Trim()
        if ($trimmed.ToLowerInvariant() -eq 'q') {
            return $null
        }

        $number = 0.0
        if ([double]::TryParse($trimmed, [ref]$number)) {
            return $number
        }

        Write-Host "Invalid number. Please enter a numeric value." -ForegroundColor Yellow
    } while ($true)
}

function Read-NumberedChoice {
    param(
        [string]$Title,
        [string[]]$Options,
        [switch]$AllowCancel
    )

    Write-Host ""
    Write-Host $Title -ForegroundColor Cyan

    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host ("[{0}] {1}" -f ($i + 1), $Options[$i])
    }

    if ($AllowCancel) {
        Write-Host "[0] Cancel / Go back"
    }

    do {
        $raw = Read-Host "Enter the number"
        $choice = 0

        if ([int]::TryParse($raw, [ref]$choice)) {
            if ($AllowCancel -and $choice -eq 0) {
                return 0
            }

            if ($choice -ge 1 -and $choice -le $Options.Count) {
                return $choice
            }
        }

        Write-Host "Invalid selection. Enter one of the listed numbers." -ForegroundColor Yellow
    } while ($true)
}

function Read-MultiNumberedChoice {
    param(
        [string]$Title,
        [string[]]$Options,
        [switch]$AllowCancel
    )

    Write-Host ""
    Write-Host $Title -ForegroundColor Cyan

    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host ("[{0}] {1}" -f ($i + 1), $Options[$i])
    }

    if ($AllowCancel) {
        Write-Host "[0] Cancel / Go back"
    }

    Write-Host "Enter one or more numbers separated by commas (example: 1,3)"

    do {
        $raw = Read-Host "Enter the number(s)"

        if ($AllowCancel -and -not [string]::IsNullOrWhiteSpace($raw) -and $raw.Trim() -eq '0') {
            return @()
        }

        if ([string]::IsNullOrWhiteSpace($raw)) {
            Write-Host "At least one selection is required." -ForegroundColor Yellow
            continue
        }

        $items = @(
            $raw.Split(',') |
            ForEach-Object { $_.Trim() } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        )

        $valid = $true
        $selected = New-Object System.Collections.Generic.List[int]

        foreach ($item in $items) {
            $choice = 0

            if (-not [int]::TryParse($item, [ref]$choice)) {
                $valid = $false
                break
            }

            if ($choice -lt 1 -or $choice -gt $Options.Count) {
                $valid = $false
                break
            }

            if (-not $selected.Contains($choice)) {
                $selected.Add($choice)
            }
        }

        if ($valid -and $selected.Count -gt 0) {
            return @($selected | Sort-Object)
        }

        Write-Host "Invalid selection. Enter valid numbers like 1,2 or 1,3." -ForegroundColor Yellow
    } while ($true)
}

function Read-OptionalChoice {
    param(
        [string]$Title,
        [string[]]$Options
    )

    Write-Host ""
    Write-Host $Title -ForegroundColor Cyan

    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host ("[{0}] {1}" -f ($i + 1), $Options[$i])
    }

    Write-Host "[Enter] Skip"

    do {
        $raw = Read-Host "Enter the number"

        if ([string]::IsNullOrWhiteSpace($raw)) {
            return $null
        }

        $choice = 0
        if ([int]::TryParse($raw, [ref]$choice)) {
            if ($choice -ge 1 -and $choice -le $Options.Count) {
                return $Options[$choice - 1]
            }
        }

        Write-Host "Invalid selection. Enter one of the listed numbers or press Enter to skip." -ForegroundColor Yellow
    } while ($true)
}

function Read-YesNo {
    param([string]$Prompt)

    do {
        $answer = Read-Host "$Prompt [Y/N]"

        if ([string]::IsNullOrWhiteSpace($answer)) {
            Write-Host "No input detected. Please enter Y or N." -ForegroundColor Yellow
            continue
        }

        switch ($answer.Trim().ToUpperInvariant()) {
            'Y'   { return $true }
            'YES' { return $true }
            'N'   { return $false }
            'NO'  { return $false }
            default { Write-Host "Invalid entry. Please enter Y or N." -ForegroundColor Yellow }
        }
    } while ($true)
}

function Read-OptionalYesNo {
    param([string]$Prompt)

    do {
        $answer = Read-Host "$Prompt [Y/N, Enter to skip]"

        if ([string]::IsNullOrWhiteSpace($answer)) {
            return $null
        }

        switch ($answer.Trim().ToUpperInvariant()) {
            'Y'   { return $true }
            'YES' { return $true }
            'N'   { return $false }
            'NO'  { return $false }
            default { Write-Host "Invalid entry. Please enter Y, N, or press Enter to skip." -ForegroundColor Yellow }
        }
    } while ($true)
}

function Confirm-Selection {
    param(
        [string[]]$DescriptionLines,
        [string]$RestartMessage = 'Restarting...'
    )

    Write-Host ""
    Write-Host "You selected:"
    foreach ($line in $DescriptionLines) {
        Write-Host $line
    }

    $confirm = Read-YesNo "Confirm this selection"

    if (-not $confirm) {
        Write-Host $RestartMessage -ForegroundColor Yellow
        Write-Host ""
        return $false
    }

    return $true
}

function Get-ComponentObjects {
    $output = & edgecmd get Components 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw "edgecmd failed while retrieving existing components."
    }

    $text = ($output -join [Environment]::NewLine)

    try {
        $components = $text | ConvertFrom-Json

        if ($null -eq $components) {
            return @()
        }

        if ($components -isnot [System.Collections.IEnumerable] -or $components -is [string]) {
            $components = @($components)
        }

        return @($components)
    }
    catch {
        throw "Could not parse edgecmd get Components output as JSON."
    }
}

function Get-DataFilters {
    param(
        [string]$ComponentId
    )

    $output = & edgecmd get DataFilters -cid $ComponentId 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw "edgecmd failed while retrieving data filters."
    }

    $text = ($output -join [Environment]::NewLine)

    try {
        $filters = @($text | ConvertFrom-Json)

        if ($null -eq $filters -or $filters.Count -eq 0) {
            return @()
        }

        return @($filters)
    }
    catch {
        throw "Could not parse edgecmd get DataFilters output as JSON."
    }
}


function Get-Schedules {
    param(
        [string]$ComponentId
    )

    $output = & edgecmd get Schedules -cid $ComponentId 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw "edgecmd failed while retrieving schedules."
    }

    $text = ($output -join [Environment]::NewLine)

    try {
        $schedules = @($text | ConvertFrom-Json)

        if ($null -eq $schedules -or $schedules.Count -eq 0) {
            return @()
        }

        return @($schedules)
    }
    catch {
        throw "Could not parse edgecmd get Schedules output as JSON."
    }
}

function Show-ExistingComponents {
    param(
        [object[]]$Components
    )

    Write-Host ""
    Write-Host "Existing components:" -ForegroundColor Cyan

    if (-not $Components -or $Components.Count -eq 0) {
        Write-Host "  <none>"
        Write-Host ""
        return
    }

    $Components | ForEach-Object {
        Write-Host "  $($_.componentId) [$($_.componentType)]"
    }

    Write-Host ""
}

function Show-DataSourceDetails {
    param(
        [string]$ComponentId
    )

    Write-Host ""
    Write-Host ("Data source details for {0}:" -f $ComponentId) -ForegroundColor Cyan

    $output = & edgecmd get DataSource -cid $ComponentId 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Unable to retrieve data source details." -ForegroundColor Yellow
        $output | ForEach-Object { Write-Host $_ }
        Write-Host ""
        return
    }

    $output | ForEach-Object { Write-Host $_ }
    Write-Host ""
}

function Show-DataFiltersDetails {
    param(
        [string]$ComponentId
    )

    Write-Host ""
    Write-Host ("Data filter details for {0}:" -f $ComponentId) -ForegroundColor Cyan

    $filters = Get-DataFilters -ComponentId $ComponentId

    if (-not $filters -or $filters.Count -eq 0) {
        Write-Host "  <none>"
        Write-Host ""
        return
    }

    for ($i = 0; $i -lt $filters.Count; $i++) {
        $filter = $filters[$i]
        Write-Host ("[{0}] id={1}" -f ($i + 1), $filter.id)

        if ($null -ne $filter.PSObject.Properties['absoluteDeadband']) {
            Write-Host ("    absoluteDeadband : {0}" -f $filter.absoluteDeadband)
        }

        if ($null -ne $filter.PSObject.Properties['percentChange']) {
            Write-Host ("    percentChange    : {0}" -f $filter.percentChange)
        }

        if ($null -ne $filter.PSObject.Properties['expirationPeriod']) {
            Write-Host ("    expirationPeriod : {0}" -f $filter.expirationPeriod)
        }
    }

    Write-Host ""
}

function Set-OpcUaDataSourceFromObject {
    param(
        [string]$ComponentId,
        [hashtable]$DataSource
    )

    $tempFile = Join-Path $env:TEMP ("opcua-datasource-{0}.json" -f [guid]::NewGuid().ToString())
    $json = $DataSource | ConvertTo-Json -Depth 10

    try {
        Set-Content -Path $tempFile -Value $json -Encoding UTF8
        & edgecmd set DataSource -cid $ComponentId -file $tempFile

        if ($LASTEXITCODE -ne 0) {
            throw "edgecmd failed while configuring the OPC UA data source."
        }
    }
    finally {
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        }
    }
}

function Set-DataFiltersFromObject {
    param(
        [string]$ComponentId,
        [object[]]$DataFilters
    )

    $tempFile = Join-Path $env:TEMP ("datafilters-{0}.json" -f [guid]::NewGuid().ToString())
    $json = ConvertTo-Json -InputObject @($DataFilters) -Depth 10
    Write-Host "DataFilters JSON payload:" -ForegroundColor DarkGray
    Write-Host $json -ForegroundColor DarkGray

    try {
        Set-Content -Path $tempFile -Value $json -Encoding UTF8
        & edgecmd set DataFilters -cid $ComponentId -file $tempFile

        if ($LASTEXITCODE -ne 0) {
            throw "edgecmd failed while configuring data filters."
        }
    }
    finally {
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        }
    }
}


function Set-SchedulesFromObject {
    param(
        [string]$ComponentId,
        [object[]]$Schedules
    )

    $tempFile = Join-Path $env:TEMP ("schedules-{0}.json" -f [guid]::NewGuid().ToString())
    $json = ConvertTo-Json -InputObject @($Schedules) -Depth 10
    Write-Host "Schedules JSON payload:" -ForegroundColor DarkGray
    Write-Host $json -ForegroundColor DarkGray

    try {
        Set-Content -Path $tempFile -Value $json -Encoding UTF8
        & edgecmd set Schedules -cid $ComponentId -file $tempFile

        if ($LASTEXITCODE -ne 0) {
            throw "edgecmd failed while configuring schedules."
        }
    }
    finally {
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        }
    }
}

function Configure-OpcUaDataSource {
    param(
        [string]$ComponentId
    )

    $confirm = $false

    do {
        Write-Host ""
        Write-Host "Configure OPC UA data source" -ForegroundColor Cyan
        Write-Host "Press Enter to skip any optional field." -ForegroundColor DarkGray
        Write-Host "useSecureConnection will be set to true by default." -ForegroundColor DarkGray

        $endpointUrl = Read-RequiredText "Enter endpointUrl (or Q to skip data source configuration)"
        if ($null -eq $endpointUrl) {
            Write-Host "Data source configuration skipped." -ForegroundColor Yellow
            return
        }

        $username = Read-OptionalText "Enter username"
        $password = Read-OptionalText "Enter password"

        $incomingTimestamp = Read-OptionalChoice -Title "Select incomingTimestamp" -Options @(
            'Source',
            'Server',
            'Adapter'
        )

        $streamIdPrefix = Read-OptionalText "Enter streamIdPrefix"
        $defaultStreamIdPattern = Read-OptionalText "Enter defaultStreamIdPattern"
        $defaultEventStreamIdPattern = Read-OptionalText "Enter defaultEventStreamIdPattern"
        $dataCollectionMode = Read-OptionalText "Enter dataCollectionMode"
        $serverFailoverEnabled = Read-OptionalYesNo "Set serverFailoverEnabled"
        $backupEndpointUrls = Read-OptionalText "Enter backupEndpointUrls (comma-separated if multiple)"

        $dataSource = [ordered]@{
            endpointUrl         = $endpointUrl
            useSecureConnection = $true
        }

        if ($username) { $dataSource.username = $username }
        if ($password) { $dataSource.password = $password }
        if ($incomingTimestamp) { $dataSource.incomingTimestamp = $incomingTimestamp }
        if ($streamIdPrefix) { $dataSource.streamIdPrefix = $streamIdPrefix }
        if ($defaultStreamIdPattern) { $dataSource.defaultStreamIdPattern = $defaultStreamIdPattern }
        if ($defaultEventStreamIdPattern) { $dataSource.defaultEventStreamIdPattern = $defaultEventStreamIdPattern }
        if ($dataCollectionMode) { $dataSource.dataCollectionMode = $dataCollectionMode }
        if ($null -ne $serverFailoverEnabled) { $dataSource.serverFailoverEnabled = $serverFailoverEnabled }

        if ($backupEndpointUrls) {
            $urls = @(
                $backupEndpointUrls.Split(',') |
                ForEach-Object { $_.Trim() } |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
            )

            if ($urls.Count -eq 1) {
                $dataSource.backupEndpointUrls = $urls[0]
            }
            elseif ($urls.Count -gt 1) {
                $dataSource.backupEndpointUrls = $urls
            }
        }

        $summaryLines = @()
        foreach ($entry in $dataSource.GetEnumerator()) {
            if ($entry.Value -is [System.Array]) {
                $summaryLines += ("  {0} : {1}" -f $entry.Key, ($entry.Value -join ', '))
            }
            else {
                $summaryLines += ("  {0} : {1}" -f $entry.Key, $entry.Value)
            }
        }

        $confirm = Confirm-Selection -DescriptionLines $summaryLines -RestartMessage "Restarting data source configuration..."
    } while (-not $confirm)

    Set-OpcUaDataSourceFromObject -ComponentId $ComponentId -DataSource $dataSource

    Write-Host ""
    Write-Host "Data source configured successfully." -ForegroundColor Green
    Show-DataSourceDetails -ComponentId $ComponentId
}

function Configure-NewDataFilters {
    param(
        [string]$ComponentId
    )

    $filterOptions = @(
        'absoluteDeadband',
        'percentChange',
        'expirationPeriod'
    )

    $allFilters = @()
    $addAnother = $true

    while ($addAnother) {
        $confirm = $false

        do {
            Write-Host ""
            Write-Host "Configure data filters" -ForegroundColor Cyan
            Write-Host "Select one or more filter types." -ForegroundColor DarkGray

            $filterId = Read-RequiredText "Enter data filter ID (or Q to skip data filter configuration)"
            if ($null -eq $filterId) {
                if ($allFilters.Count -eq 0) {
                    Write-Host "Data filter configuration skipped." -ForegroundColor Yellow
                    return
                }

                $addAnother = $false
                break
            }

            $alreadyExists = $allFilters | Where-Object { $_.id -eq $filterId }
            if ($alreadyExists) {
                Write-Host ""
                Write-Host "A data filter with ID '$filterId' has already been added in this session. Please choose another ID." -ForegroundColor Yellow
                Write-Host ""
                continue
            }

            $selectedNumbers = Read-MultiNumberedChoice -Title "Select data filter types" -Options $filterOptions
            $selectedTypes = @($selectedNumbers | ForEach-Object { $filterOptions[$_ - 1] })

            $dataFilter = [ordered]@{
                id = $filterId
            }

            if ($selectedTypes -contains 'absoluteDeadband') {
                $absoluteDeadband = Read-RequiredNumber "Enter value for absoluteDeadband (or Q to cancel this data filter)"
                if ($null -eq $absoluteDeadband) {
                    Write-Host "Data filter entry cancelled." -ForegroundColor Yellow
                    continue
                }

                $dataFilter.absoluteDeadband = $absoluteDeadband
            }

            if ($selectedTypes -contains 'percentChange') {
                $percentChange = Read-RequiredNumber "Enter value for percentChange (or Q to cancel this data filter)"
                if ($null -eq $percentChange) {
                    Write-Host "Data filter entry cancelled." -ForegroundColor Yellow
                    continue
                }

                $dataFilter.percentChange = $percentChange
            }

            if ($selectedTypes -contains 'expirationPeriod') {
                $expirationPeriod = Read-RequiredText "Enter value for expirationPeriod (for example 0:10:00) (or Q to cancel this data filter)"
                if ($null -eq $expirationPeriod) {
                    Write-Host "Data filter entry cancelled." -ForegroundColor Yellow
                    continue
                }

                $dataFilter.expirationPeriod = $expirationPeriod
            }

            $summaryLines = @(
                "  id    : $($dataFilter.id)",
                "  types : $($selectedTypes -join ', ')"
            )

            foreach ($entry in $dataFilter.GetEnumerator() | Where-Object { $_.Key -ne 'id' }) {
                $summaryLines += ("  {0} : {1}" -f $entry.Key, $entry.Value)
            }

            $confirm = Confirm-Selection -DescriptionLines $summaryLines -RestartMessage "Restarting data filter configuration..."
        } while (-not $confirm)

        if (-not $addAnother) {
            break
        }

        $allFilters += [pscustomobject]$dataFilter

        Write-Host ""
        Write-Host ("Data filter '{0}' added." -f $dataFilter.id) -ForegroundColor Green

        $addAnother = Read-YesNo "Do you want to add more data filters"
    }

    if ($allFilters.Count -eq 0) {
        Write-Host "Data filter configuration skipped." -ForegroundColor Yellow
        return
    }

    Set-DataFiltersFromObject -ComponentId $ComponentId -DataFilters $allFilters

    Write-Host ""
    Write-Host "Data filters configured successfully." -ForegroundColor Green
    Show-DataFiltersDetails -ComponentId $ComponentId
}

function Edit-ExistingDataFilters {
    param(
        [string]$ComponentId
    )

    $existingFilters = Get-DataFilters -ComponentId $ComponentId

    if (@($existingFilters).Count -eq 0) {
        Write-Host "No existing data filters were found for this component." -ForegroundColor Yellow
        return
    }

    $filterOptions = @($existingFilters | ForEach-Object { $_.id })
    $selectedFilterNumbers = Read-MultiNumberedChoice -Title "Select data filter(s) to update" -Options $filterOptions -AllowCancel
    if (@($selectedFilterNumbers).Count -eq 0) {
        Write-Host "Data filter edit cancelled." -ForegroundColor Yellow
        return
    }

    $updatedFiltersById = @{}

    foreach ($filterNumber in $selectedFilterNumbers) {
        $selectedFilter = $existingFilters[$filterNumber - 1]

        Write-Host ""
        Write-Host ("Updating filter: {0}" -f $selectedFilter.id) -ForegroundColor Cyan

        $editableFields = @()

        if ($null -ne $selectedFilter.PSObject.Properties['absoluteDeadband']) {
            $editableFields += 'absoluteDeadband'
        }

        if ($null -ne $selectedFilter.PSObject.Properties['percentChange']) {
            $editableFields += 'percentChange'
        }

        if ($null -ne $selectedFilter.PSObject.Properties['expirationPeriod']) {
            $editableFields += 'expirationPeriod'
        }

        if ($editableFields.Count -eq 0) {
            Write-Host "The selected filter has no editable fields. Skipping." -ForegroundColor Yellow
            continue
        }

        $selectedFieldNumbers = Read-MultiNumberedChoice -Title ("Select field(s) to update for filter '{0}'" -f $selectedFilter.id) -Options $editableFields -AllowCancel
        if (@($selectedFieldNumbers).Count -eq 0) {
            Write-Host ("Skipped filter '{0}'." -f $selectedFilter.id) -ForegroundColor Yellow
            continue
        }

        $updatedFilter = [ordered]@{
            id = $selectedFilter.id
        }

        if ($null -ne $selectedFilter.PSObject.Properties['absoluteDeadband']) {
            $updatedFilter.absoluteDeadband = $selectedFilter.absoluteDeadband
        }

        if ($null -ne $selectedFilter.PSObject.Properties['percentChange']) {
            $updatedFilter.percentChange = $selectedFilter.percentChange
        }

        if ($null -ne $selectedFilter.PSObject.Properties['expirationPeriod']) {
            $updatedFilter.expirationPeriod = $selectedFilter.expirationPeriod
        }

        $skipThisFilter = $false

        foreach ($number in $selectedFieldNumbers) {
            $fieldName = $editableFields[$number - 1]
            $prompt = "Enter new value for $fieldName"

            if ($fieldName -eq 'expirationPeriod') {
                $prompt = "Enter new value for expirationPeriod (seconds)"
            }

            $newValue = Read-RequiredNumber "$prompt (or Q to cancel this filter update)"
            if ($null -eq $newValue) {
                Write-Host ("Skipped filter '{0}'." -f $selectedFilter.id) -ForegroundColor Yellow
                $skipThisFilter = $true
                break
            }

            if ($fieldName -eq 'expirationPeriod') {
                $updatedFilter[$fieldName] = [int]$newValue
            }
            else {
                $updatedFilter[$fieldName] = $newValue
            }
        }

        if (-not $skipThisFilter) {
            $updatedFiltersById[$selectedFilter.id] = [pscustomobject]$updatedFilter
        }
    }

    if ($updatedFiltersById.Count -eq 0) {
        Write-Host "No data filters were updated." -ForegroundColor Yellow
        return
    }

    $summaryLines = @()
    foreach ($filterId in ($updatedFiltersById.Keys | Sort-Object)) {
        $filter = $updatedFiltersById[$filterId]
        $summaryLines += "  id : $($filter.id)"

        if ($null -ne $filter.PSObject.Properties['absoluteDeadband']) {
            $summaryLines += ("  absoluteDeadband : {0}" -f $filter.absoluteDeadband)
        }

        if ($null -ne $filter.PSObject.Properties['percentChange']) {
            $summaryLines += ("  percentChange    : {0}" -f $filter.percentChange)
        }

        if ($null -ne $filter.PSObject.Properties['expirationPeriod']) {
            $summaryLines += ("  expirationPeriod : {0}" -f $filter.expirationPeriod)
        }

        $summaryLines += ""
    }

    $confirm = Confirm-Selection -DescriptionLines $summaryLines -RestartMessage "Restarting data filter edit..."
    if (-not $confirm) {
        Edit-ExistingDataFilters -ComponentId $ComponentId
        return
    }

    $allFilters = @()
    foreach ($filter in $existingFilters) {
        if ($updatedFiltersById.ContainsKey($filter.id)) {
            $allFilters += $updatedFiltersById[$filter.id]
        }
        else {
            $allFilters += $filter
        }
    }

    Set-DataFiltersFromObject -ComponentId $ComponentId -DataFilters $allFilters

    Write-Host ""
    Write-Host "Data filters updated successfully." -ForegroundColor Green
    Show-DataFiltersDetails -ComponentId $ComponentId
}


function Show-SchedulesDetails {
    param(
        [string]$ComponentId
    )

    Write-Host ""
    Write-Host ("Schedule details for {0}:" -f $ComponentId) -ForegroundColor Cyan

    $schedules = Get-Schedules -ComponentId $ComponentId

    if (-not $schedules -or $schedules.Count -eq 0) {
        Write-Host "  <none>"
        Write-Host ""
        return
    }

    for ($i = 0; $i -lt $schedules.Count; $i++) {
        $schedule = $schedules[$i]
        Write-Host ("[{0}] id={1}" -f ($i + 1), $schedule.id)

        if ($null -ne $schedule.PSObject.Properties['period']) {
            Write-Host ("    period : {0}" -f $schedule.period)
        }

        if ($null -ne $schedule.PSObject.Properties['offset']) {
            Write-Host ("    offset : {0}" -f $schedule.offset)
        }
    }

    Write-Host ""
}

function Configure-NewSchedules {
    param(
        [string]$ComponentId
    )

    $allSchedules = @()
    $addAnother = $true

    while ($addAnother) {
        $confirm = $false

        do {
            Write-Host ""
            Write-Host "Configure schedules" -ForegroundColor Cyan

            $scheduleId = Read-RequiredText "Enter schedule ID (or Q to skip schedule configuration)"
            if ($null -eq $scheduleId) {
                if ($allSchedules.Count -eq 0) {
                    Write-Host "Schedule configuration skipped." -ForegroundColor Yellow
                    return
                }

                $addAnother = $false
                break
            }

            $alreadyExists = $allSchedules | Where-Object { $_.id -eq $scheduleId }
            if ($alreadyExists) {
                Write-Host ""
                Write-Host "A schedule with ID '$scheduleId' has already been added in this session. Please choose another ID." -ForegroundColor Yellow
                Write-Host ""
                continue
            }

            $period = Read-RequiredText "Enter period (for example 0:00:05) (or Q to cancel this schedule)"
            if ($null -eq $period) {
                Write-Host "Schedule entry cancelled." -ForegroundColor Yellow
                continue
            }

            $offset = Read-RequiredText "Enter offset (for example 0:00:00) (or Q to cancel this schedule)"
            if ($null -eq $offset) {
                Write-Host "Schedule entry cancelled." -ForegroundColor Yellow
                continue
            }

            $schedule = [ordered]@{
                id     = $scheduleId
                period = $period
                offset = $offset
            }

            $summaryLines = @(
                "  id     : $($schedule.id)",
                "  period : $($schedule.period)",
                "  offset : $($schedule.offset)"
            )

            $confirm = Confirm-Selection -DescriptionLines $summaryLines -RestartMessage "Restarting schedule configuration..."
        } while (-not $confirm)

        if (-not $addAnother) {
            break
        }

        $allSchedules += [pscustomobject]$schedule

        Write-Host ""
        Write-Host ("Schedule '{0}' added." -f $schedule.id) -ForegroundColor Green

        $addAnother = Read-YesNo "Do you want to add more schedules"
    }

    if ($allSchedules.Count -eq 0) {
        Write-Host "Schedule configuration skipped." -ForegroundColor Yellow
        return
    }

    Set-SchedulesFromObject -ComponentId $ComponentId -Schedules $allSchedules

    Write-Host ""
    Write-Host "Schedules configured successfully." -ForegroundColor Green
    Show-SchedulesDetails -ComponentId $ComponentId
}

function Edit-ExistingSchedules {
    param(
        [string]$ComponentId
    )

    $existingSchedules = Get-Schedules -ComponentId $ComponentId

    if (@($existingSchedules).Count -eq 0) {
        Write-Host "No existing schedules were found for this component." -ForegroundColor Yellow
        return
    }

    $scheduleOptions = @($existingSchedules | ForEach-Object { $_.id })
    $selectedScheduleNumbers = Read-MultiNumberedChoice -Title "Select schedule(s) to update" -Options $scheduleOptions -AllowCancel
    if (@($selectedScheduleNumbers).Count -eq 0) {
        Write-Host "Schedule edit cancelled." -ForegroundColor Yellow
        return
    }

    $updatedSchedulesById = @{}

    foreach ($scheduleNumber in $selectedScheduleNumbers) {
        $selectedSchedule = $existingSchedules[$scheduleNumber - 1]

        Write-Host ""
        Write-Host ("Updating schedule: {0}" -f $selectedSchedule.id) -ForegroundColor Cyan

        $updatedSchedule = [ordered]@{
            id     = $selectedSchedule.id
            period = $selectedSchedule.period
            offset = $selectedSchedule.offset
        }

        $period = Read-RequiredText "Enter new value for period (current: $($selectedSchedule.period)) (or Q to cancel this schedule update)"
        if ($null -eq $period) {
            Write-Host ("Skipped schedule '{0}'." -f $selectedSchedule.id) -ForegroundColor Yellow
            continue
        }

        $offset = Read-RequiredText "Enter new value for offset (current: $($selectedSchedule.offset)) (or Q to cancel this schedule update)"
        if ($null -eq $offset) {
            Write-Host ("Skipped schedule '{0}'." -f $selectedSchedule.id) -ForegroundColor Yellow
            continue
        }

        $updatedSchedule.period = $period
        $updatedSchedule.offset = $offset
        $updatedSchedulesById[$selectedSchedule.id] = [pscustomobject]$updatedSchedule
    }

    if ($updatedSchedulesById.Count -eq 0) {
        Write-Host "No schedules were updated." -ForegroundColor Yellow
        return
    }

    $summaryLines = @()
    foreach ($scheduleId in ($updatedSchedulesById.Keys | Sort-Object)) {
        $schedule = $updatedSchedulesById[$scheduleId]
        $summaryLines += "  id     : $($schedule.id)"
        $summaryLines += "  period : $($schedule.period)"
        $summaryLines += "  offset : $($schedule.offset)"
        $summaryLines += ""
    }

    $confirm = Confirm-Selection -DescriptionLines $summaryLines -RestartMessage "Restarting schedule edit..."
    if (-not $confirm) {
        Edit-ExistingSchedules -ComponentId $ComponentId
        return
    }

    $allSchedules = @()
    foreach ($schedule in $existingSchedules) {
        if ($updatedSchedulesById.ContainsKey($schedule.id)) {
            $allSchedules += $updatedSchedulesById[$schedule.id]
        }
        else {
            $allSchedules += $schedule
        }
    }

    Set-SchedulesFromObject -ComponentId $ComponentId -Schedules $allSchedules

    Write-Host ""
    Write-Host "Schedules updated successfully." -ForegroundColor Green
    Show-SchedulesDetails -ComponentId $ComponentId
}


function Configure-DataDiscovery {
    param(
        [string]$ComponentId
    )

    $confirm = $false

    do {
        Write-Host ""
        Write-Host "Configure data discovery" -ForegroundColor Cyan

        $discoveryId = Read-RequiredText "Enter data discovery ID (or Q to skip data discovery configuration)"
        if ($null -eq $discoveryId) {
            Write-Host "Data discovery configuration skipped." -ForegroundColor Yellow
            return
        }

        $query = Read-RequiredText "Enter query"
        if ($null -eq $query) {
            Write-Host "Data discovery configuration skipped." -ForegroundColor Yellow
            return
        }

        $startTime = Read-RequiredText "Enter startTime"
        if ($null -eq $startTime) {
            Write-Host "Data discovery configuration skipped." -ForegroundColor Yellow
            return
        }

        $summaryLines = @(
            "  id         : $discoveryId",
            "  query      : $query",
            "  startTime  : $startTime",
            "  autoSelect : False"
        )

        $confirm = Confirm-Selection -DescriptionLines $summaryLines -RestartMessage "Restarting data discovery configuration..."
    } while (-not $confirm)

    $tempFile = Join-Path $env:TEMP ("datadiscovery-{0}.json" -f [guid]::NewGuid().ToString())
    $discovery = [ordered]@{
        id         = $discoveryId
        query      = $query
        startTime  = $startTime
        autoSelect = $false
    }
    $json = $discovery | ConvertTo-Json -Depth 10
    Write-Host "DataDiscovery JSON payload:" -ForegroundColor DarkGray
    Write-Host $json -ForegroundColor DarkGray

    try {
        Set-Content -Path $tempFile -Value $json -Encoding UTF8
        & edgecmd add Discoveries -cid $ComponentId -file $tempFile

        if ($LASTEXITCODE -ne 0) {
            throw "edgecmd failed while configuring data discovery."
        }
    }
    finally {
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        }
    }

    Write-Host ""
    Write-Host "Data discovery configured successfully." -ForegroundColor Green
}

function Configure-DataSelection {
    param(
        [string]$ComponentId
    )

    Write-Host ""
    Write-Host "Configure data selection" -ForegroundColor Cyan

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $defaultExportPath = Join-Path (Get-Location) ("{0}-DataSelection-{1}.csv" -f $ComponentId, $timestamp)
    Write-Host ("Exporting current data selection to: {0}" -f $defaultExportPath) -ForegroundColor DarkGray

    & edgecmd get DataSelection -cid $ComponentId -file $defaultExportPath -csv
    if ($LASTEXITCODE -ne 0) {
        throw "edgecmd failed while exporting data selection to CSV."
    }

    Write-Host "Update the CSV file as needed, then provide the file path to import." -ForegroundColor DarkGray
    $csvPath = Read-RequiredText "Enter path to the data selection CSV file to import (or Q to cancel)"
    if ($null -eq $csvPath) {
        Write-Host "Data selection configuration skipped." -ForegroundColor Yellow
        return
    }

    if (-not (Test-Path $csvPath)) {
        throw "The specified data selection CSV file was not found."
    }

    Write-Host ""
    Write-Host "Running EdgeCmd..." -ForegroundColor DarkGray

    & edgecmd set DataSelection -cid $ComponentId -file $csvPath -csv
    if ($LASTEXITCODE -ne 0) {
        throw "edgecmd failed while importing data selection from CSV."
    }

    Write-Host ""
    Write-Host "Data selection configured successfully." -ForegroundColor Green
}

function Get-DataEndpoints {
    $output = & edgecmd get DataEndpoints 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw "edgecmd failed while retrieving data endpoints."
    }

    $text = ($output -join [Environment]::NewLine)

    try {
        $endpoints = $text | ConvertFrom-Json

        if ($null -eq $endpoints) {
            return @()
        }

        if ($endpoints -isnot [System.Collections.IEnumerable] -or $endpoints -is [string]) {
            $endpoints = @($endpoints)
        }

        return @($endpoints)
    }
    catch {
        throw "Could not parse edgecmd get DataEndpoints output as JSON."
    }
}

function Show-DataEndpointsDetails {
    Write-Host ""
    Write-Host "Data endpoints:" -ForegroundColor Cyan

    $endpoints = Get-DataEndpoints

    if (-not $endpoints -or $endpoints.Count -eq 0) {
        Write-Host "  <none>"
        Write-Host ""
        return
    }

    foreach ($endpoint in $endpoints) {
        Write-Host ("  id={0}" -f $endpoint.id)
        foreach ($property in $endpoint.PSObject.Properties) {
            if ($property.Name -ne 'id') {
                Write-Host ("    {0} : {1}" -f $property.Name, $property.Value)
            }
        }
    }

    Write-Host ""
}

function Set-DataEndpointsFromObject {
    param(
        [object[]]$DataEndpoints
    )

    $tempFile = Join-Path $env:TEMP ("dataendpoints-{0}.json" -f [guid]::NewGuid().ToString())
    $json = ConvertTo-Json -InputObject @($DataEndpoints) -Depth 10
    Write-Host "DataEndpoints JSON payload:" -ForegroundColor DarkGray
    Write-Host $json -ForegroundColor DarkGray

    try {
        Set-Content -Path $tempFile -Value $json -Encoding UTF8
        & edgecmd set DataEndpoints -file $tempFile

        if ($LASTEXITCODE -ne 0) {
            throw "edgecmd failed while configuring data endpoints."
        }
    }
    finally {
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        }
    }
}

function Configure-DataEndpoints {
    param(
        [string]$ComponentId
    )

    $endpointTypeOptions = @(
        'CONNECT data services',
        'Edge data store',
        'PI Web API',
        'PI Web API (with a secret ID)'
    )

    $confirm = $false

    do {
        Write-Host ""
        Write-Host "Configure data endpoints" -ForegroundColor Cyan
        Write-Host "Press Enter to skip any optional field." -ForegroundColor DarkGray

        $typeChoice = Read-NumberedChoice -Title "Select data endpoint type" -Options $endpointTypeOptions -AllowCancel
        if ($typeChoice -eq 0) {
            Write-Host "Data endpoints configuration skipped." -ForegroundColor Yellow
            return
        }

        $endpointType = $endpointTypeOptions[$typeChoice - 1]
        $endpointId = Read-RequiredText "Enter endpoint ID (or Q to cancel data endpoints configuration)"
        if ($null -eq $endpointId) {
            Write-Host "Data endpoints configuration skipped." -ForegroundColor Yellow
            return
        }

        $endpoint = Read-RequiredText "Enter endpoint"
        if ($null -eq $endpoint) {
            Write-Host "Data endpoints configuration skipped." -ForegroundColor Yellow
            return
        }

        $dataEndpoint = [ordered]@{
            id       = $endpointId
            endpoint = $endpoint
        }

        switch ($endpointType) {
            'CONNECT data services' {
                $clientId = Read-RequiredText "Enter clientId"
                $clientSecret = Read-RequiredText "Enter clientSecret"
                $dataEndpoint.clientId = $clientId
                $dataEndpoint.clientSecret = $clientSecret
            }
            'Edge data store' {
            }
            'PI Web API' {
                $username = Read-RequiredText "Enter username"
                $password = Read-RequiredText "Enter password"
                $dataEndpoint.username = $username
                $dataEndpoint.password = $password
            }
            'PI Web API (with a secret ID)' {
                $clientId = Read-RequiredText "Enter clientId"
                $clientSecret = Read-RequiredText "Enter clientSecret"
                $tokenEndpoint = Read-RequiredText "Enter tokenEndpoint"
                $validateEndpointCertificate = Read-OptionalYesNo "Set validateEndpointCertificate"
                $username = Read-OptionalText "Enter username"
                $password = Read-OptionalText "Enter password"
                $dataEndpoint.clientId = $clientId
                $dataEndpoint.clientSecret = $clientSecret
                $dataEndpoint.tokenEndpoint = $tokenEndpoint
                if ($null -ne $validateEndpointCertificate) { $dataEndpoint.validateEndpointCertificate = $validateEndpointCertificate }
                if ($username) { $dataEndpoint.username = $username }
                if ($password) { $dataEndpoint.password = $password }
            }
        }

        $summaryLines = @(
            "  type     : $endpointType"
        )
        foreach ($entry in $dataEndpoint.GetEnumerator()) {
            $summaryLines += ("  {0} : {1}" -f $entry.Key, $entry.Value)
        }

        $confirm = Confirm-Selection -DescriptionLines $summaryLines -RestartMessage "Restarting data endpoints configuration..."
    } while (-not $confirm)

    $allEndpoints = @()
    try {
        $existingEndpoints = Get-DataEndpoints
    }
    catch {
        $existingEndpoints = @()
    }

    foreach ($existing in $existingEndpoints) {
        if ($existing.id -ne $dataEndpoint.id) {
            $allEndpoints += $existing
        }
    }
    $allEndpoints += [pscustomobject]$dataEndpoint

    Set-DataEndpointsFromObject -DataEndpoints $allEndpoints

    Write-Host ""
    Write-Host "Data endpoints configured successfully." -ForegroundColor Green
    Show-DataEndpointsDetails
}

function Remove-ExistingDataFilters {
    param(
        [string]$ComponentId
    )

    $existingFilters = Get-DataFilters -ComponentId $ComponentId

    if (-not $existingFilters -or $existingFilters.Count -eq 0) {
        Write-Host "No existing data filters were found for this component." -ForegroundColor Yellow
        return
    }

    $filterOptions = @($existingFilters | ForEach-Object { $_.id })
    $selectedFilterNumbers = Read-MultiNumberedChoice -Title "Select data filter(s) to delete" -Options $filterOptions -AllowCancel
    if (@($selectedFilterNumbers).Count -eq 0) {
        Write-Host "Data filter delete cancelled." -ForegroundColor Yellow
        return
    }

    $selectedFilterIds = @($selectedFilterNumbers | ForEach-Object { $filterOptions[$_ - 1] })
    $summaryLines = @($selectedFilterIds | ForEach-Object { "  Delete data filter : $_" })
    $confirm = Confirm-Selection -DescriptionLines $summaryLines -RestartMessage "Restarting data filter deletion..."
    if (-not $confirm) {
        return
    }

    $remainingFilters = @($existingFilters | Where-Object { $selectedFilterIds -notcontains $_.id })
    Set-DataFiltersFromObject -ComponentId $ComponentId -DataFilters $remainingFilters

    Write-Host ""
    Write-Host "Data filter(s) deleted successfully." -ForegroundColor Green
    Show-DataFiltersDetails -ComponentId $ComponentId
}

function Remove-ExistingSchedules {
    param(
        [string]$ComponentId
    )

    $existingSchedules = Get-Schedules -ComponentId $ComponentId

    if (-not $existingSchedules -or $existingSchedules.Count -eq 0) {
        Write-Host "No existing schedules were found for this component." -ForegroundColor Yellow
        return
    }

    $scheduleOptions = @($existingSchedules | ForEach-Object { $_.id })
    $selectedScheduleNumbers = Read-MultiNumberedChoice -Title "Select schedule(s) to delete" -Options $scheduleOptions -AllowCancel
    if (@($selectedScheduleNumbers).Count -eq 0) {
        Write-Host "Schedule delete cancelled." -ForegroundColor Yellow
        return
    }

    $selectedScheduleIds = @($selectedScheduleNumbers | ForEach-Object { $scheduleOptions[$_ - 1] })
    $summaryLines = @($selectedScheduleIds | ForEach-Object { "  Delete schedule : $_" })
    $confirm = Confirm-Selection -DescriptionLines $summaryLines -RestartMessage "Restarting schedule deletion..."
    if (-not $confirm) {
        return
    }

    $remainingSchedules = @($existingSchedules | Where-Object { $selectedScheduleIds -notcontains $_.id })
    Set-SchedulesFromObject -ComponentId $ComponentId -Schedules $remainingSchedules

    Write-Host ""
    Write-Host "Schedule(s) deleted successfully." -ForegroundColor Green
    Show-SchedulesDetails -ComponentId $ComponentId
}

function Add-ComponentFlow {
    param(
        [object[]]$Components
    )

    $componentTypes = @(
        'OpcUa',
        'Modbus',
        'RDBMS',
        'MQTT'
    )

    Show-ExistingComponents -Components $Components

    $confirm = $false
    do {
        $typeChoice = Read-NumberedChoice -Title "Select component type" -Options $componentTypes -AllowCancel
        if ($typeChoice -eq 0) {
            Write-Host "Cancelled." -ForegroundColor Yellow
            return
        }

        $componentType = $componentTypes[$typeChoice - 1]

        $componentId = Read-RequiredText "Enter component name / ID (or Q to cancel)"
        if ($null -eq $componentId) {
            Write-Host "Cancelled." -ForegroundColor Yellow
            return
        }

        $alreadyExists = $Components | Where-Object { $_.componentId -eq $componentId }
        if ($alreadyExists) {
            Write-Host ""
            Write-Host "A component with ID '$componentId' already exists. Please choose another ID." -ForegroundColor Yellow
            Write-Host ""
            continue
        }

        $confirm = Confirm-Selection -DescriptionLines @(
            "  Type : $componentType",
            "  Name : $componentId"
        ) -RestartMessage "Restarting component creation..."
    } while (-not $confirm)

    Write-Host ""
    Write-Host "Running EdgeCmd..." -ForegroundColor DarkGray

    & edgecmd add Components -type $componentType -id $componentId

    if ($LASTEXITCODE -ne 0) {
        throw "edgecmd failed while creating the component."
    }

    $updated = Get-ComponentObjects
    $created = $updated | Where-Object { $_.componentId -eq $componentId }

    if (-not $created) {
        throw "edgecmd returned success, but the new component was not found after creation."
    }

    Write-Host ""
    Write-Host "Component created successfully." -ForegroundColor Green

    if ($componentType -eq 'OpcUa') {
        Configure-OpcUaDataSource -ComponentId $componentId
        Configure-DataDiscovery -ComponentId $componentId
        Configure-NewDataFilters -ComponentId $componentId
        Configure-NewSchedules -ComponentId $componentId
        Configure-DataSelection -ComponentId $componentId
        Configure-DataEndpoints -ComponentId $componentId
        $updated = Get-ComponentObjects
    }

    Show-ExistingComponents -Components $updated
}

function Edit-ComponentFlow {
    param(
        [object[]]$Components
    )

    Show-ExistingComponents -Components $Components

    if (-not $Components -or $Components.Count -eq 0) {
        Write-Host "No components are available to edit." -ForegroundColor Yellow
        return
    }

    $editableComponents = @($Components)
    $editOptions = $editableComponents | ForEach-Object { "$($_.componentId) [$($_.componentType)]" }

    $confirm = $false
    do {
        $choice = Read-NumberedChoice -Title "Select component to edit" -Options $editOptions -AllowCancel
        if ($choice -eq 0) {
            Write-Host "Cancelled." -ForegroundColor Yellow
            return
        }

        $selectedComponent = $editableComponents[$choice - 1]

        $confirm = Confirm-Selection -DescriptionLines @(
            "  Edit component : $($selectedComponent.componentId)",
            "  Type           : $($selectedComponent.componentType)"
        ) -RestartMessage "Restarting component edit..."
    } while (-not $confirm)

    if ($selectedComponent.componentType -ne 'OpcUa') {
        Write-Host "Edit workflow is currently implemented for OpcUa components only." -ForegroundColor Yellow
        return
    }

    do {
        $editMenu = @(
            'Data source',
            'Data filters',
            'Schedules',
            'Data discovery',
            'Data selection',
            'Data endpoints'
        )

        $editChoice = Read-NumberedChoice -Title ("Select what to edit for component '{0}'" -f $selectedComponent.componentId) -Options $editMenu -AllowCancel
        if ($editChoice -eq 0) {
            Write-Host "Returning to component list..." -ForegroundColor Yellow
            return
        }

        switch ($editChoice) {
            1 {
                Show-DataSourceDetails -ComponentId $selectedComponent.componentId
                Configure-OpcUaDataSource -ComponentId $selectedComponent.componentId
            }
            2 {
                do {
                    $filterMenu = @(
                        'Add data filters',
                        'Edit existing data filters',
                        'Delete data filters',
                        'Back'
                    )

                    $filterChoice = Read-NumberedChoice -Title ("Manage data filters for component '{0}'" -f $selectedComponent.componentId) -Options $filterMenu -AllowCancel
                    if ($filterChoice -eq 0 -or $filterChoice -eq 4) {
                        break
                    }

                    switch ($filterChoice) {
                        1 { Configure-NewDataFilters -ComponentId $selectedComponent.componentId }
                        2 {
                            Show-DataFiltersDetails -ComponentId $selectedComponent.componentId
                            Edit-ExistingDataFilters -ComponentId $selectedComponent.componentId
                        }
                        3 {
                            Show-DataFiltersDetails -ComponentId $selectedComponent.componentId
                            Remove-ExistingDataFilters -ComponentId $selectedComponent.componentId
                        }
                    }
                } while ($true)
            }
            3 {
                do {
                    $scheduleMenu = @(
                        'Add schedules',
                        'Edit existing schedules',
                        'Delete schedules',
                        'Back'
                    )

                    $scheduleChoice = Read-NumberedChoice -Title ("Manage schedules for component '{0}'" -f $selectedComponent.componentId) -Options $scheduleMenu -AllowCancel
                    if ($scheduleChoice -eq 0 -or $scheduleChoice -eq 4) {
                        break
                    }

                    switch ($scheduleChoice) {
                        1 { Configure-NewSchedules -ComponentId $selectedComponent.componentId }
                        2 {
                            Show-SchedulesDetails -ComponentId $selectedComponent.componentId
                            Edit-ExistingSchedules -ComponentId $selectedComponent.componentId
                        }
                        3 {
                            Show-SchedulesDetails -ComponentId $selectedComponent.componentId
                            Remove-ExistingSchedules -ComponentId $selectedComponent.componentId
                        }
                    }
                } while ($true)
            }
            4 {
                Show-DataDiscoveryDetails -ComponentId $selectedComponent.componentId
                Configure-DataDiscovery -ComponentId $selectedComponent.componentId
            }
            5 {
                Show-DataSelectionDetails -ComponentId $selectedComponent.componentId
                Configure-DataSelection -ComponentId $selectedComponent.componentId
            }
            6 {
                Show-DataEndpointsDetails -ComponentId $selectedComponent.componentId
                Configure-DataEndpoints -ComponentId $selectedComponent.componentId
            }
        }

        Write-Host ""
        Write-Host "Returning to edit options for this component..." -ForegroundColor DarkGray
    } while ($true)
}

function Remove-ComponentFlow {
    param(
        [object[]]$Components
    )

    $removableComponents = @($Components | Where-Object { $_.componentId -ne 'OmfEgress' })

    Show-ExistingComponents -Components $Components
    Write-Host "Note: OmfEgress is required and cannot be deleted." -ForegroundColor Yellow
    Write-Host ""

    if (-not $removableComponents -or $removableComponents.Count -eq 0) {
        Write-Host "No removable components are available." -ForegroundColor Yellow
        return
    }

    $removeOptions = $removableComponents | ForEach-Object { "$($_.componentId) [$($_.componentType)]" }

    $confirm = $false
    do {
        $choice = Read-NumberedChoice -Title "Select component to remove" -Options $removeOptions -AllowCancel
        if ($choice -eq 0) {
            Write-Host "Cancelled." -ForegroundColor Yellow
            return
        }

        $selectedComponent = $removableComponents[$choice - 1]

        $confirm = Confirm-Selection -DescriptionLines @(
            "  Remove component : $($selectedComponent.componentId)",
            "  Type             : $($selectedComponent.componentType)"
        ) -RestartMessage "Restarting component removal..."
    } while (-not $confirm)

    Write-Host ""
    Write-Host "Running EdgeCmd..." -ForegroundColor DarkGray

    & edgecmd remove Components -id $selectedComponent.componentId -y

    if ($LASTEXITCODE -ne 0) {
        throw "edgecmd failed while removing the component."
    }

    $updated = Get-ComponentObjects
    $stillExists = $updated | Where-Object { $_.componentId -eq $selectedComponent.componentId }

    if ($stillExists) {
        throw "edgecmd returned success, but the component still exists after removal."
    }

    Write-Host ""
    Write-Host "Component removed successfully." -ForegroundColor Green
    Show-ExistingComponents -Components $updated
}

# --- Main ---

$mainMenu = @(
    'Add Component',
    'Edit Component',
    'Remove Component'
)

do {
    $menuChoice = Read-NumberedChoice -Title "Select an action" -Options $mainMenu -AllowCancel
    if ($menuChoice -eq 0) {
        Write-Host "Exiting." -ForegroundColor Yellow
        break
    }

    try {
        $components = Get-ComponentObjects

        switch ($menuChoice) {
            1 { Add-ComponentFlow -Components $components }
            2 { Edit-ComponentFlow -Components $components }
            3 { Remove-ComponentFlow -Components $components }
            default { throw "Unexpected menu selection." }
        }
    }
    catch {
        Write-Host ""
        Write-Host ("Error: {0}" -f $_.Exception.Message) -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "Returning to main menu..." -ForegroundColor DarkGray
    Write-Host ""
} while ($true)