# MediaDL-Server.ps1 — Desktop GUI + HTTP API server for MediaDL
# Runs HTTP server on 127.0.0.1:9751 in a background runspace
# WPF GUI with system tray, dashboard, downloads, history, settings
#
# Usage:
#   MediaDL-Server.ps1            — Launch GUI (or restore from tray)
#   MediaDL-Server.ps1 -Background — Start minimized to tray (startup mode)

param([switch]$Background)

$ErrorActionPreference = 'Continue'

# ── Single instance guard ──
$mutexName = 'Global\MediaDL-Server-Mutex'
$mutex = New-Object System.Threading.Mutex($false, $mutexName)
if (-not $mutex.WaitOne(0, $false)) {
    # Already running — try to show existing window via named pipe
    try {
        $pipe = New-Object System.IO.Pipes.NamedPipeClientStream('.', 'MediaDL-Show', [System.IO.Pipes.PipeDirection]::Out)
        $pipe.Connect(500)
        $pipe.WriteByte(1)
        $pipe.Close()
    } catch {}
    exit
}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
if (-not ("MediaDLProcessControl" -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class MediaDLProcessControl {
    [DllImport("ntdll.dll")] private static extern int NtSuspendProcess(IntPtr processHandle);
    [DllImport("ntdll.dll")] private static extern int NtResumeProcess(IntPtr processHandle);
    public static bool Suspend(IntPtr processHandle) { return NtSuspendProcess(processHandle) == 0; }
    public static bool Resume(IntPtr processHandle) { return NtResumeProcess(processHandle) == 0; }
}
"@
}

# ── Paths ──
$script:InstallPath = $PSScriptRoot
$script:ConfigPath = Join-Path $PSScriptRoot "config.json"
$script:HistoryPath = Join-Path $PSScriptRoot "history.json"
$script:ArchivePath = Join-Path $PSScriptRoot "archive.txt"
$script:LogPath = Join-Path $PSScriptRoot "server.log"

# ── Config ──
if (!(Test-Path $script:ConfigPath)) { Write-Host "FATAL: config.json not found"; exit 1 }
$script:Config = Get-Content $script:ConfigPath -Raw | ConvertFrom-Json

$configDefaults = @{
    DownloadPath = "$env:USERPROFILE\Videos\YouTube"
    AudioDownloadPath = ""
    YtDlpPath = (Join-Path $PSScriptRoot "yt-dlp.exe")
    FfmpegPath = (Join-Path $PSScriptRoot "ffmpeg.exe")
    ServerPort = 9751
    ServerToken = ""
    EmbedMetadata = $true
    EmbedThumbnail = $true
    EmbedChapters = $true
    SplitChapters = $false
    PostProcessAudio = $false
    PostProcessMusicBrainz = $false
    MusicFolder = (Join-Path $env:USERPROFILE "Music\MediaDL")
    SitePresets = [ordered]@{
        'youtube.com' = [ordered]@{ format = 'mp4'; quality = '1080'; codec = 'av01' }
        'twitter.com' = [ordered]@{ format = 'mp4'; quality = 'best' }
        'x.com' = [ordered]@{ format = 'mp4'; quality = 'best' }
        'soundcloud.com' = [ordered]@{ format = 'flac'; quality = 'best'; fallbackFormat = 'mp3' }
    }
    EmbedSubs = $false
    SubtitleSrt = $false
    HardwareEncoder = 'none'
    SubLangs = "en"
    SponsorBlock = $false
    SponsorBlockAction = "remove"
    ConcurrentFragments = 4
    BandwidthLimitKbps = 0
    SiteConcurrencyCap = 1
    DownloadArchive = $true
    AutoUpdateYtDlp = $true
    NamedPipeName = 'MediaDL'
    ToastNotifications = $true
    RateLimit = ""
    Proxy = ""
    StartMinimized = $false
    CloseToTray = $true
}
foreach ($key in $configDefaults.Keys) {
    if (-not ($script:Config.PSObject.Properties.Name -contains $key)) {
        $script:Config | Add-Member -NotePropertyName $key -NotePropertyValue $configDefaults[$key] -Force
    }
}
if (-not $script:Config.ServerToken) {
    $script:Config.ServerToken = [guid]::NewGuid().ToString('N')
}
$script:Config | ConvertTo-Json -Depth 5 | Set-Content $script:ConfigPath -Encoding UTF8

function Save-Config {
    $script:Config | ConvertTo-Json -Depth 5 | Set-Content $script:ConfigPath -Encoding UTF8
}

# ── Logging ──
function Write-Log {
    param([string]$msg)
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $msg"
    try { $line | Out-File $script:LogPath -Append -Encoding utf8 -ErrorAction SilentlyContinue } catch {}
}
if ((Test-Path $script:LogPath) -and (Get-Item $script:LogPath -ErrorAction SilentlyContinue).Length -gt 1MB) {
    try { (Get-Content $script:LogPath -Tail 200) | Set-Content $script:LogPath -Encoding utf8 } catch {}
}

# ── History ──
if (!(Test-Path $script:HistoryPath)) { "[]" | Set-Content $script:HistoryPath -Encoding UTF8 }

# ── Server State (shared with runspace) ──
$script:ServerState = [hashtable]::Synchronized(@{
    Running = $false
    Downloads = [hashtable]::Synchronized(@{})
    NextId = 0
    TotalCompleted = 0
    TotalBytes = 0
    StartTime = $null
    ShouldStop = $false
    Port = $script:Config.ServerPort
    Token = $script:Config.ServerToken
    Config = $script:Config
    ConfigPath = $script:ConfigPath
    HistoryPath = $script:HistoryPath
    ArchivePath = $script:ArchivePath
    LogPath = $script:LogPath
    InstallPath = $script:InstallPath
})

# ══════════════════════════════════════════════════════════════
# WPF XAML
# ══════════════════════════════════════════════════════════════

$xamlString = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="MediaDL Server" Width="780" Height="560" MinWidth="640" MinHeight="480"
        WindowStartupLocation="CenterScreen" Background="#0a0e14"
        ResizeMode="CanResize">
    <Window.Resources>
        <SolidColorBrush x:Key="BgBase" Color="#0a0e14"/>
        <SolidColorBrush x:Key="BgSidebar" Color="#0d1117"/>
        <SolidColorBrush x:Key="BgCard" Color="#151b23"/>
        <SolidColorBrush x:Key="BgInput" Color="#1a2028"/>
        <SolidColorBrush x:Key="Border" Color="#2a3140"/>
        <SolidColorBrush x:Key="TextPrimary" Color="#e6edf3"/>
        <SolidColorBrush x:Key="TextSecondary" Color="#8b949e"/>
        <SolidColorBrush x:Key="TextMuted" Color="#525a65"/>
        <SolidColorBrush x:Key="AccentGreen" Color="#22c55e"/>
        <SolidColorBrush x:Key="AccentOrange" Color="#f97316"/>
        <SolidColorBrush x:Key="AccentRed" Color="#ef4444"/>
        <SolidColorBrush x:Key="AccentBlue" Color="#3b82f6"/>

        <Style x:Key="NavBtn" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="{StaticResource TextSecondary}"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="16,10"/>
            <Setter Property="HorizontalContentAlignment" Value="Left"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}" CornerRadius="8" Padding="{TemplateBinding Padding}" Margin="4,1">
                            <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="#1a2028"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="ActionBtn" TargetType="Button">
            <Setter Property="Background" Value="{StaticResource AccentGreen}"/>
            <Setter Property="Foreground" Value="#0a0a0a"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="18,9"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}" CornerRadius="8" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="#16a34a"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="bd" Property="Opacity" Value="0.5"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="SecBtn" TargetType="Button">
            <Setter Property="Background" Value="#1a2028"/>
            <Setter Property="Foreground" Value="{StaticResource TextSecondary}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="{StaticResource Border}"/>
            <Setter Property="Padding" Value="14,8"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="8" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="#222a35"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="TextBox">
            <Setter Property="Background" Value="{StaticResource BgInput}"/>
            <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
            <Setter Property="BorderBrush" Value="{StaticResource Border}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="8,6"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="CaretBrush" Value="{StaticResource TextPrimary}"/>
        </Style>

        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="{StaticResource TextSecondary}"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Margin" Value="0,4"/>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="180"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <!-- Sidebar -->
        <Border Grid.Column="0" Background="{StaticResource BgSidebar}" BorderBrush="{StaticResource Border}" BorderThickness="0,0,1,0">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <!-- Logo -->
                <StackPanel Grid.Row="0" Margin="16,20,16,24">
                    <TextBlock Text="MediaDL" FontSize="18" FontWeight="Bold" Foreground="{StaticResource TextPrimary}"/>
                    <TextBlock x:Name="lblVersion" Text="Server v5.0.0" FontSize="10" Foreground="{StaticResource TextMuted}" Margin="0,2,0,0"/>
                </StackPanel>

                <!-- Nav -->
                <StackPanel Grid.Row="1">
                    <Button x:Name="navDashboard" Content="Dashboard" Style="{StaticResource NavBtn}"/>
                    <Button x:Name="navDownloads" Content="Downloads" Style="{StaticResource NavBtn}"/>
                    <Button x:Name="navHistory" Content="History" Style="{StaticResource NavBtn}"/>
                    <Button x:Name="navSettings" Content="Settings" Style="{StaticResource NavBtn}"/>
                </StackPanel>

                <!-- Status dot -->
                <StackPanel Grid.Row="2" Orientation="Horizontal" Margin="16,0,16,16">
                    <Ellipse x:Name="statusDot" Width="8" Height="8" Fill="#525a65" Margin="0,0,8,0"/>
                    <TextBlock x:Name="statusLabel" Text="Stopped" FontSize="11" Foreground="{StaticResource TextMuted}"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- Content area -->
        <TabControl x:Name="tabContent" Grid.Column="1" BorderThickness="0" Background="Transparent" Padding="0">
            <TabControl.ItemContainerStyle>
                <Style TargetType="TabItem"><Setter Property="Visibility" Value="Collapsed"/></Style>
            </TabControl.ItemContainerStyle>

            <!-- Dashboard -->
            <TabItem>
                <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="24,20">
                    <StackPanel>
                        <TextBlock Text="Dashboard" FontSize="22" FontWeight="Bold" Foreground="{StaticResource TextPrimary}" Margin="0,0,0,20"/>

                        <!-- Server control card -->
                        <Border Background="{StaticResource BgCard}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="12" Padding="20" Margin="0,0,0,16">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <TextBlock x:Name="dashStatus" Text="Server Stopped" FontSize="16" FontWeight="SemiBold" Foreground="{StaticResource TextPrimary}"/>
                                    <TextBlock x:Name="dashEndpoint" Text="http://127.0.0.1:9751" FontSize="11" Foreground="{StaticResource TextMuted}" Margin="0,4,0,0"/>
                                </StackPanel>
                                <StackPanel Grid.Column="1" Orientation="Horizontal">
                                    <Button x:Name="btnStartStop" Content="Start Server" Style="{StaticResource ActionBtn}" Margin="0,0,8,0"/>
                                    <Button x:Name="btnOpenFolder" Content="Open Folder" Style="{StaticResource SecBtn}"/>
                                </StackPanel>
                            </Grid>
                        </Border>

                        <!-- Stats row -->
                        <Grid Margin="0,0,0,16">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="12"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="12"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="12"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <Border Grid.Column="0" Background="{StaticResource BgCard}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="10" Padding="16,12">
                                <StackPanel><TextBlock Text="Active" FontSize="10" Foreground="{StaticResource TextMuted}" FontWeight="SemiBold" TextAlignment="Center"/>
                                <TextBlock x:Name="statActive" Text="0" FontSize="24" FontWeight="Bold" Foreground="{StaticResource AccentGreen}" TextAlignment="Center"/></StackPanel>
                            </Border>
                            <Border Grid.Column="2" Background="{StaticResource BgCard}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="10" Padding="16,12">
                                <StackPanel><TextBlock Text="Completed" FontSize="10" Foreground="{StaticResource TextMuted}" FontWeight="SemiBold" TextAlignment="Center"/>
                                <TextBlock x:Name="statCompleted" Text="0" FontSize="24" FontWeight="Bold" Foreground="{StaticResource TextPrimary}" TextAlignment="Center"/></StackPanel>
                            </Border>
                            <Border Grid.Column="4" Background="{StaticResource BgCard}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="10" Padding="16,12">
                                <StackPanel><TextBlock Text="Uptime" FontSize="10" Foreground="{StaticResource TextMuted}" FontWeight="SemiBold" TextAlignment="Center"/>
                                <TextBlock x:Name="statUptime" Text="--" FontSize="24" FontWeight="Bold" Foreground="{StaticResource TextPrimary}" TextAlignment="Center"/></StackPanel>
                            </Border>
                            <Border Grid.Column="6" Background="{StaticResource BgCard}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="10" Padding="16,12">
                                <StackPanel><TextBlock Text="Port" FontSize="10" Foreground="{StaticResource TextMuted}" FontWeight="SemiBold" TextAlignment="Center"/>
                                <TextBlock x:Name="statPort" Text="9751" FontSize="24" FontWeight="Bold" Foreground="{StaticResource TextPrimary}" TextAlignment="Center"/></StackPanel>
                            </Border>
                        </Grid>

                        <!-- Log -->
                        <TextBlock Text="Server Log" FontSize="12" Foreground="{StaticResource TextMuted}" FontWeight="SemiBold" Margin="0,0,0,6"/>
                        <Border Background="{StaticResource BgCard}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="10" Padding="12" MaxHeight="200">
                            <ScrollViewer x:Name="logScroll" VerticalScrollBarVisibility="Auto">
                                <TextBlock x:Name="logText" Text="Ready." Foreground="{StaticResource TextMuted}" FontFamily="Cascadia Code, Consolas" FontSize="11" TextWrapping="Wrap"/>
                            </ScrollViewer>
                        </Border>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>

            <!-- Downloads -->
            <TabItem>
                <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="24,20">
                    <StackPanel>
                        <TextBlock Text="Active Downloads" FontSize="22" FontWeight="Bold" Foreground="{StaticResource TextPrimary}" Margin="0,0,0,16"/>
                        <StackPanel x:Name="downloadsList">
                            <TextBlock x:Name="noDownloads" Text="No active downloads." FontSize="13" Foreground="{StaticResource TextMuted}"/>
                        </StackPanel>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>

            <!-- History -->
            <TabItem>
                <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="24,20">
                    <StackPanel>
                        <Grid Margin="0,0,0,16">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <TextBlock Text="Download History" FontSize="22" FontWeight="Bold" Foreground="{StaticResource TextPrimary}"/>
                            <Button x:Name="btnClearHistory" Content="Clear History" Style="{StaticResource SecBtn}" Grid.Column="1"/>
                        </Grid>
                        <StackPanel x:Name="historyList">
                            <TextBlock x:Name="noHistory" Text="No downloads yet." FontSize="13" Foreground="{StaticResource TextMuted}"/>
                        </StackPanel>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>

            <!-- Settings -->
            <TabItem>
                <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="24,20">
                    <StackPanel MaxWidth="560">
                        <TextBlock Text="Settings" FontSize="22" FontWeight="Bold" Foreground="{StaticResource TextPrimary}" Margin="0,0,0,20"/>

                        <!-- Paths -->
                        <TextBlock Text="PATHS" FontSize="10" FontWeight="Bold" Foreground="{StaticResource TextMuted}" Margin="0,0,0,8" LetterSpacing="0.5"/>
                        <Border Background="{StaticResource BgCard}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="10" Padding="16" Margin="0,0,0,16">
                            <StackPanel>
                                <TextBlock Text="Video Download Folder" FontSize="11" Foreground="{StaticResource TextSecondary}" Margin="0,0,0,4"/>
                                <Grid Margin="0,0,0,12"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                                    <TextBox x:Name="cfgDownloadPath" Grid.Column="0"/>
                                    <Button x:Name="btnBrowseDl" Content="..." Style="{StaticResource SecBtn}" Grid.Column="1" Margin="6,0,0,0" Padding="10,6" Width="36"/>
                                </Grid>
                                <TextBlock Text="Audio Download Folder (blank = same as video)" FontSize="11" Foreground="{StaticResource TextSecondary}" Margin="0,0,0,4"/>
                                <Grid Margin="0,0,0,0"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                                    <TextBox x:Name="cfgAudioPath" Grid.Column="0"/>
                                    <Button x:Name="btnBrowseAudio" Content="..." Style="{StaticResource SecBtn}" Grid.Column="1" Margin="6,0,0,0" Padding="10,6" Width="36"/>
                                </Grid>
                            </StackPanel>
                        </Border>

                        <!-- Embedding -->
                        <TextBlock Text="POST-PROCESSING" FontSize="10" FontWeight="Bold" Foreground="{StaticResource TextMuted}" Margin="0,0,0,8"/>
                        <Border Background="{StaticResource BgCard}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="10" Padding="16" Margin="0,0,0,16">
                            <StackPanel>
                                 <CheckBox x:Name="cfgEmbedMetadata" Content="Embed metadata (title, artist, date)"/>
                                 <CheckBox x:Name="cfgEmbedThumbnail" Content="Embed thumbnail as cover art"/>
                                 <CheckBox x:Name="cfgEmbedChapters" Content="Embed chapter markers"/>
                                 <CheckBox x:Name="cfgSplitChapters" Content="Split YouTube chapters into separate files"/>
                                 <CheckBox x:Name="cfgPostProcessAudio" Content="Extract audio to Music folder after video downloads"/>
                                 <CheckBox x:Name="cfgPostProcessMusicBrainz" Content="Tag extracted audio with MusicBrainz metadata"/>
                                <StackPanel Orientation="Horizontal" Margin="20,4,0,0">
                                    <TextBlock Text="Music folder:" FontSize="11" Foreground="{StaticResource TextMuted}" VerticalAlignment="Center" Margin="0,0,6,0"/>
                                    <TextBox x:Name="cfgMusicFolder" Width="260" FontSize="11"/>
                                </StackPanel>
                                <TextBlock Text="SITE FORMAT PRESETS (JSON)" FontSize="10" FontWeight="Bold" Foreground="{StaticResource TextMuted}" Margin="0,12,0,4"/>
                                <TextBox x:Name="cfgSitePresets" Height="72" AcceptsReturn="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" FontSize="10"/>
                                <TextBlock Text="Host keys support format, quality, codec (av01/vp9/h264/hevc), and fallbackFormat." FontSize="10" Foreground="{StaticResource TextMuted}" TextWrapping="Wrap" Margin="0,4,0,0"/>
                                 <CheckBox x:Name="cfgEmbedSubs" Content="Embed subtitles"/>
                                 <CheckBox x:Name="cfgSubtitleSrt" Content="Download subtitles as SRT and mux into MKV"/>
                                <StackPanel Orientation="Horizontal" Margin="0,4,0,0">
                                    <TextBlock Text="Hardware transcode:" FontSize="11" Foreground="{StaticResource TextMuted}" VerticalAlignment="Center" Margin="0,0,6,0"/>
                                    <ComboBox x:Name="cfgHardwareEncoder" Width="110" FontSize="11">
                                        <ComboBoxItem Content="None"/>
                                        <ComboBoxItem Content="NVENC"/>
                                        <ComboBoxItem Content="QSV"/>
                                    </ComboBox>
                                </StackPanel>
                                 <StackPanel Orientation="Horizontal" Margin="20,4,0,0">
                                    <TextBlock Text="Languages:" FontSize="11" Foreground="{StaticResource TextMuted}" VerticalAlignment="Center" Margin="0,0,6,0"/>
                                    <TextBox x:Name="cfgSubLangs" Width="120" FontSize="11"/>
                                </StackPanel>
                                <CheckBox x:Name="cfgSponsorBlock" Content="SponsorBlock (remove sponsored segments)"/>
                            </StackPanel>
                        </Border>

                        <!-- Performance -->
                        <TextBlock Text="PERFORMANCE" FontSize="10" FontWeight="Bold" Foreground="{StaticResource TextMuted}" Margin="0,0,0,8"/>
                        <Border Background="{StaticResource BgCard}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="10" Padding="16" Margin="0,0,0,16">
                            <StackPanel>
                                <StackPanel Orientation="Horizontal" Margin="0,0,0,8">
                                    <TextBlock Text="Concurrent fragments:" FontSize="12" Foreground="{StaticResource TextSecondary}" VerticalAlignment="Center" Margin="0,0,8,0"/>
                                    <TextBox x:Name="cfgFragments" Width="50" FontSize="12"/>
                                </StackPanel>
                                 <StackPanel Orientation="Horizontal" Margin="0,0,0,8">
                                     <TextBlock Text="Rate limit (e.g. 500K, 2M, blank=unlimited):" FontSize="12" Foreground="{StaticResource TextSecondary}" VerticalAlignment="Center" Margin="0,0,8,0"/>
                                     <TextBox x:Name="cfgRateLimit" Width="80" FontSize="12"/>
                                 </StackPanel>
                                 <StackPanel Orientation="Horizontal" Margin="0,0,0,8">
                                     <TextBlock Text="Bandwidth slider (Kbps, 0=unlimited):" FontSize="12" Foreground="{StaticResource TextSecondary}" VerticalAlignment="Center" Margin="0,0,8,0"/>
                                     <Slider x:Name="cfgBandwidth" Width="180" Minimum="0" Maximum="10000" TickFrequency="500" IsSnapToTickEnabled="True"/>
                                 </StackPanel>
                                 <StackPanel Orientation="Horizontal" Margin="0,0,0,8">
                                     <TextBlock Text="Per-site concurrency:" FontSize="12" Foreground="{StaticResource TextSecondary}" VerticalAlignment="Center" Margin="0,0,8,0"/>
                                     <Slider x:Name="cfgSiteConcurrency" Width="180" Minimum="1" Maximum="8" TickFrequency="1" IsSnapToTickEnabled="True"/>
                                 </StackPanel>
                                <StackPanel Orientation="Horizontal" Margin="0,0,0,0">
                                    <TextBlock Text="Proxy (e.g. socks5://host:port, blank=none):" FontSize="12" Foreground="{StaticResource TextSecondary}" VerticalAlignment="Center" Margin="0,0,8,0"/>
                                    <TextBox x:Name="cfgProxy" Width="200" FontSize="12"/>
                                </StackPanel>
                            </StackPanel>
                        </Border>

                        <!-- Behavior -->
                        <TextBlock Text="BEHAVIOR" FontSize="10" FontWeight="Bold" Foreground="{StaticResource TextMuted}" Margin="0,0,0,8"/>
                        <Border Background="{StaticResource BgCard}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="10" Padding="16" Margin="0,0,0,16">
                            <StackPanel>
                                <CheckBox x:Name="cfgAutoUpdate" Content="Auto-update yt-dlp on server start"/>
                                <CheckBox x:Name="cfgToastNotifications" Content="Show Windows toast on completion"/>
                                <CheckBox x:Name="cfgArchive" Content="Skip already-downloaded videos (archive.txt)"/>
                                <CheckBox x:Name="cfgCloseToTray" Content="Close to system tray instead of quitting"/>
                                <CheckBox x:Name="cfgStartMinimized" Content="Start minimized to tray"/>
                            </StackPanel>
                        </Border>

                        <Button x:Name="btnSaveSettings" Content="Save Settings" Style="{StaticResource ActionBtn}" HorizontalAlignment="Left" Margin="0,0,0,24"/>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>
        </TabControl>
    </Grid>
