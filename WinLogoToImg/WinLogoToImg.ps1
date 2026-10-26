[CmdletBinding()]
param(
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]] $Paths
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

# Reglages faciles a modifier.
$JpegQuality = 90
$JpegBackgroundColor = 'white'
$LogoWidthRatio = 2.0 / 3.0
$WinLogoVersion = '1.1'
$script:WinLogoLogPath = $null

function Initialize-WinLogoLog {
    $script:WinLogoLogPath = $null
    $directories = @()
    if ($env:LOCALAPPDATA) {
        $directories += Join-Path $env:LOCALAPPDATA 'WinLogoToImg'
    }
    try {
        $temporaryRoot = $env:TEMP
        if (-not $temporaryRoot) { $temporaryRoot = [IO.Path]::GetTempPath() }
        $directories += Join-Path $temporaryRoot 'WinLogoToImg'
    }
    catch { }
    foreach ($directory in $directories) {
        try {
            [void] [IO.Directory]::CreateDirectory($directory)
            $candidate = Join-Path $directory 'WinLogoToImg.log'
            if ([IO.File]::Exists($candidate) -and (Get-Item -LiteralPath $candidate).Length -gt 1MB) {
                [IO.File]::Copy($candidate, ($candidate + '.1'), $true)
                [IO.File]::WriteAllText($candidate, '', (New-Object Text.UTF8Encoding($true)))
            }
            [IO.File]::AppendAllText($candidate, ("`r`n--- WinLogoToImg {0} / {1:yyyy-MM-dd HH:mm:ss.fff} ---`r`n" -f $WinLogoVersion, [DateTime]::Now), (New-Object Text.UTF8Encoding($true)))
            $script:WinLogoLogPath = $candidate
            break
        }
        catch {
            # Le journal ne doit jamais empecher le traitement ; essayer le repli.
        }
    }
}

function Write-WinLogoLog {
    param([string] $Text, [string] $Level = 'INFO')

    try {
        if ($script:WinLogoLogPath) {
            if ([IO.File]::Exists($script:WinLogoLogPath) -and (Get-Item -LiteralPath $script:WinLogoLogPath).Length -gt 1MB) {
                [IO.File]::Copy($script:WinLogoLogPath, ($script:WinLogoLogPath + '.1'), $true)
                [IO.File]::WriteAllText($script:WinLogoLogPath, '', (New-Object Text.UTF8Encoding($true)))
            }
            $line = '[{0:yyyy-MM-dd HH:mm:ss.fff}] [{1}] {2}' -f [DateTime]::Now, $Level, $Text
            [IO.File]::AppendAllText($script:WinLogoLogPath, ($line + "`r`n"), (New-Object Text.UTF8Encoding($true)))
        }
    }
    catch { }
}

function Get-WinLogoErrorText {
    param([System.Management.Automation.ErrorRecord] $Record)

    $text = ($Record | Format-List * -Force | Out-String).Trim()
    if ($Record.Exception) { $text += "`r`n" + $Record.Exception.ToString() }
    if ($Record.InvocationInfo) { $text += "`r`n" + $Record.InvocationInfo.PositionMessage }
    if ($Record.ScriptStackTrace) { $text += "`r`n" + $Record.ScriptStackTrace }
    return $text
}

function Show-WinLogoMessage {
    param(
        [string] $Text,
        [ValidateSet('Information', 'Error')]
        [string] $Icon = 'Information'
    )

    if ($Icon -eq 'Error' -and $script:WinLogoLogPath) {
        $Text += "`r`n`r`nJournal : " + $script:WinLogoLogPath
    }
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $iconValue = [System.Windows.Forms.MessageBoxIcon]::Information
        if ($Icon -eq 'Error') {
            $iconValue = [System.Windows.Forms.MessageBoxIcon]::Error
        }
        [void] [System.Windows.Forms.MessageBox]::Show(
            $Text, 'WinLogoToImg', [System.Windows.Forms.MessageBoxButtons]::OK, $iconValue
        )
    }
    catch {
        Write-WinLogoLog -Level WARN -Text ('Affichage du message impossible : ' + (Get-WinLogoErrorText -Record $_))
        try { [Console]::Error.WriteLine($Text) } catch { }
    }
}

