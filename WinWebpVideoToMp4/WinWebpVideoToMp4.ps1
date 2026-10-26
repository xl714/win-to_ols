[CmdletBinding()]
param(
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]] $Paths
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

# -----------------------------------------------------------------------------
# Reglages faciles a modifier
# -----------------------------------------------------------------------------
$Crf = 18                      # Qualite H.264 : plus petit = meilleure qualite (18 = quasi sans perte visible)
$Preset = 'medium'             # Vitesse d'encodage x264 : ultrafast ... veryslow
$BackgroundColor = 'white'     # Couleur utilisee pour remplacer la transparence
$ShowSuccessMessage = $true    # Mettre $false pour ne rien afficher si tout va bien
$OverwriteExisting = $false    # Si false, cree "video (1).mp4" au lieu d'ecraser
$DefaultFrameDurationMs = 100  # Duree utilisee quand un frame n'a pas de duree valide

# Mode silencieux pour lancement depuis un terminal :
# set WINWEBPVIDEOTOMP4_SILENT=1 -> messages en console au lieu de boites de dialogue.
$SilentMode = ($env:WINWEBPVIDEOTOMP4_SILENT -eq '1')

Add-Type -AssemblyName System.Windows.Forms

function Show-WinWebpVideoMessage {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Text,

        [ValidateSet('Information', 'Warning', 'Error')]
        [string] $Icon = 'Information'
    )

    if ($SilentMode) {
        Write-Output ('[{0}] {1}' -f $Icon, $Text)
        return
    }

    $iconValue = switch ($Icon) {
        'Error'   { [System.Windows.Forms.MessageBoxIcon]::Error }
        'Warning' { [System.Windows.Forms.MessageBoxIcon]::Warning }
        default   { [System.Windows.Forms.MessageBoxIcon]::Information }
    }

    [void] [System.Windows.Forms.MessageBox]::Show(
        $Text,
        'WinWebpVideoToMp4',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        $iconValue
    )
}

function Invoke-NativeTool {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Executable,

        [Parameter(Mandatory = $true)]
        [string[]] $Arguments
    )

    $previousErrorPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& $Executable @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorPreference
    }

    return [PSCustomObject] @{
        ExitCode = $exitCode
        Output   = $output
    }
}

function Format-NativeToolError {
    param(
        [Parameter(Mandatory = $true)]
        $Result,

        [Parameter(Mandatory = $true)]
        [string] $DefaultMessage
    )

    $details = (($Result.Output | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine).Trim()
    if ([string]::IsNullOrWhiteSpace($details)) {
        $details = ('{0} (code {1}).' -f $DefaultMessage, $Result.ExitCode)
    }
    if ($details.Length -gt 900) {
        $details = $details.Substring(0, 900) + '...'
    }
    return $details
}

function Find-InstalledTool {
    param(
        [Parameter(Mandatory = $true)]
        [string] $ExeName,

        [Parameter(Mandatory = $true)]
        [string[]] $DirectoryFilters,

        [string] $ExeSubPath = ''
    )

    $command = Get-Command -Name $ExeName -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if ($null -ne $command) {
        return $command.Source
    }

    $roots = @()
    if ($env:ProgramFiles) {
        $roots += $env:ProgramFiles
    }
    if (${env:ProgramFiles(x86)}) {
        $roots += ${env:ProgramFiles(x86)}
    }
    if ($env:LOCALAPPDATA) {
        $roots += (Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Programs')
    }

    foreach ($root in $roots) {
        if (-not (Test-Path -LiteralPath $root -PathType Container)) {
            continue
        }

        foreach ($filter in $DirectoryFilters) {
            $directories = Get-ChildItem -LiteralPath $root -Directory -Filter $filter -ErrorAction SilentlyContinue |
                Sort-Object -Property LastWriteTime -Descending

            foreach ($directory in $directories) {
                $candidateDir = $directory.FullName
                if ($ExeSubPath) {
                    $candidateDir = Join-Path -Path $candidateDir -ChildPath $ExeSubPath
                }
                $candidate = Join-Path -Path $candidateDir -ChildPath $ExeName
                if (Test-Path -LiteralPath $candidate -PathType Leaf) {
                    return $candidate
                }
            }
        }
    }

    return $null
}

function Get-AvailableOutputPath {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo] $InputFile
    )

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($InputFile.Name)
    $candidate = Join-Path -Path $InputFile.DirectoryName -ChildPath ($baseName + '.mp4')

    if ($OverwriteExisting -or -not (Test-Path -LiteralPath $candidate)) {
        return $candidate
    }

    $index = 1
    do {
        $candidate = Join-Path -Path $InputFile.DirectoryName -ChildPath ('{0} ({1}).mp4' -f $baseName, $index)
        $index++
    }
    while (Test-Path -LiteralPath $candidate)

    return $candidate
}

