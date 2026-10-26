[CmdletBinding()]
param(
    [switch] $NoDialog,

    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]] $Paths
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

# -----------------------------------------------------------------------------
# Reglages faciles a modifier
# -----------------------------------------------------------------------------
$Quality = 90                # Qualite JPEG des images integrees au PDF
$BackgroundColor = 'white'   # Couleur utilisee pour remplacer la transparence
$ShowSuccessMessage = $true  # Mettre $false pour ne rien afficher si tout va bien
$OverwriteExisting = $false  # Si false, cree "nom (1).pdf" au lieu d'ecraser

# Extensions acceptees comme pages du PDF
$ImageExtensions = @(
    '.jpg', '.jpeg', '.jpe', '.jfif', '.png', '.webp', '.avif',
    '.heic', '.heif', '.gif', '.bmp', '.tif', '.tiff', '.jxl', '.ico'
)

Add-Type -AssemblyName System.Windows.Forms

if (-not ('WinImagesToPDF.NativeMethods' -as [type])) {
    Add-Type -Namespace 'WinImagesToPDF' -Name 'NativeMethods' -MemberDefinition @'
[DllImport("shlwapi.dll", CharSet = CharSet.Unicode)]
public static extern int StrCmpLogicalW(string x, string y);
'@
}

function Show-WinPdfMessage {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Text,

        [ValidateSet('Information', 'Warning', 'Error')]
        [string] $Icon = 'Information'
    )

    if ($NoDialog) {
        Write-Host $Text
        return
    }

    $iconValue = switch ($Icon) {
        'Error'   { [System.Windows.Forms.MessageBoxIcon]::Error }
        'Warning' { [System.Windows.Forms.MessageBoxIcon]::Warning }
        default   { [System.Windows.Forms.MessageBoxIcon]::Information }
    }

    [void] [System.Windows.Forms.MessageBox]::Show(
        $Text,
        'WinImagesToPDF',
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
        [System.IO.FileInfo] $FirstImage
    )

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($FirstImage.Name)
    $candidate = Join-Path -Path $FirstImage.DirectoryName -ChildPath ($baseName + '.pdf')

    if ($OverwriteExisting -or -not (Test-Path -LiteralPath $candidate)) {
        return $candidate
    }

    $index = 1
    do {
        $candidate = Join-Path -Path $FirstImage.DirectoryName -ChildPath ('{0} ({1}).pdf' -f $baseName, $index)
        $index++
    }
    while (Test-Path -LiteralPath $candidate)

    return $candidate
}

function Select-Images {
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = 'Choisir les images a combiner en un PDF'
    $dialog.Multiselect = $true
    $dialog.CheckFileExists = $true
    $dialog.Filter = 'Images|*.jpg;*.jpeg;*.jpe;*.jfif;*.png;*.webp;*.avif;*.heic;*.heif;*.gif;*.bmp;*.tif;*.tiff;*.jxl;*.ico|Tous les fichiers|*.*'

    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return @($dialog.FileNames)
    }

    return @()
}

$magickExe = Find-ImageMagick
if (-not $magickExe) {
    Show-WinPdfMessage -Icon Error -Text @'
ImageMagick est introuvable.

Installe ImageMagick 7 et coche l'option qui ajoute son dossier au PATH, puis relance WinImagesToPDF.
'@
    exit 2
}

if (-not $Paths -or @($Paths).Count -eq 0) {
    if ($NoDialog) {
        Show-WinPdfMessage -Icon Error -Text 'Usage : WinImagesToPDF.ps1 image1 [image2 ...] (ou un dossier d''images)'
        exit 2
    }

    $Paths = Select-Images
    if (-not $Paths -or @($Paths).Count -eq 0) {
        exit 0
    }
}

$imageFiles = New-Object 'System.Collections.Generic.List[System.IO.FileInfo]'
$skipped = @()