function Find-ImageMagick {
    $command = Get-Command -Name 'magick.exe' -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($null -ne $command) {
        return $command.Source
    }

    $roots = @($env:ProgramFiles, ${env:ProgramFiles(x86)})
    if ($env:LOCALAPPDATA) {
        $roots += Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Programs'
    }
    foreach ($root in $roots) {
        if (-not $root -or -not (Test-Path -LiteralPath $root -PathType Container)) {
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

function Invoke-ImageMagick {
    param([string] $Executable, [string[]] $Arguments)

    # Ces guillemets servent uniquement au journal, jamais a executer la commande.
    $displayArguments = @($Arguments | ForEach-Object { '"' + $_.Replace('"', '\"') + '"' }) -join ' '
    Write-WinLogoLog -Text ('MAGICK "{0}" {1}' -f $Executable, $displayArguments)
    $nativeExitCode = 1
    $nativeOutput = @()
    $previousPreference = $ErrorActionPreference
    try {
        # Windows PowerShell transforme stderr en ErrorRecord, meme pour certains avertissements.
        $ErrorActionPreference = 'Continue'
        $nativeOutput = @(& $Executable @Arguments 2>&1)
        if (Test-Path -LiteralPath 'Variable:LASTEXITCODE') {
            $nativeExitCode = $LASTEXITCODE
        }
    }
    catch {
        Write-WinLogoLog -Level ERROR -Text ('Demarrage ImageMagick impossible : ' + (Get-WinLogoErrorText -Record $_))
        throw
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }

    $details = (($nativeOutput | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine).Trim()
    Write-WinLogoLog -Text ('MAGICK ExitCode={0}; Output={1}' -f $nativeExitCode, $details)
    if ($nativeExitCode -ne 0) {
        if ([string]::IsNullOrWhiteSpace($details)) {
            $details = 'ImageMagick a retourne le code ' + $nativeExitCode + '.'
        }
        if ($details.Length -gt 1200) {
            $details = $details.Substring(0, 1200) + '...'
        }
        throw $details
    }
    return $details
}

function Get-ImageInfo {
    param([string] $Executable, [System.IO.FileInfo] $File)

    # [0] : seule la premiere image des fichiers animes ou multipages est utilisee.
    $details = Invoke-ImageMagick -Executable $Executable -Arguments @(
        ($File.FullName + '[0]'), '-auto-orient', '-format', 'WINLOGO_SIZE:%w,%h', 'info:'
    )
    if ($details -notmatch '(?m)^WINLOGO_SIZE:(\d+),(\d+)\s*$') {
        throw ('Impossible de lire les dimensions de "{0}".' -f $File.Name)
    }

    $imageWidth = [int] $Matches[1]
    $imageHeight = [int] $Matches[2]
    if ($imageWidth -le 0 -or $imageHeight -le 0) {
        throw ('Dimensions invalides pour "{0}".' -f $File.Name)
    }
    return [PSCustomObject] @{
        File = $File
        Width = $imageWidth
        Height = $imageHeight
        Pixels = [long] $imageWidth * [long] $imageHeight
    }
}

function New-LogoChoiceForm {
    param($Suggested, $Other, $Preview)

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'WinLogoToImg - Choisir le logo'
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.ClientSize = New-Object System.Drawing.Size(760, 570)
    $form.MinimumSize = New-Object System.Drawing.Size(620, 500)
    $form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
    $form.KeyPreview = $true
    $form.MinimizeBox = $false
    $form.Font = New-Object System.Drawing.Font('Segoe UI', 10)

    $layout = New-Object System.Windows.Forms.TableLayoutPanel
    $layout.Dock = [System.Windows.Forms.DockStyle]::Fill
    $layout.Padding = New-Object System.Windows.Forms.Padding(16)
    $layout.ColumnCount = 1
    $layout.RowCount = 4
    [void] $layout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 100)))
    [void] $layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 80)))
    [void] $layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100)))
    [void] $layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 90)))
    [void] $layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 48)))
    $form.Controls.Add($layout)

    $heading = New-Object System.Windows.Forms.Label
    $heading.Dock = [System.Windows.Forms.DockStyle]::Fill
    $heading.Text = ("Est-ce cette image qui est le logo / watermark ?`r`n{0} ({1} x {2} pixels)" -f
        $Suggested.File.Name, $Suggested.Width, $Suggested.Height)
    $heading.AutoEllipsis = $true
    $layout.Controls.Add($heading, 0, 0)

    $picture = New-Object System.Windows.Forms.PictureBox
    $picture.Dock = [System.Windows.Forms.DockStyle]::Fill
    $picture.BackColor = [System.Drawing.Color]::LightGray
    $picture.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
    $picture.Image = $preview
    $layout.Controls.Add($picture, 0, 1)

    $instructions = New-Object System.Windows.Forms.Label
    $instructions.Dock = [System.Windows.Forms.DockStyle]::Fill
    $instructions.Padding = New-Object System.Windows.Forms.Padding(0, 10, 0, 0)
    $instructions.AutoEllipsis = $true
    $instructions.Text = ("Entrée ou Y : utiliser cette image comme logo.`r`nN : utiliser l'autre image comme logo : {0} ({1} x {2}).`r`nÉchap : annuler." -f
        $Other.File.Name, $Other.Width, $Other.Height)
    $layout.Controls.Add($instructions, 0, 2)

    $buttons = New-Object System.Windows.Forms.FlowLayoutPanel
    $buttons.Dock = [System.Windows.Forms.DockStyle]::Fill
    $buttons.FlowDirection = [System.Windows.Forms.FlowDirection]::LeftToRight
    $layout.Controls.Add($buttons, 0, 3)

    $yesButton = New-Object System.Windows.Forms.Button
    $yesButton.Text = 'Oui (Entrée / Y)'
    $yesButton.AutoSize = $true
    $yesButton.Height = 34
    $yesButton.DialogResult = [System.Windows.Forms.DialogResult]::Yes
    $buttons.Controls.Add($yesButton)

    $noButton = New-Object System.Windows.Forms.Button
    $noButton.Text = "Non, l'autre (N)"
    $noButton.AutoSize = $true
    $noButton.Height = 34
    $noButton.DialogResult = [System.Windows.Forms.DialogResult]::No
    $buttons.Controls.Add($noButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = 'Annuler'
    $cancelButton.AutoSize = $true
    $cancelButton.Height = 34
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $buttons.Controls.Add($cancelButton)

    $form.AcceptButton = $yesButton
    $form.CancelButton = $cancelButton
    $form.Add_KeyDown({
        param($sender, $eventArgs)
        if ($eventArgs.KeyCode -eq [System.Windows.Forms.Keys]::Y) {
            $eventArgs.SuppressKeyPress = $true
            $sender.DialogResult = [System.Windows.Forms.DialogResult]::Yes
        }
        elseif ($eventArgs.KeyCode -eq [System.Windows.Forms.Keys]::N) {
            $eventArgs.SuppressKeyPress = $true
            $sender.DialogResult = [System.Windows.Forms.DialogResult]::No
        }
    })
    return $form
}