</Window>
"@

# ══════════════════════════════════════════════════════════════
# LOAD WINDOW
# ══════════════════════════════════════════════════════════════
$xaml = [xml]$xamlString
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# ── Controls ──
$tabContent = $window.FindName("tabContent")
$navDashboard = $window.FindName("navDashboard")
$navDownloads = $window.FindName("navDownloads")
$navHistory = $window.FindName("navHistory")
$navSettings = $window.FindName("navSettings")
$statusDot = $window.FindName("statusDot")
$statusLabel = $window.FindName("statusLabel")

$dashStatus = $window.FindName("dashStatus")
$dashEndpoint = $window.FindName("dashEndpoint")
$btnStartStop = $window.FindName("btnStartStop")
$btnOpenFolder = $window.FindName("btnOpenFolder")
$statActive = $window.FindName("statActive")
$statCompleted = $window.FindName("statCompleted")
$statUptime = $window.FindName("statUptime")
$statPort = $window.FindName("statPort")
$logText = $window.FindName("logText")
$logScroll = $window.FindName("logScroll")

$downloadsList = $window.FindName("downloadsList")
$noDownloads = $window.FindName("noDownloads")
$historyList = $window.FindName("historyList")
$noHistory = $window.FindName("noHistory")
$btnClearHistory = $window.FindName("btnClearHistory")

# Settings controls
$cfgDownloadPath = $window.FindName("cfgDownloadPath")
$cfgAudioPath = $window.FindName("cfgAudioPath")
$btnBrowseDl = $window.FindName("btnBrowseDl")
$btnBrowseAudio = $window.FindName("btnBrowseAudio")
$cfgEmbedMetadata = $window.FindName("cfgEmbedMetadata")
$cfgEmbedThumbnail = $window.FindName("cfgEmbedThumbnail")
$cfgEmbedChapters = $window.FindName("cfgEmbedChapters")
$cfgSplitChapters = $window.FindName("cfgSplitChapters")
$cfgPostProcessAudio = $window.FindName("cfgPostProcessAudio")
$cfgPostProcessMusicBrainz = $window.FindName("cfgPostProcessMusicBrainz")
$cfgMusicFolder = $window.FindName("cfgMusicFolder")
$cfgSitePresets = $window.FindName("cfgSitePresets")
$cfgEmbedSubs = $window.FindName("cfgEmbedSubs")
$cfgSubtitleSrt = $window.FindName("cfgSubtitleSrt")
$cfgHardwareEncoder = $window.FindName("cfgHardwareEncoder")
$cfgSubLangs = $window.FindName("cfgSubLangs")
$cfgSponsorBlock = $window.FindName("cfgSponsorBlock")
$cfgFragments = $window.FindName("cfgFragments")
$cfgRateLimit = $window.FindName("cfgRateLimit")
$cfgBandwidth = $window.FindName("cfgBandwidth")
$cfgSiteConcurrency = $window.FindName("cfgSiteConcurrency")
$cfgProxy = $window.FindName("cfgProxy")
$cfgAutoUpdate = $window.FindName("cfgAutoUpdate")
$cfgToastNotifications = $window.FindName("cfgToastNotifications")
$cfgArchive = $window.FindName("cfgArchive")
$cfgCloseToTray = $window.FindName("cfgCloseToTray")
$cfgStartMinimized = $window.FindName("cfgStartMinimized")
$btnSaveSettings = $window.FindName("btnSaveSettings")

$statPort.Text = "$($script:Config.ServerPort)"
$dashEndpoint.Text = "http://127.0.0.1:$($script:Config.ServerPort)"

# ── Load settings into UI ──
function Load-SettingsUI {
    $c = $script:Config
    $cfgDownloadPath.Text = "$($c.DownloadPath)"
    $cfgAudioPath.Text = "$($c.AudioDownloadPath)"
    $cfgEmbedMetadata.IsChecked = $c.EmbedMetadata -eq $true
    $cfgEmbedThumbnail.IsChecked = $c.EmbedThumbnail -eq $true
    $cfgEmbedChapters.IsChecked = $c.EmbedChapters -eq $true
    $cfgSplitChapters.IsChecked = $c.SplitChapters -eq $true
    $cfgPostProcessAudio.IsChecked = $c.PostProcessAudio -eq $true
    $cfgPostProcessMusicBrainz.IsChecked = $c.PostProcessMusicBrainz -eq $true
    $cfgMusicFolder.Text = "$($c.MusicFolder)"
    $cfgSitePresets.Text = if ($c.SitePresets) { $c.SitePresets | ConvertTo-Json -Compress } else { '{}' }
    $cfgEmbedSubs.IsChecked = $c.EmbedSubs -eq $true
    $cfgSubtitleSrt.IsChecked = $c.SubtitleSrt -eq $true
    $cfgHardwareEncoder.SelectedIndex = switch (("$($c.HardwareEncoder)").ToLowerInvariant()) { 'nvenc' { 1 } 'qsv' { 2 } default { 0 } }
    $cfgSubLangs.Text = "$($c.SubLangs)"
    $cfgSponsorBlock.IsChecked = $c.SponsorBlock -eq $true
    $cfgFragments.Text = "$($c.ConcurrentFragments)"
    $cfgRateLimit.Text = "$($c.RateLimit)"
    $cfgBandwidth.Value = [double]$c.BandwidthLimitKbps
    $cfgSiteConcurrency.Value = [double]$c.SiteConcurrencyCap
    $cfgProxy.Text = "$($c.Proxy)"
    $cfgAutoUpdate.IsChecked = $c.AutoUpdateYtDlp -eq $true
    $cfgToastNotifications.IsChecked = $c.ToastNotifications -ne $false
    $cfgArchive.IsChecked = $c.DownloadArchive -eq $true
    $cfgCloseToTray.IsChecked = $c.CloseToTray -eq $true
    $cfgStartMinimized.IsChecked = $c.StartMinimized -eq $true
}
Load-SettingsUI

# ── Nav active state ──
$script:ActiveNav = $null
function Set-ActiveNav($btn, $index) {
    if ($script:ActiveNav) {
        $script:ActiveNav.Foreground = [System.Windows.Media.Brushes]::Gray
        $script:ActiveNav.FontWeight = "SemiBold"
    }
    $btn.Foreground = [Windows.Media.BrushConverter]::new().ConvertFromString("#22c55e")
    $btn.FontWeight = "Bold"
    $script:ActiveNav = $btn
    $tabContent.SelectedIndex = $index
}
$navDashboard.Add_Click({ Set-ActiveNav $navDashboard 0 })
$navDownloads.Add_Click({ Set-ActiveNav $navDownloads 1 })
$navHistory.Add_Click({ Set-ActiveNav $navHistory 2; Refresh-History })
$navSettings.Add_Click({ Set-ActiveNav $navSettings 3 })
Set-ActiveNav $navDashboard 0

# ══════════════════════════════════════════════════════════════
# SYSTEM TRAY
# ══════════════════════════════════════════════════════════════
$trayIcon = New-Object System.Windows.Forms.NotifyIcon
$trayIcon.Text = "MediaDL Server"
$trayIcon.Visible = $true

