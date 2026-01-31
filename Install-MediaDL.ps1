<#
.SYNOPSIS
    MediaDL Installer - Universal Media Downloader Setup
.DESCRIPTION
    Installs and configures:
    - yt-dlp (auto-download)
    - ffmpeg (auto-download)
    - Download protocol handler (ytdl://) with progress UI
    - Userscript for 1800+ site integration
.NOTES
    Author: SysAdminDoc
    Version: 1.0.0
    Based on YTYT-Downloader v2.0.0
    Repository: https://github.com/SysAdminDoc/MediaDL
#>

#Requires -Version 5.1

# ============================================
# HIDE CONSOLE WINDOW
# ============================================
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
$consolePtr = [Console.Window]::GetConsoleWindow()
[Console.Window]::ShowWindow($consolePtr, 0) | Out-Null

# ============================================
# CONFIGURATION
# ============================================
$script:AppName = "MediaDL"
$script:AppVersion = "1.0.0"
$script:InstallPath = "$env:LOCALAPPDATA\YTYT-Downloader"
$script:YtDlpUrl = "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"
$script:FfmpegUrl = "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
$script:DefaultDownloadPath = "$env:USERPROFILE\Videos\YouTube"
$script:GitHubRepo = "https://github.com/SysAdminDoc/MediaDL"
$script:UserscriptUrl = "https://github.com/SysAdminDoc/MediaDL/raw/refs/heads/main/MediaDL.user.js"

# ============================================
# ASSEMBLIES
# ============================================
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============================================
# HELPER FUNCTIONS
# ============================================
function Download-File {
    param([string]$Url, [string]$OutPath)
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "Mozilla/5.0")
        $webClient.DownloadFile($Url, $OutPath)
        $webClient.Dispose()
        return $true
    } catch {
        return $false
    }
}

