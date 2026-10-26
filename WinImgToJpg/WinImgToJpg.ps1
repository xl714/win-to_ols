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
$Quality = 90
$BackgroundColor = 'white'   # Couleur utilisee pour remplacer la transparence
$ShowSuccessMessage = $true  # Mettre $false pour ne rien afficher si tout va bien
$OverwriteExisting = $false  # Si false, cree "image (1).jpg" au lieu d'ecraser

Add-Type -AssemblyName System.Windows.Forms

function Show-WinImgMessage {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Text,

        [ValidateSet('Information', 'Warning', 'Error')]
        [string] $Icon = 'Information'
    )

    $iconValue = switch ($Icon) {
        'Error'   { [System.Windows.Forms.MessageBoxIcon]::Error }
        'Warning' { [System.Windows.Forms.MessageBoxIcon]::Warning }
        default   { [System.Windows.Forms.MessageBoxIcon]::Information }
    }

    [void] [System.Windows.Forms.MessageBox]::Show(
        $Text,
        'WinImgToJpg',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        $iconValue
    )
}

function Find-ImageMagick {
    $command = Get-Command -Name 'magick.exe' -CommandType Application -ErrorAction SilentlyContinue |
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

        $directories = Get-ChildItem -LiteralPath $root -Directory -Filter 'ImageMagick-*' -ErrorAction SilentlyContinue |
            Sort-Object -Property LastWriteTime -Descending

        foreach ($directory in $directories) {
            $candidate = Join-Path -Path $directory.FullName -ChildPath 'magick.exe'
            if (Test-Path -LiteralPath $candidate -PathType Leaf) {
                return $candidate
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

    $jpegExtensions = @('.jpg', '.jpeg', '.jpe', '.jfif')
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($InputFile.Name)

    # Ne jamais reecrire directement un JPEG source.
    if ($jpegExtensions -contains $InputFile.Extension.ToLowerInvariant()) {
        $baseName += '_q90'
    }

    $candidate = Join-Path -Path $InputFile.DirectoryName -ChildPath ($baseName + '.jpg')

    if ($OverwriteExisting -or -not (Test-Path -LiteralPath $candidate)) {
        return $candidate
    }

    $index = 1
    do {
        $candidate = Join-Path -Path $InputFile.DirectoryName -ChildPath ('{0} ({1}).jpg' -f $baseName, $index)
        $index++
    }
    while (Test-Path -LiteralPath $candidate)

    return $candidate
}

function Select-Images {
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = 'Choisir les images a convertir en JPG'
    $dialog.Multiselect = $true
    $dialog.CheckFileExists = $true
    $dialog.Filter = 'Images|*.png;*.webp;*.avif;*.heic;*.heif;*.gif;*.bmp;*.tif;*.tiff;*.jpg;*.jpeg;*.jxl;*.ico|Tous les fichiers|*.*'

    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return @($dialog.FileNames)
    }

    return @()
}

$magickExe = Find-ImageMagick
if (-not $magickExe) {
    Show-WinImgMessage -Icon Error -Text @'
ImageMagick est introuvable.

Installe ImageMagick 7 et coche l'option qui ajoute son dossier au PATH, puis relance WinImgToJpg.
'@
    exit 2
}

if (-not $Paths -or $Paths.Count -eq 0) {
    $Paths = Select-Images
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
            throw 'Le chemin designe un dossier, pas une image.'
        }

        $outputPath = Get-AvailableOutputPath -InputFile $inputFile

        # [0] garde uniquement la premiere image pour les formats animes ou multi-pages.
        $inputSpecification = $inputFile.FullName + '[0]'
        $magickArguments = @(
            $inputSpecification,
            '-auto-orient',
            '-background', $BackgroundColor,
            '-alpha', 'remove',
            '-alpha', 'off',
            '-colorspace', 'sRGB',
            '-quality', ([string] $Quality),
            $outputPath
        )

        $previousErrorPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            $nativeOutput = @(& $magickExe @magickArguments 2>&1)
            $exitCode = $LASTEXITCODE
        }
        finally {
            $ErrorActionPreference = $previousErrorPreference
        }

        if ($exitCode -ne 0 -or -not (Test-Path -LiteralPath $outputPath -PathType Leaf)) {
            $details = (($nativeOutput | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine).Trim()
            if ([string]::IsNullOrWhiteSpace($details)) {
                $details = 'ImageMagick a retourne le code ' + $exitCode + '.'
            }
            if ($details.Length -gt 900) {
                $details = $details.Substring(0, 900) + '...'
            }
            throw $details
        }

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
    Show-WinImgMessage -Icon $icon -Text ($lines -join [Environment]::NewLine)
    exit 1
}

if ($ShowSuccessMessage -and $successes.Count -gt 0) {
    Show-WinImgMessage -Icon Information -Text ($lines -join [Environment]::NewLine)
}

exit 0