# Use a green circle icon (generated in memory)
$bmp = New-Object System.Drawing.Bitmap(16,16)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::Transparent)
$g.FillEllipse([System.Drawing.Brushes]::LimeGreen, 2, 2, 12, 12)
$g.Dispose()
$trayIcon.Icon = [System.Drawing.Icon]::FromHandle($bmp.GetHicon())

# Tray context menu
$trayMenu = New-Object System.Windows.Forms.ContextMenuStrip
$trayShow = $trayMenu.Items.Add("Show MediaDL")
$trayStartStop = $trayMenu.Items.Add("Start Server")
$trayMenu.Items.Add("-")
$trayExit = $trayMenu.Items.Add("Exit")
$trayIcon.ContextMenuStrip = $trayMenu

$trayIcon.Add_DoubleClick({
    $window.Show()
    $window.WindowState = [System.Windows.WindowState]::Normal
    $window.Activate()
})
$trayShow.Add_Click({
    $window.Show()
    $window.WindowState = [System.Windows.WindowState]::Normal
    $window.Activate()
})
$trayExit.Add_Click({
    $script:ForceExit = $true
    $window.Close()
})

# ── Window minimize/close behavior ──
$script:ForceExit = $false

$window.Add_StateChanged({
    if ($window.WindowState -eq [System.Windows.WindowState]::Minimized) {
        $window.Hide()
    }
})

$window.Add_Closing({
    param($s, $e)
    if (-not $script:ForceExit -and $script:Config.CloseToTray -eq $true) {
        $e.Cancel = $true
        $window.Hide()
    }
})

# ══════════════════════════════════════════════════════════════
# HTTP SERVER (background runspace)
# ══════════════════════════════════════════════════════════════
$script:ServerRunspace = $null
$script:ServerPipeline = $null