function Get-FrameDurationsMs {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo] $InputFile,

        [Parameter(Mandatory = $true)]
        [string] $MagickExe,

        [string] $WebpmuxExe
    )

    # webpmux donne les durees exactes en millisecondes.
    if ($WebpmuxExe) {
        $result = Invoke-NativeTool -Executable $WebpmuxExe -Arguments @('-info', $InputFile.FullName)
        if ($result.ExitCode -eq 0) {
            $durations = @()
            foreach ($line in $result.Output) {
                $text = "$line"
                # Lignes de frames : "  1:   480   270   no   0   0   33   none   yes   12345   lossy"
                if ($text -match '^\s*\d+:\s') {
                    $columns = @(-split $text)
                    if ($columns.Count -ge 7) {
                        $durations += [int] $columns[6]
                    }
                }
            }
            if ($durations.Count -gt 0) {
                return $durations
            }
        }
    }

    # Repli : ImageMagick rapporte le delai en centisecondes (arrondi).
    $result = Invoke-NativeTool -Executable $MagickExe -Arguments @('identify', '-format', "%T`n", $InputFile.FullName)
    if ($result.ExitCode -ne 0) {
        throw (Format-NativeToolError -Result $result -DefaultMessage 'ImageMagick n''a pas pu lire les durees des frames')
    }

    $durations = @()
    foreach ($line in $result.Output) {
        $text = "$line".Trim()
        if ($text -match '^\d+$') {
            $durations += ([int] $text) * 10
        }
    }
    return $durations
}

function Convert-WebpToMp4 {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo] $InputFile,

        [Parameter(Mandatory = $true)]
        [string] $MagickExe,

        [Parameter(Mandatory = $true)]
        [string] $FfmpegExe,

        [string] $WebpmuxExe
    )

    if ($InputFile.Extension.ToLowerInvariant() -ne '.webp') {
        throw 'Ce fichier n''est pas un .webp.'
    }

    $outputPath = Get-AvailableOutputPath -InputFile $InputFile

    $tempDir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ('WinWebpVideoToMp4_' + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tempDir | Out-Null

    try {
        # 1) Extraction des frames completes (compositing gere par -coalesce).
        $framePattern = Join-Path -Path $tempDir -ChildPath 'frame_%06d.png'
        $magickArguments = @(
            $InputFile.FullName,
            '-coalesce',
            '-background', $BackgroundColor,
            '-alpha', 'remove',
            '-alpha', 'off',
            $framePattern
        )
        $result = Invoke-NativeTool -Executable $MagickExe -Arguments $magickArguments
        if ($result.ExitCode -ne 0) {
            throw (Format-NativeToolError -Result $result -DefaultMessage 'ImageMagick n''a pas pu extraire les frames')
        }

        $frames = @(Get-ChildItem -LiteralPath $tempDir -Filter 'frame_*.png' | Sort-Object -Property Name)
        if ($frames.Count -eq 0) {
            throw 'Aucun frame extrait du fichier.'
        }
        if ($frames.Count -lt 2) {
            throw 'Ce WebP ne contient qu''une seule image (pas d''animation). Rien a convertir en video.'
        }

        # 2) Durees par frame.
        $durationsMs = @(Get-FrameDurationsMs -InputFile $InputFile -MagickExe $MagickExe -WebpmuxExe $WebpmuxExe)
        while ($durationsMs.Count -lt $frames.Count) {
            $durationsMs += $DefaultFrameDurationMs
        }

        # 3) Liste concat ffmpeg avec duree exacte de chaque frame.
        $invariant = [System.Globalization.CultureInfo]::InvariantCulture
        $listLines = @()
        $totalMs = 0
        for ($i = 0; $i -lt $frames.Count; $i++) {
            $framePath = ($frames[$i].FullName -replace '\\', '/') -replace "'", "'\''"
            $ms = $durationsMs[$i]
            if ($ms -le 0) {
                $ms = $DefaultFrameDurationMs
            }
            $totalMs += $ms
            $seconds = ([double] $ms / 1000.0).ToString('0.0###', $invariant)
            $listLines += ("file '{0}'" -f $framePath)
            $listLines += ('duration {0}' -f $seconds)
        }
        # Le dernier fichier est repete pour que sa duree soit respectee.
        $lastFramePath = ($frames[$frames.Count - 1].FullName -replace '\\', '/') -replace "'", "'\''"
        $listLines += ("file '{0}'" -f $lastFramePath)

        $listPath = Join-Path -Path $tempDir -ChildPath 'frames.txt'
        [System.IO.File]::WriteAllLines($listPath, [string[]] $listLines)

        # 4) Assemblage en MP4 H.264 (dimensions paires + yuv420p pour compatibilite).
        $ffmpegArguments = @(
            '-y',
            '-hide_banner',
            '-loglevel', 'error',
            '-f', 'concat',
            '-safe', '0',
            '-i', $listPath,
            '-vf', 'scale=trunc(iw/2)*2:trunc(ih/2)*2:flags=lanczos,format=yuv420p',
            # Conserve chaque frame avec son propre timestamp (sinon reechantillonnage 25 fps),
            # en base milliseconde, la resolution native des durees WebP.
            '-fps_mode', 'vfr',
            '-enc_time_base:v', '1:1000',
            '-c:v', 'libx264',
            '-crf', ([string] $Crf),
            '-preset', $Preset,
            '-movflags', '+faststart',
            # Coupe exactement a la duree de l'animation (le frame repete ajoute sinon un residu).
            '-t', (([double] $totalMs / 1000.0).ToString('0.0###', $invariant)),
            $outputPath
        )
        $result = Invoke-NativeTool -Executable $FfmpegExe -Arguments $ffmpegArguments
        if ($result.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $outputPath -PathType Leaf)) {
            if (Test-Path -LiteralPath $outputPath) {
                Remove-Item -LiteralPath $outputPath -Force -ErrorAction SilentlyContinue
            }
            throw (Format-NativeToolError -Result $result -DefaultMessage 'ffmpeg n''a pas pu creer le MP4')
        }

        return $outputPath
    }
    finally {
        Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Select-WebpFiles {
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = 'Choisir les WebP animes a convertir en MP4'
    $dialog.Multiselect = $true
    $dialog.CheckFileExists = $true
    $dialog.Filter = 'WebP|*.webp|Tous les fichiers|*.*'

    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return @($dialog.FileNames)
    }

    return @()
}

