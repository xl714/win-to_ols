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
$OutputSuffix = ' - fusion'   # Nom du PDF final = nom du premier PDF + ce suffixe
$ShowSuccessMessage = $true   # Mettre $false pour ne rien afficher si tout va bien
$OverwriteExisting = $false   # Si false, cree "nom (1).pdf" au lieu d'ecraser

Add-Type -AssemblyName System.Windows.Forms

if (-not ('WinMergePDFs.NativeMethods' -as [type])) {
    Add-Type -Namespace 'WinMergePDFs' -Name 'NativeMethods' -MemberDefinition @'
[DllImport("shlwapi.dll", CharSet = CharSet.Unicode)]
public static extern int StrCmpLogicalW(string x, string y);
'@
}

function Show-WinMergeMessage {
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
        'WinMergePDFs',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        $iconValue
    )
}

function Find-Qpdf {
    $command = Get-Command -Name 'qpdf.exe' -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if ($null -ne $command) {
        return $command.Source
    }

    # Sinon, chercher un dossier "qpdf*" (installateur classique ou zip portable)
    $roots = @()
    if ($PSScriptRoot) {
        $roots += $PSScriptRoot
    }
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

        $directories = Get-ChildItem -LiteralPath $root -Directory -Filter 'qpdf*' -ErrorAction SilentlyContinue |
            Sort-Object -Property LastWriteTime -Descending

        foreach ($directory in $directories) {
            foreach ($candidate in @(
                    (Join-Path -Path $directory.FullName -ChildPath 'bin\qpdf.exe'),
                    (Join-Path -Path $directory.FullName -ChildPath 'qpdf.exe'))) {
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
        [System.IO.FileInfo] $FirstPdf,

        # Chemins complets (en minuscules) des PDF d'entree : jamais reutilises comme sortie
        [Parameter(Mandatory = $true)]
        [hashtable] $InputKeys
    )

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($FirstPdf.Name) + $OutputSuffix
    $candidate = Join-Path -Path $FirstPdf.DirectoryName -ChildPath ($baseName + '.pdf')

    $isInput = $InputKeys.ContainsKey($candidate.ToLowerInvariant())
    if (-not $isInput -and ($OverwriteExisting -or -not (Test-Path -LiteralPath $candidate))) {
        return $candidate
    }

    $index = 1
    do {
        $candidate = Join-Path -Path $FirstPdf.DirectoryName -ChildPath ('{0} ({1}).pdf' -f $baseName, $index)
        $index++
    }
    while ((Test-Path -LiteralPath $candidate) -or $InputKeys.ContainsKey($candidate.ToLowerInvariant()))

    return $candidate
}

function Select-Pdfs {
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = 'Choisir les PDF a fusionner (au moins deux)'
    $dialog.Multiselect = $true
    $dialog.CheckFileExists = $true
    $dialog.Filter = 'Fichiers PDF|*.pdf|Tous les fichiers|*.*'

    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return @($dialog.FileNames)
    }

    return @()
}

$qpdfExe = Find-Qpdf
if (-not $qpdfExe) {
    Show-WinMergeMessage -Icon Error -Text @'
qpdf est introuvable.

Installe-le puis relance WinMergePDFs. Dans un terminal :

  winget install --id QPDF.QPDF -e

Ou decompresse le zip de https://github.com/qpdf/qpdf/releases dans %LOCALAPPDATA%\Programs.
'@
    exit 2
}

if (-not $Paths -or @($Paths).Count -eq 0) {
    if ($NoDialog) {
        Show-WinMergeMessage -Icon Error -Text 'Usage : WinMergePDFs.ps1 fichier1.pdf fichier2.pdf [...] (ou un dossier de PDF)'
        exit 2
    }

    $Paths = Select-Pdfs
    if (-not $Paths -or @($Paths).Count -eq 0) {
        exit 0
    }
}

$pdfFiles = New-Object 'System.Collections.Generic.List[System.IO.FileInfo]'
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
            Where-Object { $_.Extension.ToLowerInvariant() -eq '.pdf' })

        if ($children.Count -eq 0) {
            $skipped += ('{0} : aucun PDF dans ce dossier' -f $item.Name)
        }

        foreach ($child in $children) {
            $pdfFiles.Add($child)
        }
    }
    elseif ($item.Extension.ToLowerInvariant() -eq '.pdf') {
        $pdfFiles.Add($item)
    }
    else {
        $skipped += ('{0} : ce n''est pas un PDF' -f $item.Name)
    }
}

# Retirer les doublons (meme fichier passe deux fois)
$seenPaths = @{}
$uniqueFiles = New-Object 'System.Collections.Generic.List[System.IO.FileInfo]'
foreach ($file in $pdfFiles) {
    $key = $file.FullName.ToLowerInvariant()
    if (-not $seenPaths.ContainsKey($key)) {
        $seenPaths[$key] = $true
        $uniqueFiles.Add($file)
    }
}