function Start-Server {
    if ($script:ServerState.Running) { return }

    # Reload config into shared state
    $script:ServerState.Config = $script:Config
    $script:ServerState.ShouldStop = $false
    $script:ServerState.StartTime = Get-Date

    $rs = [runspacefactory]::CreateRunspace()
    $rs.ApartmentState = "MTA"
    $rs.Open()
    $rs.SessionStateProxy.SetVariable('state', $script:ServerState)

    $ps = [powershell]::Create()
    $ps.Runspace = $rs
    $ps.AddScript({
        $ErrorActionPreference = 'Continue'
        $PORT = $state.Port
        $MAX_CONCURRENT = 3
        $config = $state.Config
        $SITE_CONCURRENCY_CAP = [int]$config.SiteConcurrencyCap
        if ($SITE_CONCURRENCY_CAP -lt 1 -or $SITE_CONCURRENCY_CAP -gt 8) { $SITE_CONCURRENCY_CAP = 1 }

        function Write-SLog { param([string]$msg); $state.Log += "$(Get-Date -Format 'HH:mm:ss') $msg`n" }

        $queueDbPath = Join-Path (Join-Path $env:LOCALAPPDATA 'MediaDL') 'queue.db'
        $sqlitePath = $null
        $sqliteCommand = Get-Command sqlite3.exe -ErrorAction SilentlyContinue
        if ($sqliteCommand) { $sqlitePath = $sqliteCommand.Source }
        elseif (Test-Path (Join-Path $state.InstallPath 'sqlite3.exe')) {
            $sqlitePath = Join-Path $state.InstallPath 'sqlite3.exe'
        }
        if ($sqlitePath) {
            try { New-Item -ItemType Directory -Path (Split-Path $queueDbPath) -Force | Out-Null } catch {}
        }

        function ConvertTo-SqliteLiteral {
            param($Value)
            if ($null -eq $Value) { return 'NULL' }
            return "'" + ([string]$Value).Replace("'", "''") + "'"
        }

        function Invoke-QueueSql {
            param([string]$Sql, [switch]$Json)
            if (-not $sqlitePath) { return $null }
            try {
                if ($Json) { return ((& $sqlitePath -batch -json $queueDbPath $Sql 2>$null | Out-String).Trim()) }
                & $sqlitePath -batch $queueDbPath $Sql 2>$null | Out-Null
            } catch { Write-SLog "SQLite error: $($_.Exception.Message)" }
        }

        function Initialize-QueueDb {
            if (-not $sqlitePath) {
                Write-SLog "SQLite CLI unavailable; persistent queue disabled"
                return
            }
            Invoke-QueueSql @"
PRAGMA journal_mode=WAL;
CREATE TABLE IF NOT EXISTS downloads (
    id TEXT PRIMARY KEY,
    url TEXT NOT NULL,
    title TEXT,
    audio_only INTEGER NOT NULL DEFAULT 0,
    referer TEXT,
    format TEXT,
    quality TEXT,
    output_dir TEXT,
    status TEXT NOT NULL,
    progress REAL NOT NULL DEFAULT 0,
    speed TEXT,
    eta TEXT,
    filename TEXT,
    priority INTEGER NOT NULL DEFAULT 0,
    content_key TEXT,
    video_id TEXT,
    channel_id TEXT,
    source_url TEXT,
    split_chapters INTEGER NOT NULL DEFAULT 0,
    record_from_now INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_downloads_status_created ON downloads(status, created_at);
"@
            $columns = Invoke-QueueSql "PRAGMA table_info(downloads);" -Json
            foreach ($column in @('priority','content_key','video_id','channel_id','source_url')) {
                if ($columns -and $columns -notmatch ('"name":"' + $column + '"')) {
                    $definition = if ($column -eq 'priority') { 'INTEGER NOT NULL DEFAULT 0' } else { 'TEXT' }
                    Invoke-QueueSql "ALTER TABLE downloads ADD COLUMN $column $definition;"
                }
            }
        }

        function Save-QueueRecord {
            param($Download)
            if (-not $sqlitePath -or -not $Download) { return }
            $now = (Get-Date).ToUniversalTime().ToString('o')
            $created = if ($Download.startTime) { ([datetime]$Download.startTime).ToUniversalTime().ToString('o') } else { $now }
            $sql = @"
INSERT OR REPLACE INTO downloads
 (id,url,title,audio_only,referer,format,quality,output_dir,status,progress,speed,eta,filename,priority,content_key,video_id,channel_id,source_url,split_chapters,record_from_now,created_at,updated_at)
VALUES (
 $(ConvertTo-SqliteLiteral $Download.id),
 $(ConvertTo-SqliteLiteral $Download.url),
 $(ConvertTo-SqliteLiteral $Download.title),
 $(if ($Download.audioOnly) { 1 } else { 0 }),
 $(ConvertTo-SqliteLiteral $Download.referer),
 $(ConvertTo-SqliteLiteral $Download.format),
 $(ConvertTo-SqliteLiteral $Download.quality),
 $(ConvertTo-SqliteLiteral $Download.outputDir),
 $(ConvertTo-SqliteLiteral $Download.status),
 $([double]$Download.progress),
 $(ConvertTo-SqliteLiteral $Download.speed),
 $(ConvertTo-SqliteLiteral $Download.eta),
 $(ConvertTo-SqliteLiteral $Download.filename),
 $([int]$Download.priority),
 $(ConvertTo-SqliteLiteral $Download.contentKey),
 $(ConvertTo-SqliteLiteral $Download.videoId),
 $(ConvertTo-SqliteLiteral $Download.channelId),
 $(ConvertTo-SqliteLiteral $Download.sourceUrl),
 $(if ($Download.splitChapters) { 1 } else { 0 }),
 $(if ($Download.recordFromNow) { 1 } else { 0 }),
 $(ConvertTo-SqliteLiteral $created),
 $(ConvertTo-SqliteLiteral $now)
);
"@
            Invoke-QueueSql $sql
        }

        function Restore-QueueEntries {
            if (-not $sqlitePath) { return }
            $json = Invoke-QueueSql "SELECT id,url,title,audio_only,referer,format,quality,output_dir,status,progress,speed,eta,filename,priority,content_key,video_id,channel_id,source_url,split_chapters,record_from_now,created_at FROM downloads WHERE status NOT IN ('complete','failed','cancelled') ORDER BY priority,created_at;" -Json
            if (-not $json) { return }
            try { $rows = @($json | ConvertFrom-Json) } catch { return }
            foreach ($row in $rows) {
                $start = Get-Date
                try { $start = [datetime]::Parse("$($row.created_at)").ToLocalTime() } catch {}
                $state.Downloads["$($row.id)"] = [hashtable]::Synchronized(@{
                    id="$($row.id)"; url="$($row.url)"; title="$($row.title)"
                    audioOnly=([int]$row.audio_only -eq 1); status="interrupted"
                    progress=[double]$row.progress; speed="$($row.speed)"; eta="$($row.eta)"
                    process=$null; progressFile=""; startTime=$start; filename="$($row.filename)"
                    format="$($row.format)"; quality="$($row.quality)"; priority=[int]$row.priority
                    contentKey="$($row.content_key)"; videoId="$($row.video_id)"; channelId="$($row.channel_id)"; sourceUrl="$($row.source_url)"
                    splitChapters=([int]$row.split_chapters -eq 1); recordFromNow=([int]$row.record_from_now -eq 1)
                    referer="$($row.referer)"; outputDir="$($row.output_dir)"
                })
            }
            if ($rows.Count -gt 0) { Write-SLog "Restored $($rows.Count) interrupted queue item(s) from SQLite" }
        }

        function Get-SiteKey {
            param([string]$Url)
            try { return ([uri]$Url).Host.ToLowerInvariant() } catch { return 'unknown' }
        }

        function Get-SiteFormatPreset {
            param([string]$Site)
            if (-not $config.SitePresets -or -not $Site) { return $null }
            $siteKey = ("$Site").Trim().ToLowerInvariant() -replace '^www\.', ''
            $properties = if ($config.SitePresets -is [System.Collections.IDictionary]) {
                @($config.SitePresets.GetEnumerator() | ForEach-Object { [pscustomobject]@{ Name = "$($_.Key)"; Value = $_.Value } })
            } else {
                @($config.SitePresets.PSObject.Properties | ForEach-Object { [pscustomobject]@{ Name = $_.Name; Value = $_.Value } })
            }
            foreach ($property in $properties) {
                $presetKey = ("$($property.Name)").Trim().ToLowerInvariant() -replace '^www\.', ''
                if ($siteKey -eq $presetKey -or $siteKey.EndsWith(".$presetKey")) { return $property.Value }
            }
            return $null
        }

        function Normalize-IdentityPart {
            param([string]$Value)
            $clean = "$Value".Trim().ToLowerInvariant()
            if (-not $clean) { return 'unknown' }
            $clean = $clean -replace '[^a-z0-9._:@-]', '_'
            if ($clean.Length -gt 160) { $clean = $clean.Substring(0,160) }
            return $clean
        }

        function Get-DownloadIdentity {
            param([string]$Url, [string]$SourceUrl, [string]$VideoId, [string]$ChannelId, [string]$Site, [bool]$AudioOnly)
            $candidate = if ($SourceUrl) { "$SourceUrl" } else { "$Url" }
            $id = if ($VideoId) { "$VideoId" } else { $null }
            $channel = if ($ChannelId) { "$ChannelId" } else { $null }
            $siteKey = if ($Site) { "$Site" } else { $null }
            try {
                $uri = [uri]$candidate
                $uriHost = ($uri.Host -replace '^www\.', '').ToLowerInvariant()
                $path = $uri.AbsolutePath
                if (-not $siteKey) { $siteKey = $uriHost }
                if ($uriHost -eq 'youtu.be' -or $uriHost -match '(^|\.)youtube\.com$') {
                    if (-not $id -and $uri.Query -match '[?&]v=([^&]+)') { $id = [uri]::UnescapeDataString($matches[1]) }
                    if (-not $id -and $path -match '/(?:shorts|embed|v)/([^/?]+)') { $id = [uri]::UnescapeDataString($matches[1]) }
                    if (-not $id -and $uriHost -eq 'youtu.be' -and $path -match '^/([^/?]+)') { $id = [uri]::UnescapeDataString($matches[1]) }
                    if (-not $channel -and $path -match '/(?:@|channel/|c/|user/)([^/?]+)') { $channel = [uri]::UnescapeDataString($matches[1]) }
                    $siteKey = 'youtube.com'
                } elseif ($uriHost -match '(^|\.)tiktok\.com$') {
                    if (-not $id -and $path -match '/video/(\d+)') { $id = $matches[1] }
                    if (-not $channel -and $path -match '/@([^/]+)') { $channel = [uri]::UnescapeDataString($matches[1]) }
                    $siteKey = 'tiktok.com'
                } elseif ($uriHost -match '(^|\.)instagram\.com$') {
                    if (-not $id -and $path -match '/(?:reel|reels|p|tv)/([^/?]+)') { $id = [uri]::UnescapeDataString($matches[1]) }
                    if (-not $channel -and $path -match '^/(?:stories/)?([^/]+)') { $channel = [uri]::UnescapeDataString($matches[1]) }
                    $siteKey = 'instagram.com'
                } elseif ($uriHost -eq 'x.com' -or $uriHost -match '(^|\.)twitter\.com$') {
                    if (-not $id -and $path -match '/status/(\d+)') { $id = $matches[1] }
                    if (-not $channel -and $path -match '^/([^/]+)/status/') { $channel = [uri]::UnescapeDataString($matches[1]) }
                    $siteKey = 'x.com'
                } elseif ($uriHost -match '(^|\.)twitch\.tv$') {
                    if (-not $id -and $path -match '/videos/(\d+)') { $id = $matches[1] }
                    if (-not $channel -and $path -match '^/([^/]+)') { $channel = [uri]::UnescapeDataString($matches[1]) }
                    $siteKey = 'twitch.tv'
                } elseif ($uriHost -match '(^|\.)facebook\.com$' -or $uriHost -eq 'fb.com') {
                    if (-not $id -and $path -match '/(?:videos|reel|reels)/(\d+)') { $id = $matches[1] }
                    if (-not $channel -and $path -match '^/([^/]+)/(?:videos|reel|reels)/') { $channel = [uri]::UnescapeDataString($matches[1]) }
                    $siteKey = 'facebook.com'
                } elseif ($uriHost -match '(^|\.)reddit\.com$') {
                    if (-not $id -and $path -match '/r/([^/]+)/comments/([^/?]+)') { $channel = [uri]::UnescapeDataString($matches[1]); $id = $matches[2] }
                    $siteKey = 'reddit.com'
                } elseif ($uriHost -match '(^|\.)vimeo\.com$') {
                    if (-not $id -and $path -match '/(?:video/)?(\d+)') { $id = $matches[1] }
                    $siteKey = 'vimeo.com'
                } elseif (-not $id -and $path -match '/(?:video|watch|status|reel|shorts)/([^/?]+)') {
                    $id = [uri]::UnescapeDataString($matches[1])
                }
            } catch {}
            if (-not $siteKey) { $siteKey = (Get-SiteKey $candidate) -replace '^www\.', '' }
            $siteKey = Normalize-IdentityPart $siteKey
            if ($id) {
                $key = "id|$siteKey|$(Normalize-IdentityPart $channel)|$(Normalize-IdentityPart $id)|$(if ($AudioOnly) { 'audio' } else { 'video' })"
            } else {
                $canonical = ($candidate.ToLowerInvariant() -replace '#.*$' -replace '[?&](utm_[^=]+|si|feature)=[^&]*','')
                $hash = [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes("$siteKey|$canonical"))).Replace('-','').Substring(0,24).ToLowerInvariant()
                $key = "url|$hash|$(if ($AudioOnly) { 'audio' } else { 'video' })"
            }
            return [pscustomobject]@{ key=$key; site=$siteKey; videoId=$id; channelId=$channel; sourceUrl=$candidate }
        }

        function Find-QueueDuplicate {
            param([string]$ContentKey)
            if (-not $ContentKey) { return $null }
            foreach ($dl in @($state.Downloads.Values | Sort-Object startTime)) {
                if ($dl.contentKey -eq $ContentKey -and $dl.status -notmatch 'complete|failed|cancelled') { return $dl }
            }
            return $null
        }

        function Get-ActiveSiteCount {
            param([string]$Site)
            @($state.Downloads.Values | Where-Object {
                $_.status -match 'downloading|merging|extracting' -and (Get-SiteKey $_.url) -eq $Site
            }).Count
        }

        function Get-NextQueuePriority {
            $priorities = @($state.Downloads.Values | ForEach-Object {
                try { [int]$_.priority } catch { 0 }
            })
            if ($priorities.Count -eq 0) { return 0 }
            return ([int](($priorities | Measure-Object -Maximum).Maximum) + 1)
        }

        function Get-DownloadProcessIds {
            param([int]$RootId)
            $ids = @($RootId)
            $pending = [System.Collections.Generic.Queue[int]]::new()
            $pending.Enqueue($RootId)
            while ($pending.Count -gt 0) {
                $parent = $pending.Dequeue()
                try {
                    $children = @(Get-CimInstance Win32_Process -Filter "ParentProcessId=$parent" -ErrorAction SilentlyContinue)
                    foreach ($child in $children) {
                        $childId = [int]$child.ProcessId
                        if ($ids -notcontains $childId) { $ids += $childId; $pending.Enqueue($childId) }
                    }
                } catch {}
            }
            return $ids
        }

        function Set-DownloadSuspended {
            param($Download, [bool]$Suspended)
            if (-not $Download.process -or $Download.process.HasExited) { return $false }
            $ok = $true
            foreach ($processId in (Get-DownloadProcessIds $Download.process.Id)) {
                try {
                    $child = Get-Process -Id $processId -ErrorAction Stop
                    $changed = if ($Suspended) {
                        [MediaDLProcessControl]::Suspend($child.Handle)
                    } else {
                        [MediaDLProcessControl]::Resume($child.Handle)
                    }
                    if (-not $changed) { $ok = $false }
                } catch { $ok = $false }
            }
            return $ok
        }

        if (-not ('MediaDL.NamedPipeHost' -as [type])) {
            Add-Type -TypeDefinition @"
using System;
using System.Collections.Concurrent;
using System.IO;
using System.IO.Pipes;
using System.Text;
using System.Threading;
namespace MediaDL {
    public sealed class NamedPipeRequest {
        public string Line { get; private set; }
        public string Response { get; set; }
        public ManualResetEventSlim Completed { get; private set; }
        public NamedPipeRequest(string line) { Line = line; Completed = new ManualResetEventSlim(false); }
    }
    public sealed class NamedPipeHost : IDisposable {
        private readonly string name;
        private readonly ConcurrentQueue<NamedPipeRequest> queue = new ConcurrentQueue<NamedPipeRequest>();
        private volatile bool stopping;
        private Thread worker;
        public NamedPipeHost(string pipeName) { name = pipeName; }
        public void Start() { worker = new Thread(Run) { IsBackground = true, Name = "MediaDL named pipe" }; worker.Start(); }
        public bool TryDequeue(out NamedPipeRequest request) { return queue.TryDequeue(out request); }
        public void Stop() {
            stopping = true;
            try { using (var wake = new NamedPipeClientStream(".", name, PipeDirection.Out)) { wake.Connect(250); } } catch { }
            if (worker != null && worker.IsAlive) worker.Join(1000);
        }
        private void Run() {
            while (!stopping) {
                try {
                    using (var pipe = new NamedPipeServerStream(name, PipeDirection.InOut, 1, PipeTransmissionMode.Byte, PipeOptions.Asynchronous)) {
                        pipe.WaitForConnection();
                        if (stopping) break;
                        using (var reader = new StreamReader(pipe, new UTF8Encoding(false), false, 4096, true))
                        using (var writer = new StreamWriter(pipe, new UTF8Encoding(false), 4096, true) { AutoFlush = true }) {
                            var line = reader.ReadLine();
                            if (line == null) continue;
                            var request = new NamedPipeRequest(line);
                            queue.Enqueue(request);
                            request.Completed.Wait(30000);
                            writer.WriteLine(request.Response ?? "{\"status\":503,\"body\":{\"error\":\"pipe request timeout\"}}");
                        }
                    }
                } catch { if (!stopping) Thread.Sleep(100); }
            }
        }
        public void Dispose() { Stop(); }
    }
}
"@
        }

        function Convert-PipeResult {
            param($Body, [int]$Status = 200)
            return (@{status=$Status;body=$Body} | ConvertTo-Json -Depth 7 -Compress)
        }
        function Get-PipeHeader {
            param($Headers,[string]$Name)
            if (-not $Headers) { return $null }
            $property = @($Headers.PSObject.Properties | Where-Object { $_.Name -ieq $Name } | Select-Object -First 1)
            if ($property) { return "$($property.Value)" }
            return $null
        }
        function Invoke-PipeRequest {
            param([string]$Line)
            try { $p = $Line | ConvertFrom-Json } catch { return (Convert-PipeResult @{error='Invalid JSON request'} 400) }
            $method = ("$($p.method)").ToUpperInvariant(); $path = (("$($p.path)" -split '\?')[0]).TrimEnd('/'); if (-not $path) { $path='/' }
            if ($method -eq 'OPTIONS') { return (Convert-PipeResult @{ok=$true}) }
            if ($path -notin @('/health','/ui') -and (Get-PipeHeader $p.headers 'X-Auth-Token') -ne $state.Token) { return (Convert-PipeResult @{error='Unauthorized'} 401) }
            switch -Regex ($path) {
                '^/health$' {
                    $active=@($state.Downloads.Values|Where-Object{$_.status -match 'downloading|merging|extracting'}).Count
                    $body=@{status='ok';version='5.0.0';port=$PORT;pipe=$config.NamedPipeName;downloads=$active;token_required=$true}
                    if ((Get-PipeHeader $p.headers 'X-MDL-Client') -eq 'MediaDL') { $body.token=$state.Token }
                    return (Convert-PipeResult $body)
                }
                '^/download$' {
                    if ($method -ne 'POST') { return (Convert-PipeResult @{error='Method not allowed'} 405) }
                    $params=$p.body; if($params -is [string]){try{$params=$params|ConvertFrom-Json}catch{return(Convert-PipeResult @{error='Invalid body'} 400)}}
                    if(-not $params -or -not $params.url){return(Convert-PipeResult @{error='Missing url'} 400)}
                    $identity=Get-DownloadIdentity -Url $params.url -SourceUrl $params.sourceUrl -VideoId $params.videoId -ChannelId $params.channelId -Site $params.site -AudioOnly ($params.audioOnly -eq $true)
                    $duplicate=Find-QueueDuplicate $identity.key; if($duplicate){return(Convert-PipeResult @{error='Duplicate download';duplicateId=$duplicate.id;contentKey=$identity.key;title=$duplicate.title} 409)}
                    $active=@($state.Downloads.Values|Where-Object{$_.status -match 'downloading|merging|extracting'}).Count; if($active -ge $MAX_CONCURRENT){return(Convert-PipeResult @{error='Too many concurrent downloads';active=$active} 429)}
                    $site=Get-SiteKey $params.url; $siteActive=Get-ActiveSiteCount $site; if($siteActive -ge $SITE_CONCURRENCY_CAP){return(Convert-PipeResult @{error='Per-site concurrency limit reached';site=$site;active=$siteActive;limit=$SITE_CONCURRENCY_CAP} 429)}
                    $id=Start-Download $params; return(Convert-PipeResult @{id=$id;status='downloading'})
                }
                '^/status/(.+)$' {
                    $id=$matches[1]; Update-Downloads; if(-not $state.Downloads.ContainsKey($id)){return(Convert-PipeResult @{error='Not found'} 404)}
                    $dl=$state.Downloads[$id]; return(Convert-PipeResult @{id=$dl.id;status=$dl.status;progress=[math]::Round($dl.progress,1);speed=$dl.speed;eta=$dl.eta;title=$dl.title;filename=$dl.filename})
                }
                '^/queue$' {
                    $list=@(); foreach($dl in @($state.Downloads.Values|Sort-Object priority,startTime)){$list+=@{id=$dl.id;status=$dl.status;progress=[math]::Round($dl.progress,1);title=$dl.title;speed=$dl.speed;eta=$dl.eta;priority=[int]$dl.priority;site=(Get-SiteKey $dl.url);videoId=$dl.videoId;channelId=$dl.channelId}}
                    return(Convert-PipeResult @{downloads=$list;count=$list.Count})
                }
                '^/pause/(.+)$' {
                    if($method -ne 'POST'){return(Convert-PipeResult @{error='Method not allowed'} 405)}; $id=$matches[1]; if(-not $state.Downloads.ContainsKey($id)){return(Convert-PipeResult @{error='Not found'} 404)}; $dl=$state.Downloads[$id]
                    if($dl.status -eq 'paused'){return(Convert-PipeResult @{id=$id;status='paused'})}; if($dl.status -match 'complete|failed|cancelled' -or -not $dl.process){return(Convert-PipeResult @{error='Download cannot be paused';status=$dl.status} 409)}
                    if(Set-DownloadSuspended $dl $true){$dl.status='paused';Save-QueueRecord $dl;return(Convert-PipeResult @{id=$id;status='paused'})}; return(Convert-PipeResult @{error='Could not suspend download'} 500)
                }
                '^/resume/(.+)$' {
                    if($method -ne 'POST'){return(Convert-PipeResult @{error='Method not allowed'} 405)}; $id=$matches[1]; if(-not $state.Downloads.ContainsKey($id)){return(Convert-PipeResult @{error='Not found'} 404)}; $dl=$state.Downloads[$id]
                    if($dl.status -ne 'paused'){return(Convert-PipeResult @{id=$id;status=$dl.status})}; if(Set-DownloadSuspended $dl $false){$dl.status='downloading';Save-QueueRecord $dl;return(Convert-PipeResult @{id=$id;status='downloading'})}; return(Convert-PipeResult @{error='Could not resume download'} 500)
                }
                '^/cancel/(.+)$' {
                    if($method -ne 'DELETE'){return(Convert-PipeResult @{error='Method not allowed'} 405)}; $id=$matches[1]; if(-not $state.Downloads.ContainsKey($id)){return(Convert-PipeResult @{error='Not found'} 404)}; $dl=$state.Downloads[$id];if($dl.process -and -not $dl.process.HasExited){try{$dl.process.Kill()}catch{}};$dl.status='cancelled';Save-QueueRecord $dl;return(Convert-PipeResult @{id=$id;cancelled=$true})
                }
                '^/shutdown$' { if($method -ne 'POST'){return(Convert-PipeResult @{error='Method not allowed'} 405)};$state.ShouldStop=$true;return(Convert-PipeResult @{status='shutting_down'}) }
                default { return(Convert-PipeResult @{error='Not found';path=$path} 404) }
            }
        }
        function Start-PipeRequestPump {
            param([string]$Name)
            try{$script:NamedPipeHost=[MediaDL.NamedPipeHost]::new($Name);$script:NamedPipeHost.Start();Write-SLog "Named pipe listening on $Name";return $true}catch{Write-SLog "Named pipe unavailable: $($_.Exception.Message)";$script:NamedPipeHost=$null;return $false}
        }
        function Process-PipeRequests {
            if(-not $script:NamedPipeHost){return};while($true){$request=$null;if(-not $script:NamedPipeHost.TryDequeue([ref]$request)){break};try{$request.Response=Invoke-PipeRequest $request.Line}catch{$request.Response=Convert-PipeResult @{error='Pipe request failed';detail="$($_.Exception.Message)"} 500};[void]$request.Completed.Set()}
        }

        function Read-FileTail {
            param([string]$Path, [int]$Bytes = 4096)
            try {
                $fs = [System.IO.File]::Open($Path, 'Open', 'Read', 'ReadWrite')
                try {
                    $len = $fs.Length; if ($len -eq 0) { return "" }
                    $start = [Math]::Max(0, $len - $Bytes)
                    $fs.Seek($start, 'Begin') | Out-Null
                    $buf = New-Object byte[] ([Math]::Min($Bytes, $len))
                    $read = $fs.Read($buf, 0, $buf.Length)
                    return [System.Text.Encoding]::UTF8.GetString($buf, 0, $read)
                } finally { $fs.Close() }
            } catch { return "" }
        }

        function Save-HistoryEntry {
            param([hashtable]$entry)
            try {
                $history = @()
                if (Test-Path $state.HistoryPath) {
                    $raw = Get-Content $state.HistoryPath -Raw -ErrorAction SilentlyContinue
                    if ($raw) { $history = @($raw | ConvertFrom-Json) }
                }
                $history += [PSCustomObject]$entry
                if ($history.Count -gt 500) { $history = $history[-500..-1] }
                $history | ConvertTo-Json -Depth 3 -Compress | Set-Content $state.HistoryPath -Encoding UTF8
            } catch {}
        }

        function Get-SafePostProcessName {
            param([string]$Value)
            $name = if ($Value) { [System.IO.Path]::GetFileNameWithoutExtension("$Value") } else { 'MediaDL' }
            $name = ($name -replace '[<>:"/\\|?*]', '_') -replace '\s+', ' '
            $name = $name.Trim(' ', '.')
            if (-not $name) { $name = 'MediaDL' }
            if ($name.Length -gt 120) { $name = $name.Substring(0,120).TrimEnd(' ', '.') }
            return $name
        }

        function Get-UniquePostProcessPath {
            param([string]$Directory, [string]$BaseName, [string]$Extension)
            $candidate = Join-Path $Directory ("$BaseName$Extension")
            $index = 1
            while (Test-Path -LiteralPath $candidate) {
                $candidate = Join-Path $Directory ("$BaseName ($index)$Extension")
                $index++
            }
            return $candidate
        }

        function Get-PostProcessSource {
            param($Download)
            if ($Download.filename -and (Test-Path -LiteralPath $Download.filename -PathType Leaf)) {
                return Get-Item -LiteralPath $Download.filename
            }
            if (-not $Download.outputDir -or -not (Test-Path -LiteralPath $Download.outputDir)) { return $null }
            $since = (Get-Date).AddMinutes(-2)
            return @(Get-ChildItem -LiteralPath $Download.outputDir -File -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $_.LastWriteTime -ge $since -and $_.Extension -match '^\.(mp4|mkv|webm|mov|m4v|mp3|m4a|opus|flac|wav)$' } |
                Sort-Object LastWriteTime -Descending | Select-Object -First 1)
        }

        function Invoke-HardwareTranscode {
            param($Download)
            if ($Download.audioOnly) { return $false }
            $encoder = ("$($config.HardwareEncoder)").Trim().ToLowerInvariant()
            if (@('nvenc','qsv') -notcontains $encoder) { return $false }
            $source = Get-PostProcessSource $Download
            if (-not $source) { Write-SLog "[$($Download.id)] Hardware transcode skipped: output file not found"; return $false }
            if ($source.Extension -match '^\.webm$') { Write-SLog "[$($Download.id)] Hardware transcode skipped: WebM container cannot carry the selected H.264 stream"; return $false }
            if (-not (Test-Path -LiteralPath $config.FfmpegPath)) { Write-SLog "[$($Download.id)] Hardware transcode skipped: ffmpeg not found"; return $false }
            $codec = if ($encoder -eq 'nvenc') { 'h264_nvenc' } else { 'h264_qsv' }
            $temp = "$($source.FullName).mdl_hw_$([guid]::NewGuid().ToString('N'))$($source.Extension)"
            $args = @('-hide_banner','-loglevel','error','-y','-i',$source.FullName,'-map','0','-c:v',$codec,'-c:a','copy','-c:s','copy','-c:d','copy',$temp)
            try {
                & $config.FfmpegPath @args 2>$null | Out-Null
                if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $temp)) { Write-SLog "[$($Download.id)] Hardware transcode failed ($encoder)"; return $false }
                Move-Item -LiteralPath $temp -Destination $source.FullName -Force
                $Download.filename = $source.FullName
                Write-SLog "[$($Download.id)] Hardware transcode complete: $encoder"
                return $true
            } catch {
                if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue }
                Write-SLog "[$($Download.id)] Hardware transcode error: $($_.Exception.Message)"
                return $false
            }
        }

        function Send-CompletionToast {
            param($Download)
            if ($config.ToastNotifications -ne $true) { return }
            try {
                [void][Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
                [void][Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
                $title = [System.Security.SecurityElement]::Escape(([string]$Download.title))
                $detail = if ($Download.filename) { "Saved: $($Download.filename)" } else { 'Download complete' }
                $detail = [System.Security.SecurityElement]::Escape([string]$detail)
                $xml = [Windows.Data.Xml.Dom.XmlDocument]::new()
                $xml.LoadXml("<toast><visual><binding template='ToastGeneric'><text>$title</text><text>$detail</text></binding></visual></toast>")
                $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
                [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('MediaDL').Show($toast)
            } catch {
                Write-SLog "[$($Download.id)] Windows toast unavailable: $($_.Exception.Message)"
            }
        }

        function Get-MusicBrainzTags {
            param([string]$Title)
            if (-not $Title) { return $null }
            try {
                $query = [uri]::EscapeDataString("recording:$Title")
                $response = Invoke-RestMethod -Uri "https://musicbrainz.org/ws/2/recording/?query=$query&fmt=json&limit=1" -Headers @{ 'User-Agent' = 'MediaDL/5.0 (https://github.com/SysAdminDoc/MediaDL)' } -TimeoutSec 5 -ErrorAction Stop
                $record = @($response.recordings) | Select-Object -First 1
                if (-not $record) { return $null }
                $artist = @($record.'artist-credit' | ForEach-Object { $_.name }) -join ', '
                $release = @($record.releases) | Select-Object -First 1
                return @{ title="$($record.title)"; artist="$artist"; album="$($release.title)"; date="$($release.date)"; recordingId="$($record.id)" }
            } catch {
                Write-SLog "MusicBrainz lookup failed: $($_.Exception.Message)"
                return $null
            }
        }

        function Set-PostProcessTags {
            param([string]$Path, [hashtable]$Tags)
            if (-not $Tags -or -not (Test-Path -LiteralPath $config.FfmpegPath)) { return $false }
            $extension = [System.IO.Path]::GetExtension($Path)
            $temp = "$Path.mdl_tags_$([guid]::NewGuid().ToString('N'))$extension"
            $args = @('-hide_banner','-loglevel','error','-y','-i',$Path,'-map','0','-c','copy')
            foreach ($tagName in @('title','artist','album','date','musicbrainz_recordingid')) {
                $tagValue = $Tags[$tagName]
                if (-not $tagValue -and $tagName -eq 'musicbrainz_recordingid') { $tagValue = $Tags.recordingId }
                if ($tagValue) { $args += '-metadata'; $args += ("{0}={1}" -f $tagName,$tagValue) }
            }
            $args += $temp
            try {
                & $config.FfmpegPath @args 2>$null | Out-Null
                if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $temp)) { return $false }
                Move-Item -LiteralPath $temp -Destination $Path -Force
                return $true
            } catch {
                if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue }
                Write-SLog "Audio tagging failed: $($_.Exception.Message)"
                return $false
            }
        }

        function Invoke-PostProcess {
            param($Download)
            if ($config.PostProcessAudio -ne $true -and $config.PostProcessMusicBrainz -ne $true) { return }
            if (-not $config.MusicFolder) { Write-SLog "Post-processing skipped: MusicFolder is empty"; return }
            $source = Get-PostProcessSource $Download
            if (-not $source) { Write-SLog "[$($Download.id)] Post-processing skipped: output file not found"; return }
            try { New-Item -ItemType Directory -Path $config.MusicFolder -Force | Out-Null } catch { Write-SLog "Music folder unavailable: $($_.Exception.Message)"; return }
            $audioPath = $null
            if ($Download.audioOnly) {
                $audioPath = $source.FullName
            } else {
                if (-not (Test-Path -LiteralPath $config.FfmpegPath)) { Write-SLog "[$($Download.id)] Post-processing skipped: ffmpeg not found"; return }
                $stagingName = Get-SafePostProcessName $Download.title
                $stagingDirectory = if ($Download.outputDir -and (Test-Path -LiteralPath $Download.outputDir)) { $Download.outputDir } else { $config.MusicFolder }
                $audioPath = Get-UniquePostProcessPath $stagingDirectory $stagingName '.mp3'
                $extractArgs = @('-hide_banner','-loglevel','error','-y','-i',$source.FullName,'-vn','-map','0:a:0','-codec:a','libmp3lame','-q:a','2',$audioPath)
                & $config.FfmpegPath @extractArgs 2>$null | Out-Null
                if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $audioPath)) { Write-SLog "[$($Download.id)] Audio extraction failed"; return }
            }
            $tags = $null
            if ($config.PostProcessMusicBrainz -eq $true) {
                $tags = Get-MusicBrainzTags $Download.title
                if ($tags) { [void](Set-PostProcessTags $audioPath $tags) }
            }
            $base = if ($tags -and $tags.artist -and $tags.title) { Get-SafePostProcessName ("$($tags.artist) - $($tags.title)") } else { Get-SafePostProcessName $Download.title }
            $destination = Get-UniquePostProcessPath $config.MusicFolder $base ([System.IO.Path]::GetExtension($audioPath))
            if ([System.IO.Path]::GetFullPath($audioPath) -ne [System.IO.Path]::GetFullPath($destination)) {
                Move-Item -LiteralPath $audioPath -Destination $destination -Force
            }
            $Download.filename = $destination
            $Download.postProcessedPath = $destination
            Write-SLog "[$($Download.id)] Post-processing complete: $destination"
        }

        function Start-AudioFallback {
            param($Download)
            $fallback = if ($Download.fallbackFormat) { ("$($Download.fallbackFormat)").ToLowerInvariant() } else { $null }
            if (-not $Download.audioOnly -or $Download.fallbackAttempted -or @('mp3','m4a','opus','flac','wav') -notcontains $fallback) { return $false }
            $Download.fallbackAttempted = $true
            foreach ($oldFile in @($Download.progressFile, (Join-Path $env:TEMP "mdl_stderr_$($Download.id).txt"))) {
                if ($oldFile -and (Test-Path -LiteralPath $oldFile)) { Remove-Item -LiteralPath $oldFile -Force -ErrorAction SilentlyContinue }
            }
            $progressFile = Join-Path $env:TEMP "mdl_progress_$($Download.id)_fallback.txt"
            "" | Set-Content $progressFile -Force
            $outDir = if ($Download.outputDir -and (Test-Path -LiteralPath $Download.outputDir)) { $Download.outputDir } else { $config.DownloadPath }
            $outTpl = Join-Path $outDir "%(title)s.$fallback"
            $ffLoc = Split-Path $config.FfmpegPath -Parent
            $args = @('-f','bestaudio','--extract-audio','--audio-format',$fallback,'--audio-quality','0','--newline','--progress','--no-colors','--ffmpeg-location',$ffLoc,'-o',$outTpl)
            $args += '--progress-template'; $args += 'download:MDLP %(progress._percent_str)s %(progress._speed_str)s %(progress._eta_str)s'
            if ($config.ConcurrentFragments -gt 0) { $args += '--concurrent-fragments'; $args += "$($config.ConcurrentFragments)" }
            if ($config.EmbedMetadata -eq $true) { $args += '--embed-metadata' }
            if ($config.DownloadArchive -eq $true) { $args += '--download-archive'; $args += $state.ArchivePath }
            if ($config.Proxy -and $config.Proxy -match '^(socks[45]|https?):') { $args += '--proxy'; $args += $config.Proxy }
            if ($Download.referer) { $args += '--referer'; $args += $Download.referer }
            $args += $Download.url
            try {
                $Download.process = Start-Process -FilePath $config.YtDlpPath -ArgumentList $args -NoNewWindow -PassThru `
                    -RedirectStandardOutput $progressFile -RedirectStandardError (Join-Path $env:TEMP "mdl_stderr_$($Download.id).txt")
                $Download.progressFile = $progressFile
                $Download.format = $fallback
                $Download.status = 'downloading'
                $Download.progress = 0
                $Download.speed = ''; $Download.eta = ''; $Download.filename = ''
                Save-QueueRecord $Download
                Write-SLog "[$($Download.id)] Primary audio format failed; retrying with $fallback"
                return $true
            } catch {
                Write-SLog "[$($Download.id)] Audio fallback could not start: $($_.Exception.Message)"
                return $false
            }
        }

        function Start-Download {
            param($params)
            $state.NextId++
            $id = "dl_$($state.NextId)_$([guid]::NewGuid().ToString('N').Substring(0,6))"
            $progressFile = Join-Path $env:TEMP "mdl_progress_$id.txt"
            "" | Set-Content $progressFile -Force

            $audioOnly = $params.audioOnly -eq $true
            $url = $params.url; $title = $params.title
            $identity = Get-DownloadIdentity -Url $url -SourceUrl $params.sourceUrl -VideoId $params.videoId -ChannelId $params.channelId -Site $params.site -AudioOnly $audioOnly
            $referer = $params.referer
            $recordFromNow = $params.recordFromNow -eq $true
            $splitChapters = $config.SplitChapters -eq $true
            if ($params.PSObject.Properties.Name -contains 'splitChapters') {
                $splitChapters = [bool]$params.splitChapters
            }
            $isDirect = $url -match "fbcdn\.net|\.mp4\?|\.webm\?|\.m3u8(?:\?|$)"

            $allowedVF = @('mp4','mkv','webm'); $allowedAF = @('mp3','m4a','opus','flac','wav')
            $allowedQ = @('best','2160','1440','1080','720','480')
            $siteKey = if ($params.site) { ("$($params.site)").Trim().ToLowerInvariant() } else { Get-SiteKey $url }
            $sitePreset = Get-SiteFormatPreset $siteKey
            $presetFormat = if ($sitePreset -and $sitePreset.format) { ("$($sitePreset.format)").ToLowerInvariant() } else { $null }
            $presetQuality = if ($sitePreset -and $sitePreset.quality) { ("$($sitePreset.quality)").ToLowerInvariant() } else { $null }
            $presetCodec = if ($sitePreset -and $sitePreset.codec) { ("$($sitePreset.codec)").ToLowerInvariant() } else { 'auto' }
            $presetFallback = if ($sitePreset -and $sitePreset.fallbackFormat) { ("$($sitePreset.fallbackFormat)").ToLowerInvariant() } else { $null }
            $reqFmt = if ($params.format) { ("$($params.format)").ToLowerInvariant() } elseif ($presetFormat) { $presetFormat } else { $null }
            $reqQ = if ($params.quality) { ("$($params.quality)").ToLowerInvariant() } elseif ($presetQuality) { $presetQuality } else { 'best' }
            $format = if ($audioOnly) { if ($reqFmt -and $allowedAF -contains $reqFmt) { $reqFmt } else { 'mp3' } } else { if ($reqFmt -and $allowedVF -contains $reqFmt) { $reqFmt } else { 'mp4' } }
            $quality = if ($allowedQ -contains $reqQ) { $reqQ } else { 'best' }
            if (-not $audioOnly -and $config.SubtitleSrt -eq $true) { $format = 'mkv' }
            $codec = if (-not $audioOnly -and @('av01','vp9','h264','hevc') -contains $presetCodec) { $presetCodec } else { 'auto' }
            $fallbackFormat = if ($audioOnly -and $allowedAF -contains $presetFallback -and $presetFallback -ne $format) { $presetFallback } else { $null }
            if (-not $audioOnly -and $sitePreset -and $sitePreset.codec) { Write-SLog "[$id] Site preset $siteKey selects codec=$codec" }

            $outDir = $config.DownloadPath
            if ($audioOnly -and $config.AudioDownloadPath) { $outDir = $config.AudioDownloadPath }
            if ($params.outputDir) {
                $rd = "$($params.outputDir)".Trim()
                if ($rd -match '^[A-Za-z]:\\' -and $rd -notmatch '\.\.' -and $rd.Length -le 260) {
                    if (!(Test-Path $rd)) { try { New-Item -ItemType Directory -Path $rd -Force | Out-Null } catch {} }
                    if (Test-Path $rd) { $outDir = $rd }
                }
            }

            $ffLoc = Split-Path $config.FfmpegPath -Parent
            $isPlaylist = $url -match '[?&]list=' -and $url -notmatch '[?&]v='
            $chapterSuffix = if ($splitChapters) { " - %(section_number)03d %(section_title)s" } else { "" }
            if ($isPlaylist) { $outTpl = Join-Path $outDir "%(playlist_title)s/%(title)s$chapterSuffix.$format" }
            else { $outTpl = Join-Path $outDir "%(title)s$chapterSuffix.$format" }

            $videoSelector = switch ($codec) {
                'av01' { 'bestvideo[vcodec^=av01]' }
                'vp9'  { 'bestvideo[vcodec^=vp9]' }
                'h264' { 'bestvideo[vcodec^=avc1]' }
                'hevc' { 'bestvideo[vcodec^=hev1]' }
                default { 'bestvideo' }
            }
            if ($quality -eq 'best') {
                $fmtSel = if ($codec -eq 'auto') { 'bestvideo+bestaudio/best' } else { "$videoSelector+bestaudio/bestvideo+bestaudio/best" }
            } else {
                $heightSelector = "$videoSelector[height<=$quality]"
                $fallbackHeight = "bestvideo[height<=$quality]"
                $fmtSel = if ($codec -eq 'auto') { "$fallbackHeight+bestaudio/best[height<=$quality]/best" } else { "$heightSelector+bestaudio/$fallbackHeight+bestaudio/best[height<=$quality]/best" }
            }

            $args = @('--newline','--progress','--no-colors','--ffmpeg-location',$ffLoc,'-o',$outTpl)
            $args += '--progress-template'; $args += 'download:MDLP %(progress._percent_str)s %(progress._speed_str)s %(progress._eta_str)s'
            $frags = if ($config.ConcurrentFragments -gt 0) { $config.ConcurrentFragments } else { 4 }
            $args += '--concurrent-fragments'; $args += "$frags"
            if ($config.EmbedMetadata -eq $true) { $args += '--embed-metadata' }
            if ($config.EmbedThumbnail -eq $true) { $args += '--embed-thumbnail' }
            if ($config.EmbedChapters -eq $true) { $args += '--embed-chapters' }
            if ($splitChapters) { $args += '--split-chapters' }
            if (-not $audioOnly -and -not $isDirect -and $config.SubtitleSrt -eq $true) {
                $args += '--write-subs'; $args += '--write-auto-subs'; $args += '--sub-langs'; $args += (($config.SubLangs -replace '[^a-zA-Z0-9,\-]','') -replace '^$','all'); $args += '--sub-format'; $args += 'srt'; $args += '--embed-subs'
            } elseif ($config.EmbedSubs -eq $true) {
                $args += '--embed-subs'; $args += '--write-subs'; $args += '--write-auto-subs'; $args += '--sub-langs'; $args += (($config.SubLangs -replace '[^a-zA-Z0-9,\-]','') -replace '^$','all')
            }
            if ($config.SponsorBlock -eq $true) { $action = if ($config.SponsorBlockAction -eq 'mark') {'mark'} else {'remove'}; $args += "--sponsorblock-$action"; $args += 'all' }
            if ($config.DownloadArchive -eq $true) { $args += '--download-archive'; $args += $state.ArchivePath }
            $bandwidthLimit = [int]$config.BandwidthLimitKbps
            if ($bandwidthLimit -gt 0) {
                $args += '--limit-rate'; $args += ("{0}K" -f $bandwidthLimit)
            } elseif ($config.RateLimit -and $config.RateLimit -match '^\d+[KMG]?$') {
                $args += '--limit-rate'; $args += $config.RateLimit
            }
            if ($config.Proxy -and $config.Proxy -match '^(socks|https?):') { $args += '--proxy'; $args += $config.Proxy }
            if ($referer) { $args += '--referer'; $args += $referer }
            if ($isPlaylist) { $args += '--yes-playlist' }

            if ($audioOnly) {
                $ytArgs = @('-f','bestaudio','--extract-audio','--audio-format',$format,'--audio-quality','0') + $args + @($url)
            } elseif ($isDirect) {
                $ytArgs = $args + @($url)
            } else {
                $ytArgs = @('-f',$fmtSel,'--merge-output-format',$format) + $args + @($url)
            }

            $proc = Start-Process -FilePath $config.YtDlpPath -ArgumentList $ytArgs -NoNewWindow -PassThru `
                -RedirectStandardOutput $progressFile -RedirectStandardError (Join-Path $env:TEMP "mdl_stderr_$id.txt")

            $state.Downloads[$id] = [hashtable]::Synchronized(@{
                id=$id; url=$url; title=if($title){$title}else{"Unknown"}; audioOnly=$audioOnly
                status="downloading"; progress=0; speed=""; eta=""; process=$proc
                progressFile=$progressFile; startTime=(Get-Date); filename=""; format=$format; quality=$quality; site=$siteKey; formatPreset=$siteKey; codec=$codec; fallbackFormat=$fallbackFormat; fallbackAttempted=$false
                splitChapters=$splitChapters; recordFromNow=$recordFromNow; priority=(Get-NextQueuePriority)
                contentKey=$identity.key; videoId=$identity.videoId; channelId=$identity.channelId; sourceUrl=$identity.sourceUrl
                referer=$referer; outputDir=$outDir
            })
            Save-QueueRecord $state.Downloads[$id]
            Write-SLog "[$id] Started: $($url.Substring(0,[Math]::Min(60,$url.Length)))... recordFromNow=$recordFromNow"
            return $id
        }

        function Update-Downloads {
            foreach ($id in @($state.Downloads.Keys)) {
                $dl = $state.Downloads[$id]
                if ($dl.status -eq 'complete' -or $dl.status -eq 'failed' -or $dl.status -eq 'cancelled') { continue }
                if ($dl.status -eq 'paused') { continue }
                if (-not $dl.process) { continue }
                if (Test-Path $dl.progressFile) {
                    $tail = Read-FileTail $dl.progressFile
                    if ($tail) {
                        $lines = $tail -split "`n"
                        for ($i = $lines.Count - 1; $i -ge 0; $i--) {
                            if ($lines[$i] -match '^MDLP\s+(\d+\.?\d*)%?\s+(\S+)\s+(\S+)') {
                                $dl.progress = [double]($matches[1] -replace '%','')
                                if ($matches[2] -ne 'NA' -and $matches[2] -ne 'Unknown') { $dl.speed = $matches[2] }
                                if ($matches[3] -ne 'NA' -and $matches[3] -ne 'Unknown') { $dl.eta = $matches[3] }
                                break
                            }
                            if ($lines[$i] -match '\[download\]\s+(\d+\.?\d*)%') {
                                $dl.progress = [double]$matches[1]
                                if ($lines[$i] -match 'at\s+(\S+)\s+ETA\s+(\S+)') { $dl.speed = $matches[1]; $dl.eta = $matches[2] }
                                break
                            }
                        }
                        if ($tail -match '\[Merger\]|Merging formats') { $dl.status = "merging" }
                        elseif ($tail -match '\[ExtractAudio\]|\[extract\]') { $dl.status = "extracting" }
                        elseif ($tail -match 'already been downloaded') { $dl.progress = 100; $dl.status = "complete" }
                        if ($tail -match '\[Merger\] Merging formats into "(.+)"') { $dl.filename = $matches[1] }
                        elseif ($tail -match '\[download\] Destination: (.+)') { $dl.filename = $matches[1] }
                    }
                }
                if ($dl.process.HasExited) {
                    $out = if (Test-Path $dl.progressFile) { Read-FileTail $dl.progressFile 8192 } else { "" }
                    if ($out -match "100%|has already been downloaded|Merging formats into|DelayedMuxer|audio extraction complete") {
                        $dl.status = "post-processing"; Save-QueueRecord $dl
                        try { [void](Invoke-HardwareTranscode $dl) } catch { Write-SLog "[$id] Hardware transcode error: $($_.Exception.Message)" }
                        try { Invoke-PostProcess $dl } catch { Write-SLog "[$id] Post-processing error: $($_.Exception.Message)" }
                        try { Send-CompletionToast $dl } catch { Write-SLog "[$id] Completion toast error: $($_.Exception.Message)" }
                        $dl.status = "complete"; $dl.progress = 100; $state.TotalCompleted++
                        Write-SLog "[$id] Complete"
                        Save-HistoryEntry @{ id=$dl.id; url=$dl.url; title=$dl.title; filename=$dl.filename; format=$dl.format; quality=$dl.quality; audioOnly=$dl.audioOnly; date=(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'); duration=[math]::Round(((Get-Date)-$dl.startTime).TotalSeconds) }
                    } else {
                        if (Start-AudioFallback $dl) { continue }
                        $dl.status = "failed"
                        Write-SLog "[$id] Failed"
                    }
                    Save-QueueRecord $dl
                    foreach ($f in @($dl.progressFile, (Join-Path $env:TEMP "mdl_stderr_$id.txt"), (Join-Path $env:TEMP "mdl_wrap_$id.ps1"))) {
                        if (Test-Path $f) { Remove-Item $f -Force -ErrorAction SilentlyContinue }
                    }
                }
            }
            # Cleanup old entries (>5min)
            $cutoff = (Get-Date).AddMinutes(-5)
            foreach ($id in @($state.Downloads.Keys)) {
                $dl = $state.Downloads[$id]
                if (($dl.status -eq 'complete' -or $dl.status -eq 'failed') -and $dl.startTime -lt $cutoff) {
                    $state.Downloads.Remove($id)
                }
            }
        }

        # ── JSON response helper ──
        function Send-Json { param($ctx, $data, [int]$code=200)
            $json = $data | ConvertTo-Json -Depth 5 -Compress
            $buf = [System.Text.Encoding]::UTF8.GetBytes($json)
            $ctx.Response.StatusCode = $code
            $ctx.Response.ContentType = "application/json; charset=utf-8"
            $ctx.Response.Headers.Add("Access-Control-Allow-Origin","*")
            $ctx.Response.Headers.Add("Access-Control-Allow-Methods","GET,POST,PUT,DELETE,OPTIONS")
            $ctx.Response.Headers.Add("Access-Control-Allow-Headers","Content-Type,X-Auth-Token,X-MDL-Client")
            $ctx.Response.ContentLength64 = $buf.Length
            try { $ctx.Response.OutputStream.Write($buf,0,$buf.Length); $ctx.Response.OutputStream.Close() } catch {}
        }
        function Read-Body { param($req)
            try { $r = New-Object System.IO.StreamReader($req.InputStream,$req.ContentEncoding); $b = $r.ReadToEnd(); $r.Close(); return $b } catch { return $null }
        }

        function Send-QueueUi { param($ctx)
            $html = @"
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>MediaDL Queue</title>
<style>
:root { color-scheme: dark; font-family: Inter, Segoe UI, sans-serif; background: #10131a; color: #f4f7fb; }
* { box-sizing: border-box; }
body { margin: 0; min-height: 100vh; background: radial-gradient(circle at top right, #263451 0, #10131a 42rem); }
main { width: min(960px, 100%); margin: 0 auto; padding: 28px 18px 56px; }
header { display: flex; justify-content: space-between; align-items: flex-start; gap: 20px; margin-bottom: 26px; }
.eyebrow { color: #7dd3fc; font-size: 12px; font-weight: 700; letter-spacing: .16em; margin: 0 0 8px; }
h1 { font-size: clamp(28px, 5vw, 46px); line-height: 1; margin: 0 0 10px; letter-spacing: -.04em; }
#updated { color: #9aa8bd; font-size: 13px; }
button { border: 1px solid #35445e; border-radius: 9px; background: #182235; color: #f4f7fb; cursor: pointer; font: inherit; padding: 9px 13px; }
button:hover { background: #23324d; border-color: #5c7bab; }
button:focus-visible { outline: 2px solid #7dd3fc; outline-offset: 2px; }
.notice { border: 1px solid #263754; border-radius: 12px; color: #aebbd0; padding: 13px 15px; margin-bottom: 14px; }
.notice.error { border-color: #7f1d1d; color: #fecaca; }
#queue-list { display: grid; gap: 11px; list-style: none; padding: 0; margin: 0; }
.queue-item { display: grid; grid-template-columns: 34px 1fr auto; align-items: center; gap: 13px; border: 1px solid #2b3952; border-radius: 14px; padding: 14px; background: rgba(20, 28, 43, .88); box-shadow: 0 10px 26px rgba(0, 0, 0, .16); transition: border-color .15s, transform .15s, opacity .15s; }
.queue-item:hover { border-color: #526b96; }
.queue-item.dragging { opacity: .46; transform: scale(.99); }
.handle { color: #7790b7; cursor: grab; font-size: 23px; line-height: 1; text-align: center; user-select: none; }
.handle:active { cursor: grabbing; }
.title { font-weight: 650; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.meta { color: #91a0b8; font-size: 12px; margin-top: 5px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.progress { background: #0b1018; border-radius: 999px; height: 6px; margin-top: 11px; overflow: hidden; }
.progress > span { background: linear-gradient(90deg, #38bdf8, #818cf8); border-radius: inherit; display: block; height: 100%; min-width: 2px; }
.actions { display: flex; align-items: center; justify-content: flex-end; gap: 7px; }
.actions button { font-size: 12px; padding: 7px 9px; }
.status { color: #86efac; font-size: 12px; text-transform: capitalize; white-space: nowrap; }
.status.paused { color: #fcd34d; }
.status.failed, .status.cancelled { color: #fca5a5; }
.empty { border: 1px dashed #40516e; border-radius: 14px; color: #9aa8bd; padding: 34px 18px; text-align: center; }
@media (max-width: 680px) {
  main { padding: 22px 12px 40px; }
  header { align-items: stretch; flex-direction: column; }
  header button { align-self: flex-start; }
  .queue-item { grid-template-columns: 28px 1fr; }
  .actions { grid-column: 2; justify-content: flex-start; flex-wrap: wrap; }
}
</style>
</head>
<body>
<main>
<header>
<div><p class="eyebrow">MEDIADL / LOCAL SERVER</p><h1>Download queue</h1><span id="updated">Connecting...</span></div>
<button id="refresh" type="button">Refresh</button>
</header>
<div id="notice" class="notice">Loading queue...</div>
<ul id="queue-list" aria-live="polite"></ul>
</main>
<script>
(function () {
  var token = '';
  var draggingId = '';
  var list = document.getElementById('queue-list');
  var notice = document.getElementById('notice');
  var updated = document.getElementById('updated');

  function escapeHtml(value) {
    return String(value == null ? '' : value).replace(/[&<>\"]/g, function (character) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '\"': '&quot;' }[character];
    });
  }

  function setNotice(message, isError) {
    notice.textContent = message;
    notice.className = isError ? 'notice error' : 'notice';
  }

  function headers() { return { 'X-Auth-Token': token }; }

  function render(items) {
    if (!items.length) {
      list.innerHTML = '<li class="empty">No downloads in the queue.</li>';
      return;
    }
    list.innerHTML = items.map(function (item) {
      var progress = Math.max(0, Math.min(100, Number(item.progress) || 0));
      var status = String(item.status || 'unknown');
      var site = item.site || 'unknown host';
      var action = '';
      if (status === 'paused') action += '<button type="button" data-action="resume" data-id="' + escapeHtml(item.id) + '">Resume</button>';
      else if (/^(downloading|merging|extracting)$/.test(status)) action += '<button type="button" data-action="pause" data-id="' + escapeHtml(item.id) + '">Pause</button>';
      if (!/^(complete|failed|cancelled)$/.test(status)) action += '<button type="button" data-action="cancel" data-id="' + escapeHtml(item.id) + '">Cancel</button>';
      return '<li class="queue-item" draggable="true" data-id="' + escapeHtml(item.id) + '">' +
        '<div class="handle" title="Drag to reorder" aria-label="Drag to reorder">&#8942;</div>' +
        '<div><div class="title" title="' + escapeHtml(item.title || item.url) + '">' + escapeHtml(item.title || item.url) + '</div>' +
        '<div class="meta">' + escapeHtml(site) + ' / ' + escapeHtml(status) + ' / ' + progress.toFixed(1) + '%</div>' +
        '<div class="progress"><span style="width:' + progress + '%"></span></div></div>' +
        '<div class="actions"><span class="status ' + escapeHtml(status) + '">' + escapeHtml(status) + '</span>' + action + '</div></li>';
    }).join('');
  }

  function loadQueue() {
    if (draggingId) return;
    fetch('/health', { headers: { 'X-MDL-Client': 'MediaDL' } })
      .then(function (response) { if (!response.ok) throw new Error('Health check failed'); return response.json(); })
      .then(function (health) {
        token = health.token || '';
        return fetch('/queue', { headers: headers() });
      })
      .then(function (response) { if (!response.ok) throw new Error('Queue request failed'); return response.json(); })
      .then(function (payload) {
        var items = Array.isArray(payload.downloads) ? payload.downloads : [];
        render(items);
        updated.textContent = items.length + ' item' + (items.length === 1 ? '' : 's') + ' / updated ' + new Date().toLocaleTimeString();
        setNotice('Drag the handle on an item to change its priority.');
      })
      .catch(function (error) { setNotice(error.message + '. Is the MediaDL server running?', true); });
  }

  function persistOrder() {
    var ids = Array.prototype.map.call(list.querySelectorAll('.queue-item'), function (item) { return item.getAttribute('data-id'); });
    fetch('/queue/reorder', { method: 'POST', headers: Object.assign({ 'Content-Type': 'application/json' }, headers()), body: JSON.stringify({ ids: ids }) })
      .then(function (response) { if (!response.ok) throw new Error('Could not save queue order'); return response.json(); })
      .then(function () { setNotice('Queue order saved.'); loadQueue(); })
      .catch(function (error) { setNotice(error.message, true); loadQueue(); });
  }

  function runAction(action, id) {
    var method = action === 'cancel' ? 'DELETE' : 'POST';
    var endpoint = '/' + action + '/' + encodeURIComponent(id);
    fetch(endpoint, { method: method, headers: headers() })
      .then(function (response) { if (!response.ok) throw new Error('Action failed'); return response.json(); })
      .then(loadQueue)
      .catch(function (error) { setNotice(error.message, true); });
  }

  list.addEventListener('click', function (event) {
    var button = event.target.closest('button[data-action]');
    if (!button) return;
    event.preventDefault();
    event.stopPropagation();
    runAction(button.getAttribute('data-action'), button.getAttribute('data-id'));
  });
  list.addEventListener('dragstart', function (event) {
    var item = event.target.closest('.queue-item');
    if (!item) return;
    draggingId = item.getAttribute('data-id');
    item.classList.add('dragging');
    event.dataTransfer.effectAllowed = 'move';
    event.dataTransfer.setData('text/plain', draggingId);
  });
  list.addEventListener('dragover', function (event) {
    event.preventDefault();
    var target = event.target.closest('.queue-item');
    var dragging = list.querySelector('.queue-item.dragging');
    if (!target || !dragging || target === dragging) return;
    var after = event.clientY > target.getBoundingClientRect().top + target.offsetHeight / 2;
    list.insertBefore(dragging, after ? target.nextSibling : target);
  });
  list.addEventListener('drop', function (event) { event.preventDefault(); if (draggingId) persistOrder(); });
  list.addEventListener('dragend', function () {
    var dragging = list.querySelector('.queue-item.dragging');
    if (dragging) dragging.classList.remove('dragging');
    draggingId = '';
  });
  document.getElementById('refresh').addEventListener('click', loadQueue);
  loadQueue();
  window.setInterval(loadQueue, 3000);
}());
</script>
</body>
</html>
"@
            $buf = [System.Text.Encoding]::UTF8.GetBytes($html)
            $ctx.Response.StatusCode = 200
            $ctx.Response.ContentType = "text/html; charset=utf-8"
            $ctx.Response.Headers.Add("Cache-Control", "no-store")
            $ctx.Response.Headers.Add("X-Content-Type-Options", "nosniff")
            $ctx.Response.ContentLength64 = $buf.Length
            try { $ctx.Response.OutputStream.Write($buf,0,$buf.Length); $ctx.Response.OutputStream.Close() } catch {}
        }

        # ── Auto-update yt-dlp ──
        if ($config.AutoUpdateYtDlp -eq $true) {
            try { Start-Process -FilePath $config.YtDlpPath -ArgumentList "-U" -NoNewWindow -ErrorAction SilentlyContinue } catch {}
            Write-SLog "yt-dlp auto-update triggered"
        }

        Initialize-QueueDb
        Restore-QueueEntries

        # ── Start listener ──
        $listener = New-Object System.Net.HttpListener
        $listener.Prefixes.Add("http://127.0.0.1:$PORT/")
        try { $listener.Start() } catch { Write-SLog "FATAL: Cannot start on port $PORT"; $state.Running = $false; return }
        $state.Running = $true
        $state.Log = ""
        Write-SLog "Server listening on port $PORT"
        Start-PipeRequestPump (if ($config.NamedPipeName -and "$($config.NamedPipeName)" -match '^[A-Za-z0-9._-]{1,64}$') { "$($config.NamedPipeName)" } else { 'MediaDL' }) | Out-Null

        while ($listener.IsListening -and -not $state.ShouldStop) {
            try {
                Process-PipeRequests
                $result = $listener.BeginGetContext($null,$null)
                while (-not $result.AsyncWaitHandle.WaitOne(500)) {
                    Update-Downloads
                    Process-PipeRequests
                    if ($state.ShouldStop) { break }
                }
                if ($state.ShouldStop) { break }
                $ctx = $listener.EndGetContext($result)
                $method = $ctx.Request.HttpMethod
                $path = $ctx.Request.Url.AbsolutePath.TrimEnd('/')

                if ($method -eq 'OPTIONS') { Send-Json $ctx @{ok=$true}; continue }
                if ($path -ne '/health' -and $path -ne '/ui') {
                    if ($ctx.Request.Headers["X-Auth-Token"] -ne $state.Token) { Send-Json $ctx @{error="Unauthorized"} 401; continue }
                }

                switch -Regex ($path) {
                    '^/ui$' { Send-QueueUi $ctx }
                    '^/health$' {
                        $active = @($state.Downloads.Values | Where-Object { $_.status -match 'downloading|merging|extracting' }).Count
                        $resp = @{status="ok";version="5.0.0";port=$PORT;downloads=$active;token_required=$true}
                        if ($ctx.Request.Headers["X-MDL-Client"] -eq "MediaDL") { $resp.token = $state.Token }
                        Send-Json $ctx $resp
                    }
                    '^/download$' {
                        if ($method -ne 'POST') { Send-Json $ctx @{error="Method not allowed"} 405; break }
                        $body = Read-Body $ctx.Request
                        if (-not $body) { Send-Json $ctx @{error="Empty body"} 400; break }
                        try { $p = $body | ConvertFrom-Json } catch { Send-Json $ctx @{error="Invalid JSON"} 400; break }
                        if (-not $p.url) { Send-Json $ctx @{error="Missing url"} 400; break }
                        $identity = Get-DownloadIdentity -Url $p.url -SourceUrl $p.sourceUrl -VideoId $p.videoId -ChannelId $p.channelId -Site $p.site -AudioOnly ($p.audioOnly -eq $true)
                        $duplicate = Find-QueueDuplicate $identity.key
                        if ($duplicate) {
                            Send-Json $ctx @{error="Duplicate download";duplicateId=$duplicate.id;contentKey=$identity.key;title=$duplicate.title} 409
                            break
                        }
                        $active = @($state.Downloads.Values | Where-Object { $_.status -match 'downloading|merging|extracting' }).Count
                        if ($active -ge $MAX_CONCURRENT) { Send-Json $ctx @{error="Too many concurrent downloads";active=$active} 429; break }
                        $site = Get-SiteKey $p.url
                        $siteActive = Get-ActiveSiteCount $site
                        if ($siteActive -ge $SITE_CONCURRENCY_CAP) {
                            Send-Json $ctx @{error="Per-site concurrency limit reached";site=$site;active=$siteActive;limit=$SITE_CONCURRENCY_CAP} 429
                            break
                        }
                        $id = Start-Download $p
                        Send-Json $ctx @{id=$id;status="downloading"}
                    }
                    '^/status/(.+)$' {
                        $sid = $matches[1]; Update-Downloads
                        if ($state.Downloads.ContainsKey($sid)) {
                            $dl = $state.Downloads[$sid]
                            Send-Json $ctx @{id=$dl.id;status=$dl.status;progress=[math]::Round($dl.progress,1);speed=$dl.speed;eta=$dl.eta;title=$dl.title;filename=$dl.filename}
                        } else { Send-Json $ctx @{error="Not found"} 404 }
                    }
                    '^/queue/reorder$' {
                        if ($method -ne 'POST') { Send-Json $ctx @{error="Method not allowed"} 405; break }
                        $body = Read-Body $ctx.Request
                        if (-not $body) { Send-Json $ctx @{error="Empty body"} 400; break }
                        try { $payload = $body | ConvertFrom-Json } catch { Send-Json $ctx @{error="Invalid JSON"} 400; break }
                        if (-not ($payload.PSObject.Properties.Name -contains 'ids')) { Send-Json $ctx @{error="Missing ids"} 400; break }
                        $orderedIds = [System.Collections.Generic.List[string]]::new()
                        $seen = @{}
                        foreach ($queueId in @($payload.ids)) {
                            $key = "$queueId"
                            if ($key -and $state.Downloads.ContainsKey($key) -and -not $seen.ContainsKey($key)) {
                                $seen[$key] = $true
                                $orderedIds.Add($key)
                            }
                        }
                        foreach ($dl in @($state.Downloads.Values | Sort-Object priority,startTime)) {
                            $key = "$($dl.id)"
                            if (-not $seen.ContainsKey($key)) { $seen[$key] = $true; $orderedIds.Add($key) }
                        }
                        for ($i = 0; $i -lt $orderedIds.Count; $i++) {
                            $dl = $state.Downloads[$orderedIds[$i]]
                            $dl.priority = $i
                            Save-QueueRecord $dl
                        }
                        Send-Json $ctx @{updated=$true;count=$orderedIds.Count}
                    }
                    '^/queue$' {
                        $list = @(); foreach ($dl in @($state.Downloads.Values | Sort-Object priority,startTime)) { $list += @{id=$dl.id;status=$dl.status;progress=[math]::Round($dl.progress,1);title=$dl.title;speed=$dl.speed;eta=$dl.eta;priority=[int]$dl.priority;site=(Get-SiteKey $dl.url);videoId=$dl.videoId;channelId=$dl.channelId} }
                        Send-Json $ctx @{downloads=$list;count=$list.Count}
                    }
                    '^/history$' {
                        $h = @(); if (Test-Path $state.HistoryPath) { try { $h = @(Get-Content $state.HistoryPath -Raw | ConvertFrom-Json) } catch {} }
                        $lp = $ctx.Request.QueryString["limit"]; if ($lp -match '^\d+$') { $n=[int]$lp; if ($h.Count -gt $n) { $h=$h[-$n..-1] } }
                        Send-Json $ctx @{history=$h;count=$h.Count}
                    }
                    '^/config$' {
                        if ($method -eq 'GET') {
                            Send-Json $ctx @{downloadPath=$config.DownloadPath;audioDownloadPath=$config.AudioDownloadPath;musicFolder=$config.MusicFolder;postProcessAudio=$config.PostProcessAudio;postProcessMusicBrainz=$config.PostProcessMusicBrainz;sitePresets=$config.SitePresets;embedMetadata=$config.EmbedMetadata;embedThumbnail=$config.EmbedThumbnail;embedChapters=$config.EmbedChapters;splitChapters=$config.SplitChapters;embedSubs=$config.EmbedSubs;subtitleSrt=$config.SubtitleSrt;hardwareEncoder=$config.HardwareEncoder;namedPipeName=$config.NamedPipeName;toastNotifications=$config.ToastNotifications;subLangs=$config.SubLangs;sponsorBlock=$config.SponsorBlock;concurrentFragments=$config.ConcurrentFragments;bandwidthLimitKbps=$config.BandwidthLimitKbps;siteConcurrencyCap=$config.SiteConcurrencyCap;downloadArchive=$config.DownloadArchive;rateLimit=$config.RateLimit;proxy=$config.Proxy;videoFormats=@('mp4','mkv','webm');audioFormats=@('mp3','m4a','opus','flac','wav');qualities=@('best','2160','1440','1080','720','480')}
                        } else { Send-Json $ctx @{error="Use GUI settings"} 405 }
                    }
                    '^/pause/(.+)$' {
                        if ($method -ne 'POST') { Send-Json $ctx @{error="Method not allowed"} 405; break }
                        $pauseId = $matches[1]
                        if (-not $state.Downloads.ContainsKey($pauseId)) { Send-Json $ctx @{error="Not found"} 404; break }
                        $dl = $state.Downloads[$pauseId]
                        if ($dl.status -eq 'paused') { Send-Json $ctx @{id=$pauseId;status="paused"}; break }
                        if ($dl.status -match 'complete|failed|cancelled' -or -not $dl.process) { Send-Json $ctx @{error="Download cannot be paused";status=$dl.status} 409; break }
                        if (Set-DownloadSuspended $dl $true) {
                            $dl.status = "paused"; Save-QueueRecord $dl
                            Send-Json $ctx @{id=$pauseId;status="paused"}
                        } else { Send-Json $ctx @{error="Could not suspend download"} 500 }
                    }
                    '^/resume/(.+)$' {
                        if ($method -ne 'POST') { Send-Json $ctx @{error="Method not allowed"} 405; break }
                        $resumeId = $matches[1]
                        if (-not $state.Downloads.ContainsKey($resumeId)) { Send-Json $ctx @{error="Not found"} 404; break }
                        $dl = $state.Downloads[$resumeId]
                        if ($dl.status -ne 'paused') { Send-Json $ctx @{id=$resumeId;status=$dl.status} ; break }
                        if (Set-DownloadSuspended $dl $false) {
                            $dl.status = "downloading"; Save-QueueRecord $dl
                            Send-Json $ctx @{id=$resumeId;status="downloading"}
                        } else { Send-Json $ctx @{error="Could not resume download"} 500 }
                    }
                    '^/cancel/(.+)$' {
                        if ($method -ne 'DELETE') { Send-Json $ctx @{error="Method not allowed"} 405; break }
                        $cid = $matches[1]
                        if ($state.Downloads.ContainsKey($cid)) {
                            $dl = $state.Downloads[$cid]
                            if ($dl.process -and -not $dl.process.HasExited) { try { $dl.process.Kill() } catch {} }
                            $dl.status = "cancelled"
                            Save-QueueRecord $dl
                            Send-Json $ctx @{id=$cid;cancelled=$true}
                        } else { Send-Json $ctx @{error="Not found"} 404 }
                    }
                    '^/shutdown$' { Write-SLog "Shutdown requested"; Send-Json $ctx @{status="shutting_down"}; $state.ShouldStop = $true }
                    default { Send-Json $ctx @{error="Not found"} 404 }
                }
            } catch { Start-Sleep -Milliseconds 200 }
        }

        # Cleanup
        if ($script:NamedPipeHost) { $script:NamedPipeHost.Stop(); $script:NamedPipeHost = $null }
        foreach ($dl in $state.Downloads.Values) {
            if ($dl.process -and -not $dl.process.HasExited) {
                $dl.status = "interrupted"
                Save-QueueRecord $dl
                try { $dl.process.Kill() } catch {}
            }
        }
        try { $listener.Stop(); $listener.Close() } catch {}
        $state.Running = $false
        Write-SLog "Server stopped"
    }) | Out-Null

    $script:ServerRunspace = $rs
    $script:ServerPipeline = $ps
    $script:ServerState.Log = ""
    $ps.BeginInvoke() | Out-Null

    Write-Log "Server runspace started"
    Update-ServerUI
}

function Stop-Server {
    $script:ServerState.ShouldStop = $true
    # Wait briefly for clean shutdown
    $deadline = (Get-Date).AddSeconds(3)
    while ($script:ServerState.Running -and (Get-Date) -lt $deadline) {
        $window.Dispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
        Start-Sleep -Milliseconds 100
    }
    if ($script:ServerPipeline) {
        try { $script:ServerPipeline.Stop() } catch {}
        try { $script:ServerPipeline.Dispose() } catch {}
    }
    if ($script:ServerRunspace) {
        try { $script:ServerRunspace.Close() } catch {}
    }
    $script:ServerState.Running = $false
    $script:ServerState.StartTime = $null
    Update-ServerUI
}

function Update-ServerUI {
    if ($script:ServerState.Running) {
        $statusDot.Fill = [Windows.Media.BrushConverter]::new().ConvertFromString("#22c55e")
        $statusLabel.Text = "Running"
        $dashStatus.Text = "Server Running"
        $btnStartStop.Content = "Stop Server"
        $btnStartStop.Background = [Windows.Media.BrushConverter]::new().ConvertFromString("#ef4444")
        $trayStartStop.Text = "Stop Server"
        $trayIcon.Text = "MediaDL Server - Running"
    } else {
        $statusDot.Fill = [Windows.Media.BrushConverter]::new().ConvertFromString("#525a65")
        $statusLabel.Text = "Stopped"
        $dashStatus.Text = "Server Stopped"
        $btnStartStop.Content = "Start Server"
        $btnStartStop.Background = [Windows.Media.BrushConverter]::new().ConvertFromString("#22c55e")
        $trayStartStop.Text = "Start Server"
        $trayIcon.Text = "MediaDL Server - Stopped"
    }
}

# ══════════════════════════════════════════════════════════════
# EVENT HANDLERS
# ══════════════════════════════════════════════════════════════

$btnStartStop.Add_Click({
    if ($script:ServerState.Running) { Stop-Server } else { Start-Server }
})

$trayStartStop.Add_Click({
    if ($script:ServerState.Running) { Stop-Server } else { Start-Server }
})

$btnOpenFolder.Add_Click({
    $p = $script:Config.DownloadPath
    if ($p -and (Test-Path $p)) { Start-Process explorer.exe -ArgumentList $p }
    else { Start-Process explorer.exe -ArgumentList $script:InstallPath }
})

# Browse buttons
$btnBrowseDl.Add_Click({
    $d = New-Object System.Windows.Forms.FolderBrowserDialog
    $d.SelectedPath = $cfgDownloadPath.Text
    if ($d.ShowDialog() -eq 'OK') { $cfgDownloadPath.Text = $d.SelectedPath }
})
$btnBrowseAudio.Add_Click({
    $d = New-Object System.Windows.Forms.FolderBrowserDialog
    $d.SelectedPath = $cfgAudioPath.Text
    if ($d.ShowDialog() -eq 'OK') { $cfgAudioPath.Text = $d.SelectedPath }
})

# Save settings
$btnSaveSettings.Add_Click({
    $script:Config.DownloadPath = $cfgDownloadPath.Text
    $script:Config.AudioDownloadPath = $cfgAudioPath.Text
    $script:Config.EmbedMetadata = $cfgEmbedMetadata.IsChecked
    $script:Config.EmbedThumbnail = $cfgEmbedThumbnail.IsChecked
    $script:Config.EmbedChapters = $cfgEmbedChapters.IsChecked
    $script:Config.SplitChapters = $cfgSplitChapters.IsChecked
    $script:Config.PostProcessAudio = $cfgPostProcessAudio.IsChecked
    $script:Config.PostProcessMusicBrainz = $cfgPostProcessMusicBrainz.IsChecked
    $musicFolder = "$($cfgMusicFolder.Text)".Trim()
    if ($musicFolder -match '^[A-Za-z]:\\' -and $musicFolder -notmatch '\.\.' -and $musicFolder.Length -le 260) {
        $script:Config.MusicFolder = $musicFolder
    }
    $presetJson = "$($cfgSitePresets.Text)".Trim()
    try {
        $parsedPresets = if ($presetJson) { $presetJson | ConvertFrom-Json } else { [pscustomobject]@{} }
        if ($parsedPresets -is [array]) { throw "Site presets must be a JSON object" }
        $script:Config.SitePresets = $parsedPresets
    } catch {
        [System.Windows.MessageBox]::Show("Site format presets are not valid JSON: $($_.Exception.Message)", "MediaDL settings") | Out-Null
        return
    }
    $script:Config.EmbedSubs = $cfgEmbedSubs.IsChecked
    $script:Config.SubtitleSrt = $cfgSubtitleSrt.IsChecked
    $script:Config.HardwareEncoder = @('none','nvenc','qsv')[[Math]::Max(0, [Math]::Min(2, [int]$cfgHardwareEncoder.SelectedIndex))]
    $script:Config.SubLangs = $cfgSubLangs.Text
    $script:Config.SponsorBlock = $cfgSponsorBlock.IsChecked
    $v = 0; if ([int]::TryParse($cfgFragments.Text, [ref]$v) -and $v -ge 1 -and $v -le 32) { $script:Config.ConcurrentFragments = $v }
    $script:Config.RateLimit = $cfgRateLimit.Text
    $script:Config.BandwidthLimitKbps = [int][Math]::Max(0, [Math]::Min(10000, $cfgBandwidth.Value))
    $script:Config.SiteConcurrencyCap = [int][Math]::Max(1, [Math]::Min(8, $cfgSiteConcurrency.Value))
    $script:Config.Proxy = $cfgProxy.Text
    $script:Config.AutoUpdateYtDlp = $cfgAutoUpdate.IsChecked
    $script:Config.ToastNotifications = $cfgToastNotifications.IsChecked
    $script:Config.DownloadArchive = $cfgArchive.IsChecked
    $script:Config.CloseToTray = $cfgCloseToTray.IsChecked
    $script:Config.StartMinimized = $cfgStartMinimized.IsChecked
    Save-Config
    $script:ServerState.Config = $script:Config
    $btnSaveSettings.Content = "Saved!"
    $window.Dispatcher.BeginInvoke([action]{ Start-Sleep -Milliseconds 1500; $btnSaveSettings.Content = "Save Settings" })
})

# Clear history
$btnClearHistory.Add_Click({
    "[]" | Set-Content $script:HistoryPath -Encoding UTF8
    Refresh-History
})

# ── History refresh ──
function Refresh-History {
    $historyList.Children.Clear()
    $history = @()
    if (Test-Path $script:HistoryPath) {
        try { $history = @(Get-Content $script:HistoryPath -Raw | ConvertFrom-Json) } catch {}
    }
    if ($history.Count -eq 0) {
        $t = New-Object System.Windows.Controls.TextBlock
        $t.Text = "No downloads yet."
        $t.FontSize = 13
        $t.Foreground = [Windows.Media.BrushConverter]::new().ConvertFromString("#525a65")
        $historyList.Children.Add($t)
        return
    }
    [array]::Reverse($history)
    $shown = [Math]::Min($history.Count, 50)
    for ($i = 0; $i -lt $shown; $i++) {
        $h = $history[$i]
        $card = New-Object System.Windows.Controls.Border
        $card.Background = [Windows.Media.BrushConverter]::new().ConvertFromString("#151b23")
        $card.BorderBrush = [Windows.Media.BrushConverter]::new().ConvertFromString("#2a3140")
        $card.BorderThickness = [System.Windows.Thickness]::new(1)
        $card.CornerRadius = [System.Windows.CornerRadius]::new(8)
        $card.Padding = [System.Windows.Thickness]::new(12,8,12,8)
        $card.Margin = [System.Windows.Thickness]::new(0,0,0,6)

        $sp = New-Object System.Windows.Controls.StackPanel
        $titleTb = New-Object System.Windows.Controls.TextBlock
        $titleTb.Text = "$($h.title)"
        $titleTb.FontSize = 12; $titleTb.FontWeight = "SemiBold"
        $titleTb.Foreground = [Windows.Media.BrushConverter]::new().ConvertFromString("#e6edf3")
        $titleTb.TextTrimming = "CharacterEllipsis"
        $sp.Children.Add($titleTb)

        $metaTb = New-Object System.Windows.Controls.TextBlock
        $metaTb.Text = "$($h.date)  |  $($h.format)  |  $($h.quality)  |  $($h.duration)s"
        $metaTb.FontSize = 10
        $metaTb.Foreground = [Windows.Media.BrushConverter]::new().ConvertFromString("#525a65")
        $metaTb.Margin = [System.Windows.Thickness]::new(0,2,0,0)
        $sp.Children.Add($metaTb)

        $card.Child = $sp
        $historyList.Children.Add($card)
    }
}

# ══════════════════════════════════════════════════════════════
# UI TIMER (updates dashboard every 500ms)
# ══════════════════════════════════════════════════════════════
$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromMilliseconds(500)
$timer.Add_Tick({
    Update-ServerUI

    # Stats
    $active = @($script:ServerState.Downloads.Values | Where-Object { $_.status -match 'downloading|merging|extracting' }).Count
    $statActive.Text = "$active"
    $statCompleted.Text = "$($script:ServerState.TotalCompleted)"

    if ($script:ServerState.StartTime) {
        $up = (Get-Date) - $script:ServerState.StartTime
        if ($up.TotalHours -ge 1) { $statUptime.Text = "{0:0}h" -f $up.TotalHours }
        elseif ($up.TotalMinutes -ge 1) { $statUptime.Text = "{0:0}m" -f $up.TotalMinutes }
        else { $statUptime.Text = "{0:0}s" -f $up.TotalSeconds }
    } else { $statUptime.Text = "--" }

    # Log
    if ($script:ServerState.Log) {
        $logText.Text += $script:ServerState.Log
        $script:ServerState.Log = ""
        # Trim to last 2000 chars
        if ($logText.Text.Length -gt 2000) { $logText.Text = $logText.Text.Substring($logText.Text.Length - 2000) }
        $logScroll.ScrollToEnd()
    }

    # Active downloads list
    $dls = @($script:ServerState.Downloads.Values | Where-Object { $_.status -notmatch 'complete|failed|cancelled' })
    if ($dls.Count -eq 0) {
        if ($downloadsList.Children.Count -ne 1 -or $downloadsList.Children[0] -ne $noDownloads) {
            $downloadsList.Children.Clear()
            $downloadsList.Children.Add($noDownloads)
        }
    } else {
        $downloadsList.Children.Clear()
        foreach ($dl in $dls) {
            $card = New-Object System.Windows.Controls.Border
            $card.Background = [Windows.Media.BrushConverter]::new().ConvertFromString("#151b23")
            $card.BorderBrush = [Windows.Media.BrushConverter]::new().ConvertFromString("#2a3140")
            $card.BorderThickness = [System.Windows.Thickness]::new(1)
            $card.CornerRadius = [System.Windows.CornerRadius]::new(10)
            $card.Padding = [System.Windows.Thickness]::new(14,10,14,10)
            $card.Margin = [System.Windows.Thickness]::new(0,0,0,8)

            $sp = New-Object System.Windows.Controls.StackPanel

            $titleTb = New-Object System.Windows.Controls.TextBlock
            $titleTb.Text = "$($dl.title)"
            $titleTb.FontSize = 13; $titleTb.FontWeight = "SemiBold"
            $titleTb.Foreground = [Windows.Media.BrushConverter]::new().ConvertFromString("#e6edf3")
            $titleTb.TextTrimming = "CharacterEllipsis"
            $sp.Children.Add($titleTb)

            # Progress bar
            $barBg = New-Object System.Windows.Controls.Border
            $barBg.Background = [Windows.Media.BrushConverter]::new().ConvertFromString("#1a2028")
            $barBg.CornerRadius = [System.Windows.CornerRadius]::new(4)
            $barBg.Height = 6
            $barBg.Margin = [System.Windows.Thickness]::new(0,6,0,4)
            $barFill = New-Object System.Windows.Controls.Border
            $barFill.Background = [Windows.Media.BrushConverter]::new().ConvertFromString("#22c55e")
            $barFill.CornerRadius = [System.Windows.CornerRadius]::new(4)
            $barFill.HorizontalAlignment = "Left"
            $pct = [Math]::Min([Math]::Max($dl.progress, 0), 100)
            $barFill.Width = [Math]::Max(($pct / 100.0) * 400, 0)
            $barBg.Child = $barFill
            $sp.Children.Add($barBg)

            $metaTb = New-Object System.Windows.Controls.TextBlock
            $metaTb.Text = "$([math]::Round($dl.progress,1))%  |  $($dl.speed)  |  ETA $($dl.eta)  |  $($dl.status)"
            $metaTb.FontSize = 10
            $metaTb.Foreground = [Windows.Media.BrushConverter]::new().ConvertFromString("#8b949e")
            $sp.Children.Add($metaTb)

            $card.Child = $sp
            $downloadsList.Children.Add($card)
        }
    }
})
$timer.Start()

# ══════════════════════════════════════════════════════════════
# NAMED PIPE (single instance show-window IPC)
# ══════════════════════════════════════════════════════════════
$pipeRunspace = [runspacefactory]::CreateRunspace()
$pipeRunspace.Open()
$pipeRunspace.SessionStateProxy.SetVariable('dispatcher', $window.Dispatcher)
$pipeRunspace.SessionStateProxy.SetVariable('window', $window)
$pipePipeline = [powershell]::Create()
$pipePipeline.Runspace = $pipeRunspace
$pipePipeline.AddScript({
    while ($true) {
        try {
            $pipe = New-Object System.IO.Pipes.NamedPipeServerStream('MediaDL-Show', [System.IO.Pipes.PipeDirection]::In)
            $pipe.WaitForConnection()
            $pipe.ReadByte() | Out-Null
            $pipe.Close()
            $dispatcher.Invoke([action]{
                $window.Show()
                $window.WindowState = [System.Windows.WindowState]::Normal
                $window.Activate()
            })
        } catch { Start-Sleep -Seconds 1 }
    }
}) | Out-Null
$pipePipeline.BeginInvoke() | Out-Null

# ══════════════════════════════════════════════════════════════
# STARTUP
# ══════════════════════════════════════════════════════════════

# Auto-start server
Start-Server

# Handle -Background flag or StartMinimized config
if ($Background -or $script:Config.StartMinimized -eq $true) {
    $window.WindowState = [System.Windows.WindowState]::Minimized
    $window.ShowInTaskbar = $false
    $window.Hide()
}

# Set window icon if available
$iconPath = Join-Path $PSScriptRoot "icon.ico"
if (Test-Path $iconPath) {
    try { $window.Icon = [System.Windows.Media.Imaging.BitmapFrame]::Create([System.Uri]::new($iconPath)) } catch {}
}

$window.ShowDialog() | Out-Null

# ── Cleanup ──
$timer.Stop()
Stop-Server
$trayIcon.Visible = $false
$trayIcon.Dispose()
try { $pipePipeline.Stop(); $pipePipeline.Dispose(); $pipeRunspace.Close() } catch {}
$mutex.ReleaseMutex()
$mutex.Dispose()