$magickExe = Find-InstalledTool -ExeName 'magick.exe' -DirectoryFilters @('ImageMagick-*')
if (-not $magickExe) {
    Show-WinWebpVideoMessage -Icon Error -Text @'
ImageMagick est introuvable.

Installe ImageMagick 7 et coche l'option qui ajoute son dossier au PATH, puis relance WinWebpVideoToMp4.
'@
    exit 2
}

$ffmpegExe = Find-InstalledTool -ExeName 'ffmpeg.exe' -DirectoryFilters @('ffmpeg', 'ffmpeg-*') -ExeSubPath 'bin'
if (-not $ffmpegExe) {
    Show-WinWebpVideoMessage -Icon Error -Text @'
ffmpeg est introuvable.

Installe ffmpeg (par exemple dans C:\Program Files\ffmpeg\bin) ou ajoute-le au PATH, puis relance WinWebpVideoToMp4.
'@
    exit 2
}

# Optionnel : webpmux donne des durees de frames exactes (sinon repli sur ImageMagick).
$webpmuxExe = Find-InstalledTool -ExeName 'webpmux.exe' -DirectoryFilters @('libwebp-*') -ExeSubPath 'bin'

if (-not $Paths -or $Paths.Count -eq 0) {
    $Paths = Select-WebpFiles
    if (-not $Paths -or $Paths.Count -eq 0) {
        exit 0
    }
}

$successes = @()
$failures = @()

foreach ($rawPath in $Paths) {
    try {
        $inputFile = Get-Item -LiteralPath $rawPath -ErrorAction Stop

        if ($inputFile.PSIsContainer) {
            throw 'Le chemin designe un dossier, pas un fichier .webp.'
        }

        $outputPath = Convert-WebpToMp4 -InputFile $inputFile -MagickExe $magickExe -FfmpegExe $ffmpegExe -WebpmuxExe $webpmuxExe

        $successes += [PSCustomObject] @{
            InputName  = $inputFile.Name
            OutputName = [System.IO.Path]::GetFileName($outputPath)
            OutputPath = $outputPath
        }
    }
    catch {
        $displayName = [System.IO.Path]::GetFileName([string] $rawPath)
        if ([string]::IsNullOrWhiteSpace($displayName)) {
            $displayName = [string] $rawPath
        }

        $failures += [PSCustomObject] @{
            InputName = $displayName
            Error     = $_.Exception.Message
        }
    }
}

$lines = @()

if ($successes.Count -gt 0) {
    $lines += ('{0} conversion(s) reussie(s) :' -f $successes.Count)
    $lines += ''

    foreach ($result in ($successes | Select-Object -First 10)) {
        $lines += ('{0}  ->  {1}' -f $result.InputName, $result.OutputName)
    }

    if ($successes.Count -gt 10) {
        $lines += ('... et {0} autre(s).' -f ($successes.Count - 10))
    }
}

if ($failures.Count -gt 0) {
    if ($lines.Count -gt 0) {
        $lines += ''
    }

    $lines += ('{0} echec(s) :' -f $failures.Count)
    $lines += ''

    foreach ($failure in ($failures | Select-Object -First 5)) {
        $lines += ('{0} : {1}' -f $failure.InputName, $failure.Error)
    }

    if ($failures.Count -gt 5) {
        $lines += ('... et {0} autre(s).' -f ($failures.Count - 5))
    }
}

if ($failures.Count -gt 0) {
    $icon = if ($successes.Count -gt 0) { 'Warning' } else { 'Error' }
    Show-WinWebpVideoMessage -Icon $icon -Text ($lines -join [Environment]::NewLine)
    exit 1
}

if ($ShowSuccessMessage -and $successes.Count -gt 0) {
    Show-WinWebpVideoMessage -Icon Information -Text ($lines -join [Environment]::NewLine)
}

exit 0