if ($uniqueFiles.Count -lt 2) {
    if ($uniqueFiles.Count -eq 0) {
        $text = 'Aucun fichier PDF a fusionner.'
    }
    else {
        $text = 'Un seul PDF trouve ({0}) : il en faut au moins deux pour une fusion.' -f $uniqueFiles[0].Name
    }
    if (@($skipped).Count -gt 0) {
        $text += [Environment]::NewLine + [Environment]::NewLine +
            ((@($skipped) | Select-Object -First 5) -join [Environment]::NewLine)
    }
    Show-WinMergeMessage -Icon Error -Text $text
    exit 1
}

# Tri "naturel" comme l'Explorateur Windows : doc2 avant doc10
$sortedPdfs = $uniqueFiles.ToArray()
[Array]::Sort($sortedPdfs, [System.Comparison[System.IO.FileInfo]] {
    param($a, $b)
    $result = [WinMergePDFs.NativeMethods]::StrCmpLogicalW($a.Name, $b.Name)
    if ($result -eq 0) {
        $result = [WinMergePDFs.NativeMethods]::StrCmpLogicalW($a.FullName, $b.FullName)
    }
    return $result
})

$outputPath = Get-AvailableOutputPath -FirstPdf $sortedPdfs[0] -InputKeys $seenPaths

# qpdf --empty --pages fichier1.pdf fichier2.pdf ... -- sortie.pdf
# Les pages sont copiees telles quelles (pas de recompression des images).
$qpdfArguments = New-Object 'System.Collections.Generic.List[string]'
$qpdfArguments.Add('--empty')
$qpdfArguments.Add('--pages')
foreach ($file in $sortedPdfs) {
    $qpdfArguments.Add($file.FullName)
}
$qpdfArguments.Add('--')
$qpdfArguments.Add($outputPath)

$previousErrorPreference = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    $nativeOutput = @(& $qpdfExe $qpdfArguments.ToArray() 2>&1)
    $exitCode = $LASTEXITCODE
}
finally {
    $ErrorActionPreference = $previousErrorPreference
}

$details = (($nativeOutput | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine).Trim()
if ($details.Length -gt 900) {
    $details = $details.Substring(0, 900) + '...'
}

# Codes de sortie de qpdf : 0 = OK, 3 = OK avec avertissements, autre = erreur
$hasWarnings = ($exitCode -eq 3)
$outputExists = Test-Path -LiteralPath $outputPath -PathType Leaf

if (($exitCode -ne 0 -and -not $hasWarnings) -or -not $outputExists) {
    if ($outputExists) {
        # Ne pas laisser un PDF incomplet derriere soi
        Remove-Item -LiteralPath $outputPath -Force -ErrorAction SilentlyContinue
    }
    if ([string]::IsNullOrWhiteSpace($details)) {
        $details = 'qpdf a retourne le code ' + $exitCode + '.'
    }

    Show-WinMergeMessage -Icon Error -Text ('Echec de la fusion des PDF.' +
        [Environment]::NewLine + [Environment]::NewLine + $details)
    exit 1
}

# Nombre de pages du PDF final (facultatif : ignore en cas de probleme)
$pageCount = $null
try {
    $ErrorActionPreference = 'Continue'
    $countOutput = @(& $qpdfExe '--show-npages' $outputPath 2>&1)
    if ($LASTEXITCODE -eq 0) {
        foreach ($line in $countOutput) {
            $parsed = 0
            if ([int]::TryParse($line.ToString().Trim(), [ref] $parsed)) {
                $pageCount = $parsed
                break
            }
        }
    }
}
catch {
    $pageCount = $null
}
finally {
    $ErrorActionPreference = $previousErrorPreference
}

$lines = @()
$lines += ('PDF cree : {0}' -f [System.IO.Path]::GetFileName($outputPath))
if ($null -ne $pageCount) {
    $lines += ('{0} fichier(s) fusionne(s), {1} page(s), dans {2}' -f $sortedPdfs.Count, $pageCount, [System.IO.Path]::GetDirectoryName($outputPath))
}
else {
    $lines += ('{0} fichier(s) fusionne(s), dans {1}' -f $sortedPdfs.Count, [System.IO.Path]::GetDirectoryName($outputPath))
}
$lines += ''
$lines += 'Ordre des fichiers :'

$displayCount = [Math]::Min($sortedPdfs.Count, 10)
for ($i = 0; $i -lt $displayCount; $i++) {
    $lines += ('  {0}. {1}' -f ($i + 1), $sortedPdfs[$i].Name)
}
if ($sortedPdfs.Count -gt 10) {
    $lines += ('  ... et {0} autre(s).' -f ($sortedPdfs.Count - 10))
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

if ($hasWarnings -and -not [string]::IsNullOrWhiteSpace($details)) {
    $lines += ''
    $lines += 'Avertissements de qpdf (le PDF a quand meme ete cree) :'
    $lines += $details
}

if (@($skipped).Count -gt 0 -or $hasWarnings) {
    Show-WinMergeMessage -Icon Warning -Text ($lines -join [Environment]::NewLine)
}
elseif ($ShowSuccessMessage) {
    Show-WinMergeMessage -Icon Information -Text ($lines -join [Environment]::NewLine)
}

exit 0