function Show-LogoChoice {
    param($Suggested, $Other, [string] $Executable, [string] $PreviewPath)

    [void] (Invoke-ImageMagick -Executable $Executable -Arguments @(
        ($Suggested.File.FullName + '[0]'), '-auto-orient', '+repage',
        '-thumbnail', '680x340>', '-colorspace', 'sRGB', '-strip', ('PNG32:' + $PreviewPath)
    ))

    Add-Type -AssemblyName System.Drawing
    $form = $null
    $preview = $null
    try {
        $preview = [System.Drawing.Image]::FromFile($PreviewPath)
        $form = New-LogoChoiceForm -Suggested $Suggested -Other $Other -Preview $preview
        return $form.ShowDialog().ToString()
    }
    finally {
        if ($null -ne $form) {
            try { $form.Dispose() } catch { Write-WinLogoLog -Level WARN -Text ('Dispose fenetre : ' + $_.Exception.Message) }
        }
        if ($null -ne $preview) {
            try { $preview.Dispose() } catch { Write-WinLogoLog -Level WARN -Text ('Dispose apercu : ' + $_.Exception.Message) }
        }
    }
}

function Get-AvailableOutputPair {
    param([System.IO.FileInfo] $ParentFile)

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($ParentFile.Name) + '_wtrked'
    $index = 0
    do {
        $suffix = ''
        if ($index -gt 0) { $suffix = ' ({0})' -f $index }
        $pngPath = Join-Path -Path $ParentFile.DirectoryName -ChildPath ($baseName + $suffix + '.png')
        $jpgPath = Join-Path -Path $ParentFile.DirectoryName -ChildPath ($baseName + $suffix + '.jpg')
        $index++
    }
    while ((Test-Path -LiteralPath $pngPath) -or (Test-Path -LiteralPath $jpgPath))
    return [PSCustomObject] @{ Png = $pngPath; Jpg = $jpgPath }
}