foreach ($rawPath in $Paths) {
    if ([string]::IsNullOrWhiteSpace($rawPath)) {
        continue
    }

    try {
        $item = Get-Item -LiteralPath $rawPath -ErrorAction Stop
    }
    catch {
        $skipped += ('{0} : introuvable' -f $rawPath)
        continue
    }

    if ($item.PSIsContainer) {
        $children = @(Get-ChildItem -LiteralPath $item.FullName -File -ErrorAction SilentlyContinue |
            Where-Object { $ImageExtensions -contains $_.Extension.ToLowerInvariant() })

        if ($children.Count -eq 0) {
            $skipped += ('{0} : aucune image dans ce dossier' -f $item.Name)
        }

        foreach ($child in $children) {
            $imageFiles.Add($child)
        }
    }
    elseif ($ImageExtensions -contains $item.Extension.ToLowerInvariant()) {
        $imageFiles.Add($item)
    }
    else {
        $skipped += ('{0} : format non pris en charge' -f $item.Name)
    }
}

# Retirer les doublons (meme fichier passe deux fois)
$seenPaths = @{}
$uniqueFiles = New-Object 'System.Collections.Generic.List[System.IO.FileInfo]'
foreach ($file in $imageFiles) {
    $key = $file.FullName.ToLowerInvariant()
    if (-not $seenPaths.ContainsKey($key)) {
        $seenPaths[$key] = $true
        $uniqueFiles.Add($file)
    }
}

if ($uniqueFiles.Count -eq 0) {
    $text = 'Aucune image a convertir.'
    if (@($skipped).Count -gt 0) {
        $text += [Environment]::NewLine + [Environment]::NewLine +
            ((@($skipped) | Select-Object -First 5) -join [Environment]::NewLine)
    }
    Show-WinPdfMessage -Icon Error -Text $text
    exit 1
}

# Tri "naturel" comme l'Explorateur Windows : page2 avant page10
$sortedImages = $uniqueFiles.ToArray()
[Array]::Sort($sortedImages, [System.Comparison[System.IO.FileInfo]] {
    param($a, $b)
    $result = [WinImagesToPDF.NativeMethods]::StrCmpLogicalW($a.Name, $b.Name)
    if ($result -eq 0) {
        $result = [WinImagesToPDF.NativeMethods]::StrCmpLogicalW($a.FullName, $b.FullName)
    }
    return $result
})

$outputPath = Get-AvailableOutputPath -FirstImage $sortedImages[0]

$magickArguments = New-Object 'System.Collections.Generic.List[string]'
foreach ($file in $sortedImages) {
    # [0] garde uniquement la premiere image des formats animes ou multi-pages.
    $magickArguments.Add($file.FullName + '[0]')
}
foreach ($argument in @(
        '-auto-orient',
        '-background', $BackgroundColor,
        '-alpha', 'remove',
        '-alpha', 'off',
        '-colorspace', 'sRGB',
        '-quality', ([string] $Quality),
        $outputPath)) {
    $magickArguments.Add($argument)
}

$previousErrorPreference = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    $nativeOutput = @(& $magickExe $magickArguments.ToArray() 2>&1)
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

    Show-WinPdfMessage -Icon Error -Text ('Echec de la creation du PDF.' +
        [Environment]::NewLine + [Environment]::NewLine + $details)
    exit 1
}

$lines = @()
$lines += ('PDF cree : {0}' -f [System.IO.Path]::GetFileName($outputPath))
$lines += ('{0} page(s), dans {1}' -f $sortedImages.Count, $sortedImages[0].DirectoryName)
$lines += ''
$lines += 'Ordre des pages :'

$displayCount = [Math]::Min($sortedImages.Count, 10)
for ($i = 0; $i -lt $displayCount; $i++) {
    $lines += ('  {0}. {1}' -f ($i + 1), $sortedImages[$i].Name)
}
if ($sortedImages.Count -gt 10) {
    $lines += ('  ... et {0} autre(s).' -f ($sortedImages.Count - 10))
}

if (@($skipped).Count -gt 0) {
    $lines += ''
    $lines += ('{0} fichier(s) ignore(s) :' -f @($skipped).Count)
    foreach ($entry in (@($skipped) | Select-Object -First 5)) {
        $lines += ('  {0}' -f $entry)
    }
    if (@($skipped).Count -gt 5) {
        $lines += ('  ... et {0} autre(s).' -f (@($skipped).Count - 5))
    }
}

if (@($skipped).Count -gt 0) {
    Show-WinPdfMessage -Icon Warning -Text ($lines -join [Environment]::NewLine)
}
elseif ($ShowSuccessMessage) {
    Show-WinPdfMessage -Icon Information -Text ($lines -join [Environment]::NewLine)
}

exit 0