# ============================================
# PRE-FLIGHT CHECKS
# ============================================
$tempDir = Join-Path $env:TEMP "MediaDL-Installer"
if (!(Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }

# ============================================
# AUTO-UNINSTALL PREVIOUS VERSION
# ============================================
function Uninstall-Previous {
    @("yt-dlp", "ffmpeg", "ffprobe") | ForEach-Object {
        Get-Process -Name $_ -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    }
    Start-Sleep -Milliseconds 500
    
    # Remove protocol handlers (will be re-registered)
    @("ytvlc", "ytvlcq", "ytdl", "ytmpv", "ytdlplay") | ForEach-Object {
        Remove-Item -Path "HKCU:\Software\Classes\$_" -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Only remove old MediaDL-specific directory if it exists (not the shared YTYT directory)
    if (Test-Path "$env:LOCALAPPDATA\MediaDL") {
        Remove-Item -Path "$env:LOCALAPPDATA\MediaDL" -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Remove desktop shortcuts
    @("MediaDL Downloads.lnk", "YouTube Download.lnk") | ForEach-Object {
        $shortcutPath = "$env:USERPROFILE\Desktop\$_"
        if (Test-Path $shortcutPath) {
            Remove-Item $shortcutPath -Force -ErrorAction SilentlyContinue
        }
    }
}

Uninstall-Previous

# Check for existing yt-dlp
$ytdlpExists = $null
@("$script:InstallPath\yt-dlp.exe", "$env:LOCALAPPDATA\MediaDL\yt-dlp.exe", "$env:LOCALAPPDATA\yt-dlp\yt-dlp.exe") | ForEach-Object {
    if (Test-Path $_) { $ytdlpExists = $_ }
}
if (!$ytdlpExists) {
    $ytdlpCmd = Get-Command yt-dlp -ErrorAction SilentlyContinue
    if ($ytdlpCmd) { $ytdlpExists = $ytdlpCmd.Source }
}

# Check for existing ffmpeg
$ffmpegExists = $null
@("$script:InstallPath\ffmpeg.exe", "$env:LOCALAPPDATA\MediaDL\ffmpeg.exe") | ForEach-Object {
    if (Test-Path $_) { $ffmpegExists = $_ }
}
if (!$ffmpegExists) {
    $ffmpegCmd = Get-Command ffmpeg -ErrorAction SilentlyContinue
    if ($ffmpegCmd) { $ffmpegExists = $ffmpegCmd.Source }
}

# ============================================
# XAML GUI DEFINITION
# ============================================
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="MediaDL Setup" Height="720" Width="550"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
        Background="#0f0f0f">
    <Window.Resources>
        <SolidColorBrush x:Key="BgDark" Color="#0f0f0f"/>
        <SolidColorBrush x:Key="BgCard" Color="#1a1a1a"/>
        <SolidColorBrush x:Key="Border" Color="#2a2a2a"/>
        <SolidColorBrush x:Key="TextPrimary" Color="#fafafa"/>
        <SolidColorBrush x:Key="TextSecondary" Color="#a1a1aa"/>
        <SolidColorBrush x:Key="AccentGreen" Color="#00b894"/>
        <SolidColorBrush x:Key="AccentGreenHover" Color="#00a085"/>
        
        <Style x:Key="PrimaryButton" TargetType="Button">
            <Setter Property="Background" Value="{StaticResource AccentGreen}"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="24,14"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="8" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="{StaticResource AccentGreenHover}"/>
                </Trigger>
                <Trigger Property="IsEnabled" Value="False">
                    <Setter Property="Opacity" Value="0.5"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        
        <Style x:Key="SecondaryButton" TargetType="Button">
            <Setter Property="Background" Value="{StaticResource BgCard}"/>
            <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
            <Setter Property="BorderBrush" Value="{StaticResource Border}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="20,12"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="8" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#252525"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Margin" Value="0,6,0,0"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>
        
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="{StaticResource BgCard}"/>
            <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
            <Setter Property="BorderBrush" Value="{StaticResource Border}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="10,8"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="CaretBrush" Value="{StaticResource TextPrimary}"/>
        </Style>
    </Window.Resources>
    
    <Grid Margin="30">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <!-- Header -->
        <StackPanel Grid.Row="0" Margin="0,0,0,25">
            <TextBlock Text="MediaDL" FontSize="36" FontWeight="Bold" Foreground="#00b894"/>
            <TextBlock Text="Universal Media Downloader" FontSize="14" Foreground="#888" Margin="0,5,0,0"/>
            <TextBlock Text="Download from YouTube, Twitter, TikTok, and 1800+ sites" FontSize="12" Foreground="#666" Margin="0,3,0,0"/>
        </StackPanel>
        
        <!-- Settings Panel -->
        <StackPanel Grid.Row="1" x:Name="OptionsPanel">
            <!-- Download Path -->
            <Border Background="#1a1a1a" CornerRadius="10" Padding="18" Margin="0,0,0,12">
                <StackPanel>
                    <TextBlock Text="Download Location" FontSize="13" FontWeight="SemiBold" Foreground="White" Margin="0,0,0,10"/>
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <TextBox x:Name="txtDownloadPath" Grid.Column="0"/>
                        <Button x:Name="btnBrowse" Grid.Column="1" Content="Browse" Style="{StaticResource SecondaryButton}" Margin="10,0,0,0" Padding="16,8"/>
                    </Grid>
                </StackPanel>
            </Border>
            
            <!-- Components -->
            <Border Background="#1a1a1a" CornerRadius="10" Padding="18" Margin="0,0,0,12">
                <StackPanel>
                    <TextBlock Text="Components" FontSize="13" FontWeight="SemiBold" Foreground="White" Margin="0,0,0,10"/>
                    <CheckBox x:Name="chkYtDlp" Content="Install/Update yt-dlp (required)" IsChecked="True" IsEnabled="False"/>
                    <CheckBox x:Name="chkFfmpeg" Content="Install ffmpeg (required for MP3/video merging)" IsChecked="True"/>
                    <CheckBox x:Name="chkProtocols" Content="Register download protocol handlers" IsChecked="True"/>
                    <CheckBox x:Name="chkDesktopShortcut" Content="Create desktop shortcut to downloads folder" IsChecked="False"/>
                </StackPanel>
            </Border>
            
            <!-- Detected -->
            <Border Background="#1a1a1a" CornerRadius="10" Padding="18">
                <StackPanel>
                    <TextBlock Text="Detected Components" FontSize="13" FontWeight="SemiBold" Foreground="White" Margin="0,0,0,10"/>
                    <TextBlock x:Name="txtYtDlpStatus" Text="Checking yt-dlp..." Foreground="#888" FontSize="12"/>
                    <TextBlock x:Name="txtFfmpegStatus" Text="Checking ffmpeg..." Foreground="#888" FontSize="12" Margin="0,4,0,0"/>
                </StackPanel>
            </Border>
        </StackPanel>
        
        <!-- Log Output -->
        <Border Grid.Row="2" Background="#0a0a0a" CornerRadius="8" Margin="0,15,0,0" x:Name="LogBorder" Visibility="Collapsed">
            <ScrollViewer x:Name="LogScroller" VerticalScrollBarVisibility="Auto">
                <TextBlock x:Name="txtLog" Foreground="#aaa" FontFamily="Consolas" FontSize="11"
                           Padding="14" TextWrapping="Wrap"/>
            </ScrollViewer>
        </Border>
        
        <!-- Progress -->
        <StackPanel Grid.Row="3" Margin="0,15,0,0">
            <Border Background="#1a1a1a" CornerRadius="5" Height="8">
                <Border x:Name="ProgressFill" Background="#00b894" CornerRadius="5" HorizontalAlignment="Left" Width="0"/>
            </Border>
            <TextBlock x:Name="txtStatus" Text="Ready to install" Foreground="#888" FontSize="12" Margin="0,10,0,0" HorizontalAlignment="Center"/>
        </StackPanel>
        
        <!-- Buttons -->
        <StackPanel Grid.Row="4" Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,20,0,0">
            <Button x:Name="btnInstall" Content="Install MediaDL" Style="{StaticResource PrimaryButton}" Width="200"/>
            <Button x:Name="btnCancel" Content="Cancel" Style="{StaticResource SecondaryButton}" Width="100" Margin="15,0,0,0"/>
        </StackPanel>
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get controls
$txtDownloadPath = $window.FindName("txtDownloadPath")
$btnBrowse = $window.FindName("btnBrowse")
$chkFfmpeg = $window.FindName("chkFfmpeg")
$chkProtocols = $window.FindName("chkProtocols")
$chkDesktopShortcut = $window.FindName("chkDesktopShortcut")
$txtYtDlpStatus = $window.FindName("txtYtDlpStatus")
$txtFfmpegStatus = $window.FindName("txtFfmpegStatus")
$txtLog = $window.FindName("txtLog")
$txtStatus = $window.FindName("txtStatus")
$ProgressFill = $window.FindName("ProgressFill")
$btnInstall = $window.FindName("btnInstall")
$btnCancel = $window.FindName("btnCancel")
$LogBorder = $window.FindName("LogBorder")
$LogScroller = $window.FindName("LogScroller")
$OptionsPanel = $window.FindName("OptionsPanel")

# Set defaults
$txtDownloadPath.Text = $script:DefaultDownloadPath

# Update status displays
if ($ytdlpExists) {
    $txtYtDlpStatus.Text = "yt-dlp: Found (will update)"
    $txtYtDlpStatus.Foreground = "#00b894"
} else {
    $txtYtDlpStatus.Text = "yt-dlp: Will be installed"
    $txtYtDlpStatus.Foreground = "#888"
}

if ($ffmpegExists) {
    $txtFfmpegStatus.Text = "ffmpeg: Found"
    $txtFfmpegStatus.Foreground = "#00b894"
    $chkFfmpeg.IsChecked = $false
} else {
    $txtFfmpegStatus.Text = "ffmpeg: Will be installed"
    $txtFfmpegStatus.Foreground = "#888"
}

# Browse button
$btnBrowse.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select download folder"
    $folderBrowser.SelectedPath = $txtDownloadPath.Text
    if ($folderBrowser.ShowDialog() -eq "OK") {
        $txtDownloadPath.Text = $folderBrowser.SelectedPath
    }
})

# Cancel button
$btnCancel.Add_Click({
    $window.Close()
})

# Helper functions for UI updates
function Update-Log {
    param([string]$Message, [string]$Color = "#aaa")
    $txtLog.Dispatcher.Invoke([action]{
        $run = New-Object System.Windows.Documents.Run
        $run.Text = "$Message`n"
        $run.Foreground = $Color
        $txtLog.Inlines.Add($run)
        $LogScroller.ScrollToEnd()
    })
}

function Set-Progress {
    param([int]$Percent)
    $ProgressFill.Dispatcher.Invoke([action]{
        $ProgressFill.Width = [int](($Percent / 100) * 490)
    })
}

function Update-Status {
    param([string]$Text)
    $txtStatus.Dispatcher.Invoke([action]{
        $txtStatus.Text = $Text
    })
    Update-Log $Text
}

$script:InstallComplete = $false

# Install button
$btnInstall.Add_Click({
    if ($script:InstallComplete) {
        # Open userscript URL
        Start-Process $script:UserscriptUrl
        return
    }
    
    $btnInstall.IsEnabled = $false
    $OptionsPanel.Visibility = "Collapsed"
    $LogBorder.Visibility = "Visible"
    
    try {
        $dlPath = $txtDownloadPath.Text
        
        # Step 1: Create directories
        Update-Status "Creating directories..."
        if (!(Test-Path $script:InstallPath)) {
            New-Item -ItemType Directory -Path $script:InstallPath -Force | Out-Null
        }
        if (!(Test-Path $dlPath)) {
            New-Item -ItemType Directory -Path $dlPath -Force | Out-Null
        }
        Update-Log "  [OK] Directories created" "#00b894"
        Set-Progress 10
        
        # Step 2: Download yt-dlp
        Update-Status "Downloading yt-dlp..."
        $ytdlpPath = Join-Path $script:InstallPath "yt-dlp.exe"
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "Mozilla/5.0")
        $wc.DownloadFile($script:YtDlpUrl, $ytdlpPath)
        $wc.Dispose()
        Update-Log "  [OK] yt-dlp downloaded" "#00b894"
        Set-Progress 30
        
        # Step 3: Download ffmpeg if needed
        $ffmpegPath = $ffmpegExists
        if ($chkFfmpeg.IsChecked -and !$ffmpegExists) {
            Update-Status "Downloading ffmpeg (this may take a moment)..."
            $ffmpegZip = Join-Path $env:TEMP "ffmpeg.zip"
            $wc = New-Object System.Net.WebClient
            $wc.Headers.Add("User-Agent", "Mozilla/5.0")
            $wc.DownloadFile($script:FfmpegUrl, $ffmpegZip)
            $wc.Dispose()
            
            Update-Log "  Extracting ffmpeg..." "#888"
            $extractPath = Join-Path $env:TEMP "ffmpeg_extract"
            Expand-Archive -Path $ffmpegZip -DestinationPath $extractPath -Force
            
            $ffmpegBin = Get-ChildItem -Path $extractPath -Recurse -Filter "ffmpeg.exe" | Select-Object -First 1
            if ($ffmpegBin) {
                Copy-Item $ffmpegBin.FullName -Destination $script:InstallPath -Force
                $ffprobePath = Join-Path $ffmpegBin.DirectoryName "ffprobe.exe"
                if (Test-Path $ffprobePath) {
                    Copy-Item $ffprobePath -Destination $script:InstallPath -Force
                }
                $ffmpegPath = Join-Path $script:InstallPath "ffmpeg.exe"
            }
            
            Remove-Item $ffmpegZip -Force -ErrorAction SilentlyContinue
            Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
            Update-Log "  [OK] ffmpeg installed" "#00b894"
        } elseif ($ffmpegExists) {
            $ffmpegPath = $ffmpegExists
            Update-Log "  [OK] Using existing ffmpeg" "#00b894"
        }
        Set-Progress 50
        
        # Step 4: Save config
        Update-Status "Saving configuration..."
        $config = @{
            DownloadPath = $dlPath
            YtDlpPath = $ytdlpPath
            FfmpegPath = $ffmpegPath
            Notifications = $true
            AutoUpdate = $true
        }
        $config | ConvertTo-Json | Set-Content (Join-Path $script:InstallPath "config.json") -Encoding UTF8
        Update-Log "  [OK] Configuration saved" "#00b894"
        Set-Progress 55
        
        # Step 5: Create protocol handlers
        if ($chkProtocols.IsChecked) {
            Update-Status "Creating protocol handlers..."
            
            # Download Handler with Progress UI (based on original YTYT)
            $dlHandler = @'
param([string]$url)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$configPath = Join-Path $PSScriptRoot "config.json"
$config = Get-Content $configPath -Raw | ConvertFrom-Json

$videoUrl = $url -replace '^ytdl://', ''
$videoUrl = [System.Uri]::UnescapeDataString($videoUrl)

$audioOnly = $videoUrl -match "ytyt_audio_only=1|mediadl_audio_only=1"
$videoUrl = $videoUrl -replace "[&?](ytyt_audio_only|mediadl_audio_only)=1", ""

$progressFile = Join-Path $env:TEMP "mediadl_progress_$([guid]::NewGuid().ToString('N')).txt"

# Create progress form
$form = New-Object System.Windows.Forms.Form
$form.Text = "MediaDL Download"
$form.Size = New-Object System.Drawing.Size(420, 140)
$form.FormBorderStyle = "None"
$form.StartPosition = "Manual"
$form.BackColor = [System.Drawing.Color]::FromArgb(18, 18, 18)
$form.TopMost = $true
$form.ShowInTaskbar = $false

# Position bottom-right, stacking for multiple downloads
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$baseX = $screen.Right - 436
$baseY = $screen.Bottom - 156

$script:mySlot = 0
for ($i = 0; $i -lt 6; $i++) {
    $slotFile = Join-Path $env:TEMP "mediadl_slot_$i.lock"
    if (!(Test-Path $slotFile)) {
        $script:mySlot = $i
        "lock" | Out-File $slotFile -Force
        break
    }
}

$offsetY = $script:mySlot * 150
$newY = $baseY - $offsetY
if ($newY -lt 50) { $newY = 50 }
$form.Location = New-Object System.Drawing.Point($baseX, $newY)

# Make draggable
$script:dragStart = $null
$form.Add_MouseDown({ param($s,$e) if ($e.Button -eq "Left") { $script:dragStart = $e.Location } })
$form.Add_MouseMove({ param($s,$e) if ($script:dragStart) { $form.Location = [System.Drawing.Point]::new(($form.Location.X + $e.X - $script:dragStart.X), ($form.Location.Y + $e.Y - $script:dragStart.Y)) } })
$form.Add_MouseUp({ $script:dragStart = $null })

# Header
$lblHeader = New-Object System.Windows.Forms.Label
$lblHeader.Text = if ($audioOnly) { "MediaDL - Audio" } else { "MediaDL - Video" }
$lblHeader.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$lblHeader.ForeColor = [System.Drawing.Color]::FromArgb(0, 184, 148)
$lblHeader.Location = New-Object System.Drawing.Point(16, 10)
$lblHeader.AutoSize = $true
$form.Controls.Add($lblHeader)

# Close button
$btnClose = New-Object System.Windows.Forms.Label
$btnClose.Text = "X"
$btnClose.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnClose.ForeColor = [System.Drawing.Color]::Gray
$btnClose.Location = New-Object System.Drawing.Point(390, 10)
$btnClose.Size = New-Object System.Drawing.Size(20, 20)
$btnClose.Cursor = "Hand"
$btnClose.Add_Click({ $script:cancelled = $true; $form.Close() })
$btnClose.Add_MouseEnter({ $btnClose.ForeColor = [System.Drawing.Color]::Red })
$btnClose.Add_MouseLeave({ $btnClose.ForeColor = [System.Drawing.Color]::Gray })
$form.Controls.Add($btnClose)

# Title label
$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "Fetching video info..."
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblTitle.ForeColor = [System.Drawing.Color]::White
$lblTitle.Location = New-Object System.Drawing.Point(16, 38)
$lblTitle.Size = New-Object System.Drawing.Size(380, 20)
$form.Controls.Add($lblTitle)

# Progress bar background
$pnlProgress = New-Object System.Windows.Forms.Panel
$pnlProgress.Size = New-Object System.Drawing.Size(230, 8)
$pnlProgress.Location = New-Object System.Drawing.Point(16, 68)
$pnlProgress.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
$form.Controls.Add($pnlProgress)

# Progress bar fill
$pnlFill = New-Object System.Windows.Forms.Panel
$pnlFill.Size = New-Object System.Drawing.Size(0, 8)
$pnlFill.BackColor = [System.Drawing.Color]::FromArgb(0, 184, 148)
$pnlProgress.Controls.Add($pnlFill)

# Percentage
$lblPct = New-Object System.Windows.Forms.Label
$lblPct.Text = "0%"
$lblPct.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblPct.ForeColor = [System.Drawing.Color]::White
$lblPct.Location = New-Object System.Drawing.Point(254, 64)
$lblPct.AutoSize = $true
$form.Controls.Add($lblPct)

# Speed
$lblSpeed = New-Object System.Windows.Forms.Label
$lblSpeed.Text = ""
$lblSpeed.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$lblSpeed.ForeColor = [System.Drawing.Color]::Gray
$lblSpeed.Location = New-Object System.Drawing.Point(300, 64)
$lblSpeed.AutoSize = $true
$form.Controls.Add($lblSpeed)

# Status
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Starting..."
$lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblStatus.ForeColor = [System.Drawing.Color]::Gray
$lblStatus.Location = New-Object System.Drawing.Point(16, 90)
$lblStatus.Size = New-Object System.Drawing.Size(280, 20)
$form.Controls.Add($lblStatus)

# ETA
$lblEta = New-Object System.Windows.Forms.Label
$lblEta.Text = ""
$lblEta.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$lblEta.ForeColor = [System.Drawing.Color]::Gray
$lblEta.Location = New-Object System.Drawing.Point(300, 90)
$lblEta.AutoSize = $true
$form.Controls.Add($lblEta)

# System tray icon
$tray = New-Object System.Windows.Forms.NotifyIcon
$tray.Icon = [System.Drawing.SystemIcons]::Application
$tray.Text = "MediaDL Download"
$tray.Visible = $true
$tray.Add_Click({ $form.Show(); $form.Activate() })

$script:step = 0
$script:job = $null
$script:cancelled = $false
$script:retryCount = 0
$script:maxRetries = 3

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 500
$timer.Add_Tick({
    try {
        if ($script:step -eq 0) {
            $lblStatus.Text = "Fetching video info..."
            $script:step = 1
        }
        elseif ($script:step -eq 1) {
            try {
                $prevEncoding = [Console]::OutputEncoding
                [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
                $titleResult = & $config.YtDlpPath --get-title --no-warnings --no-playlist $videoUrl 2>$null
                [Console]::OutputEncoding = $prevEncoding
                if ($titleResult) {
                    $lblTitle.Text = $titleResult.Trim().Substring(0, [Math]::Min(60, $titleResult.Trim().Length))
                    $tray.Text = "DL: " + $titleResult.Substring(0, [Math]::Min(45, $titleResult.Length))
                }
            } catch {}
            $script:step = 2
        }
        elseif ($script:step -eq 2) {
            $lblStatus.Text = "Starting download..."
            $ffLoc = Split-Path $config.FfmpegPath -Parent
            $outTpl = Join-Path $config.DownloadPath "%(title)s.%(ext)s"
            $ytdlp = $config.YtDlpPath
            "" | Set-Content $progressFile -Force
            
            if ($audioOnly) {
                $outTpl = Join-Path $config.DownloadPath "%(title)s.mp3"
                $lblStatus.Text = "Downloading audio..."
                $script:job = Start-Job -ScriptBlock {
                    param($ytdlp, $ffLoc, $outTpl, $vUrl, $outFile)
                    & $ytdlp -f bestaudio --extract-audio --audio-format mp3 --audio-quality 0 --newline --progress --ffmpeg-location $ffLoc -o $outTpl $vUrl 2>&1 | ForEach-Object { $_ | Out-File $outFile -Append -Encoding utf8; $_ }
                } -ArgumentList $ytdlp, $ffLoc, $outTpl, $videoUrl, $progressFile
            } else {
                $lblStatus.Text = "Downloading video..."
                $script:job = Start-Job -ScriptBlock {
                    param($ytdlp, $ffLoc, $outTpl, $vUrl, $outFile)
                    & $ytdlp -f "bestvideo[height<=1080]+bestaudio/best[height<=1080]" --merge-output-format mp4 --newline --progress --ffmpeg-location $ffLoc -o $outTpl $vUrl 2>&1 | ForEach-Object { $_ | Out-File $outFile -Append -Encoding utf8; $_ }
                } -ArgumentList $ytdlp, $ffLoc, $outTpl, $videoUrl, $progressFile
            }
            $script:step = 3
        }
        elseif ($script:step -eq 3) {
            if (Test-Path $progressFile) {
                try {
                    $content = Get-Content $progressFile -Raw -ErrorAction SilentlyContinue
                    if ($content) {
                        $allMatches = [regex]::Matches($content, '\[download\]\s+(\d+\.?\d*)%')
                        if ($allMatches.Count -gt 0) {
                            $lastMatch = $allMatches[$allMatches.Count - 1]
                            $pct = [double]$lastMatch.Groups[1].Value
                            $pnlFill.Width = [int](($pct / 100) * 230)
                            $lblPct.Text = [math]::Round($pct).ToString() + "%"
                        }
                        if ($content -match '(?s).*of\s+~?(\d+\.?\d*\w+)\s+at\s+(\S+)\s+ETA\s+(\S+)') {
                            $lblStatus.Text = "Downloading ($($matches[1]))..."
                            $lblSpeed.Text = $matches[2]
                            $lblEta.Text = "ETA " + $matches[3]
                        }
                        if ($content -match 'already been downloaded') {
                            $lblStatus.Text = "Already downloaded"
                            $pnlFill.Width = 230
                            $lblPct.Text = "100%"
                        }
                        elseif ($content -match '\[Merger\]|Merging formats') {
                            $lblStatus.Text = "Merging audio/video..."
                            $lblSpeed.Text = ""; $lblEta.Text = ""
                        }
                        elseif ($content -match '\[ExtractAudio\]') {
                            $lblStatus.Text = "Extracting audio..."
                        }
                    }
                } catch {}
            }
            
            if ($script:cancelled -and $script:job) {
                Stop-Job -Job $script:job -ErrorAction SilentlyContinue
                Remove-Job -Job $script:job -Force -ErrorAction SilentlyContinue
                $script:step = 4
                return
            }
            
            if ($script:job -and $script:job.State -ne "Running") {
                $script:step = 4
            }
        }
        elseif ($script:step -eq 4) {
            $timer.Stop()
            
            if ($script:job) {
                $jobOutput = Receive-Job -Job $script:job -ErrorAction SilentlyContinue | Out-String
                Remove-Job -Job $script:job -Force -ErrorAction SilentlyContinue
            }
            
            if (Test-Path $progressFile) { Remove-Item $progressFile -Force -ErrorAction SilentlyContinue }
            
            if ($script:cancelled) {
                $lblStatus.Text = "Cancelled"
                $lblStatus.ForeColor = [System.Drawing.Color]::Orange
                $tray.ShowBalloonTip(2000, "MediaDL", "Download cancelled", "Warning")
            } else {
                $progressContent = ""
                if (Test-Path $progressFile) { $progressContent = Get-Content $progressFile -Raw -ErrorAction SilentlyContinue }
                $allOutput = $jobOutput + $progressContent
                
                $success = ($allOutput -match "100%|has already been downloaded|Merging formats into|DelayedMuxer")
                
                if ($success) {
                    $pnlFill.Width = 230
                    $lblPct.Text = "100%"
                    $lblStatus.Text = "Complete!"
                    $lblStatus.ForeColor = [System.Drawing.Color]::LimeGreen
                    $lblSpeed.Text = ""; $lblEta.Text = ""
                    $tray.ShowBalloonTip(3000, "MediaDL", "Download complete!", "Info")
                    $ct = New-Object System.Windows.Forms.Timer
                    $ct.Interval = 4000
                    $ct.Add_Tick({ $ct.Stop(); $form.Close() })
                    $ct.Start()
                } else {
                    $script:retryCount++
                    if ($script:retryCount -lt $script:maxRetries) {
                        $lblStatus.Text = "Retrying ($($script:retryCount)/$($script:maxRetries))..."
                        $lblStatus.ForeColor = [System.Drawing.Color]::Orange
                        $pnlFill.Width = 0
                        $lblPct.Text = "0%"
                        $lblSpeed.Text = ""; $lblEta.Text = ""
                        $script:step = 2
                        $timer.Start()
                    } else {
                        $lblStatus.Text = "Failed after $($script:maxRetries) attempts"
                        $lblStatus.ForeColor = [System.Drawing.Color]::Red
                        $tray.ShowBalloonTip(3000, "MediaDL", "Download failed", "Error")
                    }
                }
            }
        }
    } catch {
        $lblStatus.Text = "Error: $_"
        $lblStatus.ForeColor = [System.Drawing.Color]::Red
    }
})

$form.Add_Shown({ $timer.Start() })

$form.Add_FormClosed({
    $timer.Stop()
    if ($script:job) { 
        Stop-Job -Job $script:job -ErrorAction SilentlyContinue
        Remove-Job -Job $script:job -Force -ErrorAction SilentlyContinue 
    }
    if (Test-Path $progressFile) { Remove-Item $progressFile -Force -ErrorAction SilentlyContinue }
    $slotFile = Join-Path $env:TEMP "mediadl_slot_$($script:mySlot).lock"
    if (Test-Path $slotFile) { Remove-Item $slotFile -Force -ErrorAction SilentlyContinue }
    $tray.Visible = $false
    $tray.Dispose()
})

[System.Windows.Forms.Application]::Run($form)
'@
            $dlHandler | Set-Content (Join-Path $script:InstallPath "ytdl-handler.ps1") -Encoding UTF8
            Update-Log "  [OK] Download handler with progress UI" "#00b894"
            Set-Progress 75
            
            # Register protocol handlers in registry
            Update-Status "Registering URL protocols..."
            
            # ytdl:// protocol
            $ytdlRegPath = "HKCU:\Software\Classes\ytdl"
            New-Item -Path $ytdlRegPath -Force | Out-Null
            Set-ItemProperty -Path $ytdlRegPath -Name "(Default)" -Value "URL:YTDL Protocol"
            Set-ItemProperty -Path $ytdlRegPath -Name "URL Protocol" -Value ""
            New-Item -Path "$ytdlRegPath\shell\open\command" -Force | Out-Null
            $handlerPath = Join-Path $script:InstallPath "ytdl-handler.ps1"
            Set-ItemProperty -Path "$ytdlRegPath\shell\open\command" -Name "(Default)" -Value "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$handlerPath`" `"%1`""
            
            Update-Log "  [OK] Protocols registered" "#00b894"
        }
        Set-Progress 85
        
        # Desktop shortcut
        if ($chkDesktopShortcut.IsChecked) {
            Update-Status "Creating desktop shortcut..."
            $WshShell = New-Object -ComObject WScript.Shell
            $shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\MediaDL Downloads.lnk")
            $shortcut.TargetPath = $dlPath
            $shortcut.Save()
            Update-Log "  [OK] Desktop shortcut created" "#00b894"
        }
        
        Set-Progress 100
        Update-Log "" "#00b894"
        Update-Log "========================================" "#00b894"
        Update-Log "MediaDL installed successfully!" "#00b894"
        Update-Log "========================================" "#00b894"
        Update-Log "" "#aaa"
        Update-Log "Next step: Install the userscript in your browser" "#f39c12"
        Update-Log "Tampermonkey or Violentmonkey required" "#888"
        
        $script:InstallComplete = $true
        $btnInstall.Content = "Install Userscript"
        $btnInstall.IsEnabled = $true
        $btnCancel.Content = "Close"
        
    } catch {
        Update-Log "" "#ff7675"
        Update-Log "[ERROR] $($_.Exception.Message)" "#ff7675"
        [System.Windows.MessageBox]::Show("Installation failed:`n`n$($_.Exception.Message)", "Error", "OK", "Error")
        $btnInstall.IsEnabled = $true
    }
})

$window.ShowDialog() | Out-Null

# Cleanup temp files
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