function Save-WatermarkedImages {
    param($ParentImage, $LogoImage, [string] $Executable, [string] $WorkDirectory)

    $logoWidth = [math]::Max(1, [int] [math]::Round(
        $ParentImage.Width * $LogoWidthRatio, 0, [MidpointRounding]::AwayFromZero
    ))
    $pngTemporary = Join-Path -Path $WorkDirectory -ChildPath 'result.png'
    $jpgTemporary = Join-Path -Path $WorkDirectory -ChildPath 'result.jpg'

    [void] (Invoke-ImageMagick -Executable $Executable -Arguments @(
        ($ParentImage.File.FullName + '[0]'), '-auto-orient', '+repage', '-colorspace', 'sRGB',
        '(', ($LogoImage.File.FullName + '[0]'), '-auto-orient', '+repage',
        '-colorspace', 'sRGB', '-resize', $logoWidth.ToString([Globalization.CultureInfo]::InvariantCulture), '+repage', ')',
        '-gravity', 'center', '-compose', 'over', '-composite', '+repage', '-depth', '8',
        ('PNG:' + $pngTemporary)
    ))
    [void] (Invoke-ImageMagick -Executable $Executable -Arguments @(
        $pngTemporary, '-background', $JpegBackgroundColor, '-alpha', 'remove', '-alpha', 'off',
        '-colorspace', 'sRGB', '-quality', $JpegQuality.ToString([Globalization.CultureInfo]::InvariantCulture),
        ('JPEG:' + $jpgTemporary)
    ))

    # Les deux conversions doivent reussir avant de publier les fichiers dans le dossier source.
    $outputs = Get-AvailableOutputPair -ParentFile $ParentImage.File
    [System.IO.File]::Copy($pngTemporary, $outputs.Png, $false)
    try {
        [System.IO.File]::Copy($jpgTemporary, $outputs.Jpg, $false)
    }
    catch {
        # Ce PNG vient uniquement d'etre cree par cette execution.
        [System.IO.File]::Delete($outputs.Png)
        throw
    }
    return $outputs
}

function Invoke-WinLogoToImg {
    param([string[]] $InputPaths)

    $workDirectory = $null
    $exitCode = 1
    try {
        Initialize-WinLogoLog
        Write-WinLogoLog -Text ('Version={0}; PowerShell={1}; Apartment={2}; LanguageMode={3}; Script={4}' -f
            $WinLogoVersion, $PSVersionTable.PSVersion, [Threading.Thread]::CurrentThread.ApartmentState,
            $ExecutionContext.SessionState.LanguageMode, $PSCommandPath)
        Write-WinLogoLog -Text ('Arguments=' + (ConvertTo-Json -InputObject @($InputPaths) -Compress))
        if (@($InputPaths).Count -ne 2) {
            throw 'Sélectionne exactement 2 fichiers images, puis clic droit > Envoyer vers > WinLogoToImg - Ajouter un logo.'
        }
        $files = @()
        foreach ($inputPath in $InputPaths) {
            $file = Get-Item -LiteralPath $inputPath -ErrorAction Stop
            if ($file.PSIsContainer -or $file -isnot [System.IO.FileInfo]) {
                throw ('"{0}" n''est pas un fichier image.' -f $inputPath)
            }
            $files += $file
        }
        if ([string]::Equals($files[0].FullName, $files[1].FullName, [StringComparison]::OrdinalIgnoreCase)) {
            throw 'Sélectionne 2 fichiers images différents.'
        }

        $magickExe = Find-ImageMagick
        Write-WinLogoLog -Text ('ImageMagick=' + $magickExe)
        if (-not $magickExe) {
            throw 'ImageMagick est introuvable. Installe ImageMagick 7 avec son ajout au PATH, puis relance WinLogoToImg.'
        }
        $images = @(
            Get-ImageInfo -Executable $magickExe -File $files[0]
            Get-ImageInfo -Executable $magickExe -File $files[1]
        )
        # La plus petite image est celle qui compte le moins de pixels, pas le moins d'octets.
        # En cas d'egalite, la premiere image selectionnee est proposee.
        $suggested = $images[0]
        $other = $images[1]
        if ($images[1].Pixels -lt $images[0].Pixels) {
            $suggested = $images[1]
            $other = $images[0]
        }
        Write-WinLogoLog -Text ('Logo propose={0} ({1}x{2}); autre={3} ({4}x{5})' -f
            $suggested.File.FullName, $suggested.Width, $suggested.Height,
            $other.File.FullName, $other.Width, $other.Height)

        $workDirectory = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ('WinLogoToImg-' + [guid]::NewGuid().ToString('N'))
        [void] [System.IO.Directory]::CreateDirectory($workDirectory)
        $previewPath = Join-Path -Path $workDirectory -ChildPath 'preview.png'
        $choice = Show-LogoChoice -Suggested $suggested -Other $other -Executable $magickExe -PreviewPath $previewPath
        Write-WinLogoLog -Text ('Choice=' + $choice)
        if ($choice -eq 'Yes') {
            $logoImage = $suggested
            $parentImage = $other
        }
        elseif ($choice -eq 'No') {
            $logoImage = $other
            $parentImage = $suggested
        }
        else {
            $exitCode = 0
            return 0
        }

        $outputs = Save-WatermarkedImages -ParentImage $parentImage -LogoImage $logoImage -Executable $magickExe -WorkDirectory $workDirectory
        Write-WinLogoLog -Text ('Exports={0}; {1}' -f $outputs.Png, $outputs.Jpg)
        $exitCode = 0
        Show-WinLogoMessage -Text ("Les deux images ont été créées :`r`n`r`n{0}`r`n{1}" -f $outputs.Png, $outputs.Jpg)
        return 0
    }
    catch {
        $failure = $_
        $exitCode = 1
        $details = Get-WinLogoErrorText -Record $failure
        Write-WinLogoLog -Level ERROR -Text $details
        try { [Console]::Error.WriteLine($details) } catch { }
        Show-WinLogoMessage -Icon Error -Text $failure.Exception.Message
        return 1
    }
    finally {
        if ($workDirectory) {
            # Nettoyage limite aux trois fichiers temporaires connus, sans suppression recursive.
            foreach ($temporaryName in @('preview.png', 'result.png', 'result.jpg')) {
                $temporaryPath = Join-Path -Path $workDirectory -ChildPath $temporaryName
                try { [System.IO.File]::Delete($temporaryPath) } catch { }
            }
            try { [System.IO.Directory]::Delete($workDirectory, $false) } catch { }
        }
        Write-WinLogoLog -Text ('ExitCode=' + $exitCode)
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    $processExitCode = 1
    try {
        $processExitCode = Invoke-WinLogoToImg -InputPaths $Paths
    }
    catch {
        $fatalError = $_
        if (-not $script:WinLogoLogPath) { Initialize-WinLogoLog }
        $fatalText = Get-WinLogoErrorText -Record $fatalError
        Write-WinLogoLog -Level FATAL -Text $fatalText
        try { [Console]::Error.WriteLine($fatalText) } catch { }
    }
    Write-WinLogoLog -Text ('Process ExitCode=' + $processExitCode)
    exit $processExitCode
}
