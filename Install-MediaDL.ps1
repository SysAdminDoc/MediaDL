<#
.SYNOPSIS
    MediaDL Installer - Professional setup wizard for universal media downloading
.DESCRIPTION
    Installs and configures:
    - yt-dlp (auto-download)
    - ffmpeg (auto-download)
    - Download protocol handler (ytdl://)
    - Userscript for 1800+ site support
.NOTES
    Author: SysAdminDoc
    Version: 1.0.0
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
$script:InstallPath = "$env:LOCALAPPDATA\MediaDL"
$script:YtDlpUrl = "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"
$script:DefaultDownloadPath = "$env:USERPROFILE\Videos\MediaDL"
$script:GitHubRepo = "https://github.com/SysAdminDoc/MediaDL"
$script:UserscriptUrl = "https://github.com/SysAdminDoc/MediaDL/raw/refs/heads/main/MediaDL.user.js"

# Browser icon URLs
$script:BrowserIcons = @{
    Chrome  = "https://raw.githubusercontent.com/AbuCarlo/browser-icons/master/icons/google-chrome.png"
    Firefox = "https://raw.githubusercontent.com/AbuCarlo/browser-icons/master/icons/mozilla-firefox.png"
    Edge    = "https://raw.githubusercontent.com/AbuCarlo/browser-icons/master/icons/microsoft-edge.png"
    Safari  = "https://raw.githubusercontent.com/AbuCarlo/browser-icons/master/icons/apple-safari.png"
    Opera   = "https://raw.githubusercontent.com/AbuCarlo/browser-icons/master/icons/opera.png"
}

# Userscript manager links by browser
$script:UserscriptManagers = @{
    Chrome = @{
        Tampermonkey = "https://chromewebstore.google.com/detail/tampermonkey/dhdgffkkebhmkfjojejmpbldmpobfkfo"
        Violentmonkey = "https://chrome.google.com/webstore/detail/violent-monkey/jinjaccalgkegednnccohejagnlnfdag"
    }
    Firefox = @{
        Tampermonkey = "https://addons.mozilla.org/en-US/firefox/addon/tampermonkey/"
        Greasemonkey = "https://addons.mozilla.org/en-US/firefox/addon/greasemonkey/"
        Violentmonkey = "https://addons.mozilla.org/firefox/addon/violentmonkey/"
    }
    Edge = @{
        Tampermonkey = "https://microsoftedge.microsoft.com/addons/detail/tampermonkey/iikmkjmpaadaobahmlepeloendndfphd"
        Violentmonkey = "https://microsoftedge.microsoft.com/addons/detail/eeagobfjdenkkddmbclomhiblgggliao"
    }
    Safari = @{
        Tampermonkey = "https://apps.apple.com/us/app/tampermonkey/id6738342400"
    }
    Opera = @{
        Tampermonkey = "https://addons.opera.com/en/extensions/details/tampermonkey-beta/"
    }
}

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
function Get-BitmapImageFromUrl {
    param([string]$Url)
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "Mozilla/5.0")
        $imageData = $webClient.DownloadData($Url)
        $webClient.Dispose()
        
        $stream = New-Object System.IO.MemoryStream(,$imageData)
        $bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
        $bitmap.BeginInit()
        $bitmap.StreamSource = $stream
        $bitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        $bitmap.EndInit()
        $bitmap.Freeze()
        return $bitmap
    } catch {
        return $null
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
    Remove-Item -Path "HKCU:\Software\Classes\ytdl" -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path $script:InstallPath) {
        Remove-Item -Path $script:InstallPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    $shortcutPath = "$env:USERPROFILE\Desktop\MediaDL Download.lnk"
    if (Test-Path $shortcutPath) {
        Remove-Item $shortcutPath -Force -ErrorAction SilentlyContinue
    }
}

Uninstall-Previous

# ============================================
# XAML GUI DEFINITION
# ============================================
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="MediaDL Setup" Height="820" Width="900"
        WindowStartupLocation="CenterScreen" ResizeMode="CanMinimize"
        Background="#0a0a0a">
    <Window.Resources>
        <SolidColorBrush x:Key="BgDark" Color="#0a0a0a"/>
        <SolidColorBrush x:Key="BgCard" Color="#141414"/>
        <SolidColorBrush x:Key="BgHover" Color="#1f1f1f"/>
        <SolidColorBrush x:Key="Border" Color="#2a2a2a"/>
        <SolidColorBrush x:Key="TextPrimary" Color="#fafafa"/>
        <SolidColorBrush x:Key="TextSecondary" Color="#a1a1aa"/>
        <SolidColorBrush x:Key="TextMuted" Color="#71717a"/>
        <SolidColorBrush x:Key="AccentGreen" Color="#00b894"/>
        <SolidColorBrush x:Key="AccentGreenHover" Color="#00a085"/>
        <SolidColorBrush x:Key="AccentPurple" Color="#6c5ce7"/>
        <SolidColorBrush x:Key="AccentRed" Color="#ef4444"/>
        
        <Style x:Key="BaseButton" TargetType="Button">
            <Setter Property="Background" Value="{StaticResource AccentGreen}"/>
            <Setter Property="Foreground" Value="#0a0a0a"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="24,12"/>
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
        
        <Style x:Key="SecondaryButton" TargetType="Button" BasedOn="{StaticResource BaseButton}">
            <Setter Property="Background" Value="{StaticResource BgCard}"/>
            <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
            <Setter Property="BorderBrush" Value="{StaticResource Border}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="8" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="{StaticResource BgHover}"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        
        <Style x:Key="DangerButton" TargetType="Button" BasedOn="{StaticResource BaseButton}">
            <Setter Property="Background" Value="{StaticResource AccentRed}"/>
            <Setter Property="Foreground" Value="White"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#dc2626"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        
        <Style x:Key="BrowserButton" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Width" Value="72"/>
            <Setter Property="Height" Value="72"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{StaticResource BgCard}" BorderBrush="{StaticResource Border}" BorderThickness="2" CornerRadius="12" Padding="12">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="BorderBrush" Value="{StaticResource AccentGreen}"/>
                                <Setter TargetName="border" Property="Background" Value="{StaticResource BgHover}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="{StaticResource BgCard}"/>
            <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
            <Setter Property="BorderBrush" Value="{StaticResource Border}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="12,10"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="CaretBrush" Value="{StaticResource TextPrimary}"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TextBox">
                        <Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="8">
                            <ScrollViewer x:Name="PART_ContentHost" Margin="{TemplateBinding Padding}"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsFocused" Value="True">
                    <Setter Property="BorderBrush" Value="{StaticResource AccentGreen}"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="CheckBox">
                        <StackPanel Orientation="Horizontal">
                            <Border x:Name="checkbox" Width="20" Height="20" Background="{StaticResource BgCard}" BorderBrush="{StaticResource Border}" BorderThickness="2" CornerRadius="4" VerticalAlignment="Center">
                                <Path x:Name="checkmark" Data="M3,7 L6,10 L11,4" Stroke="{StaticResource AccentGreen}" StrokeThickness="2" Visibility="Collapsed" Margin="2"/>
                            </Border>
                            <ContentPresenter Margin="10,0,0,0" VerticalAlignment="Center"/>
                        </StackPanel>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="checkmark" Property="Visibility" Value="Visible"/>
                                <Setter TargetName="checkbox" Property="BorderBrush" Value="{StaticResource AccentGreen}"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="checkbox" Property="BorderBrush" Value="{StaticResource AccentGreen}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>
    
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <!-- Header -->
        <Border Grid.Row="0" Background="{StaticResource BgCard}" BorderBrush="{StaticResource Border}" BorderThickness="0,0,0,1">
            <Grid Margin="32,24">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <Border Grid.Column="0" Width="60" Height="60" CornerRadius="12" Background="{StaticResource AccentGreen}" Margin="0,0,20,0">
                    <TextBlock Text="M" FontSize="32" FontWeight="Bold" Foreground="#0a0a0a" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                </Border>
                <StackPanel Grid.Column="1" VerticalAlignment="Center">
                    <TextBlock Text="MediaDL Setup Wizard" FontSize="24" FontWeight="SemiBold" Foreground="{StaticResource TextPrimary}" FontFamily="Segoe UI"/>
                    <TextBlock Text="Download videos and audio from 1800+ sites" FontSize="14" Foreground="{StaticResource TextSecondary}" FontFamily="Segoe UI" Margin="0,4,0,0"/>
                </StackPanel>
                <TextBlock Grid.Column="2" Text="v1.0.0" FontSize="12" Foreground="{StaticResource TextMuted}" VerticalAlignment="Top" FontFamily="Segoe UI Semibold"/>
            </Grid>
        </Border>
        
        <!-- Main Content -->
        <TabControl x:Name="tabWizard" Grid.Row="1" Background="Transparent" BorderThickness="0" Padding="0">
            <TabControl.ItemContainerStyle>
                <Style TargetType="TabItem">
                    <Setter Property="Visibility" Value="Collapsed"/>
                </Style>
            </TabControl.ItemContainerStyle>
            
            <!-- Step 1 -->
            <TabItem x:Name="tabStep1">
                <Grid Margin="24,16">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    <StackPanel Grid.Row="0" Margin="0,0,0,16">
                        <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,16">
                            <Ellipse Width="32" Height="32" Fill="{StaticResource AccentGreen}"/>
                            <TextBlock Text="1" Foreground="#0a0a0a" FontWeight="Bold" FontSize="14" Margin="-22,7,0,0"/>
                            <Rectangle Width="60" Height="2" Fill="{StaticResource Border}" VerticalAlignment="Center" Margin="8,0"/>
                            <Ellipse Width="32" Height="32" Fill="{StaticResource BgCard}" Stroke="{StaticResource Border}" StrokeThickness="2"/>
                            <TextBlock Text="2" Foreground="{StaticResource TextMuted}" FontWeight="Bold" FontSize="14" Margin="-22,7,0,0"/>
                            <Rectangle Width="60" Height="2" Fill="{StaticResource Border}" VerticalAlignment="Center" Margin="8,0"/>
                            <Ellipse Width="32" Height="32" Fill="{StaticResource BgCard}" Stroke="{StaticResource Border}" StrokeThickness="2"/>
                            <TextBlock Text="3" Foreground="{StaticResource TextMuted}" FontWeight="Bold" FontSize="14" Margin="-22,7,0,0"/>
                        </StackPanel>
                        <TextBlock Text="Step 1: Install Base Tools" FontSize="20" FontWeight="SemiBold" Foreground="{StaticResource TextPrimary}" HorizontalAlignment="Center"/>
                    </StackPanel>
                    <Grid Grid.Row="1">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="16"/>
                            <ColumnDefinition Width="320"/>
                        </Grid.ColumnDefinitions>
                        <StackPanel Grid.Column="0">
                            <TextBlock Text="Download Folder" FontSize="12" Foreground="{StaticResource TextSecondary}" Margin="0,0,0,6"/>
                            <Grid Margin="0,0,0,16">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <TextBox x:Name="txtDownloadPath" Grid.Column="0" FontSize="12"/>
                                <Button x:Name="btnBrowseDownload" Content="..." Grid.Column="1" Style="{StaticResource SecondaryButton}" Margin="8,0,0,0" Padding="12,8" Width="40"/>
                            </Grid>
                            <TextBlock Text="Components to Install" FontSize="12" Foreground="{StaticResource TextSecondary}" Margin="0,0,0,8"/>
                            <Border Background="{StaticResource BgCard}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,16">
                                <StackPanel>
                                    <StackPanel Orientation="Horizontal" Margin="0,0,0,8">
                                        <Ellipse Width="8" Height="8" Fill="{StaticResource AccentGreen}" VerticalAlignment="Center" Margin="0,0,10,0"/>
                                        <TextBlock Text="yt-dlp" FontWeight="SemiBold" Foreground="{StaticResource TextPrimary}"/>
                                        <TextBlock Text=" - Download engine (1800+ sites)" Foreground="{StaticResource TextSecondary}"/>
                                    </StackPanel>
                                    <StackPanel Orientation="Horizontal" Margin="0,0,0,8">
                                        <Ellipse Width="8" Height="8" Fill="{StaticResource AccentGreen}" VerticalAlignment="Center" Margin="0,0,10,0"/>
                                        <TextBlock Text="ffmpeg" FontWeight="SemiBold" Foreground="{StaticResource TextPrimary}"/>
                                        <TextBlock Text=" - Audio/video processing" Foreground="{StaticResource TextSecondary}"/>
                                    </StackPanel>
                                    <StackPanel Orientation="Horizontal">
                                        <Ellipse Width="8" Height="8" Fill="{StaticResource AccentGreen}" VerticalAlignment="Center" Margin="0,0,10,0"/>
                                        <TextBlock Text="ytdl://" FontWeight="SemiBold" Foreground="{StaticResource TextPrimary}"/>
                                        <TextBlock Text=" - Protocol handler" Foreground="{StaticResource TextSecondary}"/>
                                    </StackPanel>
                                </StackPanel>
                            </Border>
                            <TextBlock Text="Options" FontSize="12" Foreground="{StaticResource TextSecondary}" Margin="0,0,0,8"/>
                            <Border Background="{StaticResource BgCard}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="8" Padding="16">
                                <StackPanel>
                                    <CheckBox x:Name="chkAutoUpdate" Content="Auto-update yt-dlp before downloads" IsChecked="True" Margin="0,0,0,8"/>
                                    <CheckBox x:Name="chkNotifications" Content="Show toast notifications" IsChecked="True" Margin="0,0,0,8"/>
                                    <CheckBox x:Name="chkDesktopShortcut" Content="Create desktop shortcut" IsChecked="False"/>
                                </StackPanel>
                            </Border>
                        </StackPanel>
                        <Border Grid.Column="2" Background="{StaticResource BgCard}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="8" Padding="12">
                            <Grid>
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="*"/>
                                </Grid.RowDefinitions>
                                <TextBlock Text="Installation Log" FontSize="12" Foreground="{StaticResource TextSecondary}" Margin="0,0,0,8"/>
                                <ScrollViewer x:Name="statusScroll" Grid.Row="1" VerticalScrollBarVisibility="Auto">
                                    <TextBlock x:Name="txtStatus" Text="Ready to install..." FontFamily="Cascadia Code, Consolas" FontSize="11" Foreground="{StaticResource TextMuted}" TextWrapping="Wrap"/>
                                </ScrollViewer>
                            </Grid>
                        </Border>
                    </Grid>
                    <Border Grid.Row="1" VerticalAlignment="Bottom" Height="4" Background="{StaticResource BgCard}" CornerRadius="2" Margin="0,16,0,0">
                        <Border x:Name="progressFill" HorizontalAlignment="Left" Width="0" Background="{StaticResource AccentGreen}" CornerRadius="2"/>
                    </Border>
                </Grid>
            </TabItem>
            
            <!-- Step 2 -->
            <TabItem x:Name="tabStep2">
                <Grid Margin="24,16">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    <StackPanel Grid.Row="0" Margin="0,0,0,16">
                        <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,16">
                            <Ellipse Width="32" Height="32" Fill="{StaticResource AccentGreen}"/>
                            <TextBlock Text="1" Foreground="#0a0a0a" FontWeight="Bold" FontSize="14" Margin="-22,7,0,0"/>
                            <Rectangle Width="60" Height="2" Fill="{StaticResource AccentGreen}" VerticalAlignment="Center" Margin="8,0"/>
                            <Ellipse Width="32" Height="32" Fill="{StaticResource AccentGreen}"/>
                            <TextBlock Text="2" Foreground="#0a0a0a" FontWeight="Bold" FontSize="14" Margin="-22,7,0,0"/>
                            <Rectangle Width="60" Height="2" Fill="{StaticResource Border}" VerticalAlignment="Center" Margin="8,0"/>
                            <Ellipse Width="32" Height="32" Fill="{StaticResource BgCard}" Stroke="{StaticResource Border}" StrokeThickness="2"/>
                            <TextBlock Text="3" Foreground="{StaticResource TextMuted}" FontWeight="Bold" FontSize="14" Margin="-22,7,0,0"/>
                        </StackPanel>
                        <TextBlock Text="Step 2: Install Userscript Manager" FontSize="20" FontWeight="SemiBold" Foreground="{StaticResource TextPrimary}" HorizontalAlignment="Center"/>
                    </StackPanel>
                    <StackPanel Grid.Row="1" HorizontalAlignment="Center" MaxWidth="600">
                        <TextBlock Text="Select your browser to get the appropriate userscript manager:" FontSize="14" Foreground="{StaticResource TextSecondary}" HorizontalAlignment="Center" Margin="0,0,0,24"/>
                        <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,24">
                            <Button x:Name="btnChrome" Style="{StaticResource BrowserButton}" Margin="8"><Image x:Name="imgChrome" Width="40" Height="40"/></Button>
                            <Button x:Name="btnFirefox" Style="{StaticResource BrowserButton}" Margin="8"><Image x:Name="imgFirefox" Width="40" Height="40"/></Button>
                            <Button x:Name="btnEdge" Style="{StaticResource BrowserButton}" Margin="8"><Image x:Name="imgEdge" Width="40" Height="40"/></Button>
                            <Button x:Name="btnSafari" Style="{StaticResource BrowserButton}" Margin="8"><Image x:Name="imgSafari" Width="40" Height="40"/></Button>
                            <Button x:Name="btnOpera" Style="{StaticResource BrowserButton}" Margin="8"><Image x:Name="imgOpera" Width="40" Height="40"/></Button>
                        </StackPanel>
                        <Border x:Name="pnlBrowserLinks" Background="{StaticResource BgCard}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="12" Padding="24" Visibility="Collapsed">
                            <StackPanel>
                                <TextBlock x:Name="txtSelectedBrowser" Text="" FontSize="16" FontWeight="SemiBold" Foreground="{StaticResource TextPrimary}" Margin="0,0,0,12"/>
                                <TextBlock Text="Choose a userscript manager:" FontSize="13" Foreground="{StaticResource TextSecondary}" Margin="0,0,0,8"/>
                                <StackPanel x:Name="pnlManagerLinks"/>
                            </StackPanel>
                        </Border>
                        <TextBlock Text="Already have a userscript manager? Skip to the next step." FontSize="12" Foreground="{StaticResource TextMuted}" HorizontalAlignment="Center" Margin="0,24,0,0"/>
                    </StackPanel>
                </Grid>
            </TabItem>
            
            <!-- Step 3 -->
            <TabItem x:Name="tabStep3">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Margin="32,24" HorizontalAlignment="Center" MaxWidth="600">
                        <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,16">
                            <Ellipse Width="32" Height="32" Fill="{StaticResource AccentGreen}"/>
                            <TextBlock Text="1" Foreground="#0a0a0a" FontWeight="Bold" FontSize="14" Margin="-22,7,0,0"/>
                            <Rectangle Width="60" Height="2" Fill="{StaticResource AccentGreen}" VerticalAlignment="Center" Margin="8,0"/>
                            <Ellipse Width="32" Height="32" Fill="{StaticResource AccentGreen}"/>
                            <TextBlock Text="2" Foreground="#0a0a0a" FontWeight="Bold" FontSize="14" Margin="-22,7,0,0"/>
                            <Rectangle Width="60" Height="2" Fill="{StaticResource AccentGreen}" VerticalAlignment="Center" Margin="8,0"/>
                            <Ellipse Width="32" Height="32" Fill="{StaticResource AccentGreen}"/>
                            <TextBlock Text="3" Foreground="#0a0a0a" FontWeight="Bold" FontSize="14" Margin="-22,7,0,0"/>
                        </StackPanel>
                        <TextBlock Text="Step 3: Install Userscript" FontSize="20" FontWeight="SemiBold" Foreground="{StaticResource TextPrimary}" HorizontalAlignment="Center" Margin="0,0,0,24"/>
                        <Border Background="{StaticResource BgCard}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="12" Padding="24" Margin="0,0,0,16">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel Grid.Column="0">
                                    <TextBlock Text="MediaDL Userscript" FontSize="16" FontWeight="SemiBold" Foreground="{StaticResource TextPrimary}"/>
                                    <TextBlock Text="Universal media downloader for 1800+ sites" FontSize="13" Foreground="{StaticResource TextSecondary}" Margin="0,4,0,8"/>
                                    <StackPanel Orientation="Horizontal">
                                        <Border Background="{StaticResource AccentGreen}" CornerRadius="4" Padding="8,4" Margin="0,0,8,0">
                                            <TextBlock Text="Video" FontSize="11" Foreground="#0a0a0a" FontWeight="SemiBold"/>
                                        </Border>
                                        <Border Background="{StaticResource AccentPurple}" CornerRadius="4" Padding="8,4">
                                            <TextBlock Text="MP3" FontSize="11" Foreground="White" FontWeight="SemiBold"/>
                                        </Border>
                                    </StackPanel>
                                </StackPanel>
                                <Button x:Name="btnInstallUserscript" Content="Install" Grid.Column="1" Style="{StaticResource BaseButton}" Padding="24,12" VerticalAlignment="Center"/>
                            </Grid>
                        </Border>
                        <Border Background="{StaticResource BgCard}" BorderBrush="{StaticResource AccentGreen}" BorderThickness="2" CornerRadius="12" Padding="24" Margin="0,16,0,0">
                            <StackPanel>
                                <TextBlock Text="Installation Complete!" FontSize="18" FontWeight="SemiBold" Foreground="{StaticResource AccentGreen}" HorizontalAlignment="Center" Margin="0,0,0,12"/>
                                <TextBlock TextWrapping="Wrap" FontSize="13" Foreground="{StaticResource TextSecondary}" TextAlignment="Center">
                                    <Run Text="MediaDL is now ready to use. Visit any supported site and look for the"/>
                                    <Run Text=" green drawer " Foreground="{StaticResource AccentGreen}" FontWeight="SemiBold"/>
                                    <Run Text="on the right edge of your screen."/>
                                </TextBlock>
                                <Button x:Name="btnOpenFolder" Content="Open Install Folder" Style="{StaticResource SecondaryButton}" Margin="0,16,0,0" Padding="16,10" HorizontalAlignment="Center"/>
                            </StackPanel>
                        </Border>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>
            
            <!-- Uninstall -->
            <TabItem x:Name="tabUninstall">
                <StackPanel Margin="32,24" VerticalAlignment="Center" HorizontalAlignment="Center">
                    <Border Width="80" Height="80" CornerRadius="40" Background="{StaticResource AccentRed}" Margin="0,0,0,24" HorizontalAlignment="Center">
                        <TextBlock Text="X" FontSize="40" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <TextBlock Text="Uninstall MediaDL" FontSize="24" FontWeight="SemiBold" Foreground="{StaticResource TextPrimary}" HorizontalAlignment="Center" Margin="0,0,0,8"/>
                    <TextBlock Text="This will remove all installed components." FontSize="14" Foreground="{StaticResource TextSecondary}" HorizontalAlignment="Center" Margin="0,0,0,32"/>
                    <Border Background="{StaticResource BgCard}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="12" Padding="24" Margin="0,0,0,24">
                        <StackPanel>
                            <TextBlock Text="The following will be removed:" FontSize="13" Foreground="{StaticResource TextSecondary}" Margin="0,0,0,12"/>
                            <TextBlock Text="[X] Protocol handler (ytdl://)" Foreground="{StaticResource TextMuted}" FontFamily="Cascadia Code, Consolas" FontSize="12" Margin="0,4"/>
                            <TextBlock Text="[X] yt-dlp and ffmpeg" Foreground="{StaticResource TextMuted}" FontFamily="Cascadia Code, Consolas" FontSize="12" Margin="0,4"/>
                            <TextBlock Text="[X] Configuration files" Foreground="{StaticResource TextMuted}" FontFamily="Cascadia Code, Consolas" FontSize="12" Margin="0,4"/>
                            <TextBlock Text="[!] Userscript must be removed manually" Foreground="#f97316" FontFamily="Cascadia Code, Consolas" FontSize="12" Margin="0,12,0,0"/>
                        </StackPanel>
                    </Border>
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                        <Button x:Name="btnCancelUninstall" Content="Cancel" Style="{StaticResource SecondaryButton}" Margin="0,0,12,0" Padding="24,12"/>
                        <Button x:Name="btnConfirmUninstall" Content="Uninstall" Style="{StaticResource DangerButton}" Padding="24,12"/>
                    </StackPanel>
                </StackPanel>
            </TabItem>
        </TabControl>
        
        <!-- Footer -->
        <Border Grid.Row="2" Background="{StaticResource BgCard}" BorderBrush="{StaticResource Border}" BorderThickness="0,1,0,0">
            <Grid Margin="32,16">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <Button x:Name="btnUninstall" Content="Uninstall" Style="{StaticResource SecondaryButton}" Padding="16,10" Grid.Column="0"/>
                <StackPanel Grid.Column="2" Orientation="Horizontal">
                    <Button x:Name="btnBack" Content="Back" Style="{StaticResource SecondaryButton}" Padding="20,10" Margin="0,0,12,0" Visibility="Collapsed"/>
                    <Button x:Name="btnNext" Content="Install Base Tools" Style="{StaticResource BaseButton}" Padding="20,10"/>
                </StackPanel>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

# ============================================
# LOAD WINDOW
# ============================================
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get Controls
$tabWizard = $window.FindName("tabWizard")
$txtDownloadPath = $window.FindName("txtDownloadPath")
$btnBrowseDownload = $window.FindName("btnBrowseDownload")
$chkAutoUpdate = $window.FindName("chkAutoUpdate")
$chkNotifications = $window.FindName("chkNotifications")
$chkDesktopShortcut = $window.FindName("chkDesktopShortcut")
$txtStatus = $window.FindName("txtStatus")
$statusScroll = $window.FindName("statusScroll")
$progressFill = $window.FindName("progressFill")
$btnChrome = $window.FindName("btnChrome")
$btnFirefox = $window.FindName("btnFirefox")
$btnEdge = $window.FindName("btnEdge")
$btnSafari = $window.FindName("btnSafari")
$btnOpera = $window.FindName("btnOpera")
$imgChrome = $window.FindName("imgChrome")
$imgFirefox = $window.FindName("imgFirefox")
$imgEdge = $window.FindName("imgEdge")
$imgSafari = $window.FindName("imgSafari")
$imgOpera = $window.FindName("imgOpera")
$pnlBrowserLinks = $window.FindName("pnlBrowserLinks")
$txtSelectedBrowser = $window.FindName("txtSelectedBrowser")
$pnlManagerLinks = $window.FindName("pnlManagerLinks")
$btnInstallUserscript = $window.FindName("btnInstallUserscript")
$btnOpenFolder = $window.FindName("btnOpenFolder")
$btnCancelUninstall = $window.FindName("btnCancelUninstall")
$btnConfirmUninstall = $window.FindName("btnConfirmUninstall")
$btnUninstall = $window.FindName("btnUninstall")
$btnBack = $window.FindName("btnBack")
$btnNext = $window.FindName("btnNext")

# Load browser icons
$imgChrome.Source = Get-BitmapImageFromUrl -Url $script:BrowserIcons.Chrome
$imgFirefox.Source = Get-BitmapImageFromUrl -Url $script:BrowserIcons.Firefox
$imgEdge.Source = Get-BitmapImageFromUrl -Url $script:BrowserIcons.Edge
$imgSafari.Source = Get-BitmapImageFromUrl -Url $script:BrowserIcons.Safari
$imgOpera.Source = Get-BitmapImageFromUrl -Url $script:BrowserIcons.Opera

# Set defaults
$txtDownloadPath.Text = $script:DefaultDownloadPath
$script:CurrentStep = 1
$script:BaseToolsInstalled = $false

# Helper functions
function Update-Status { param([string]$Message); $txtStatus.Text = $txtStatus.Text + "`n" + $Message; $statusScroll.ScrollToEnd(); $window.Dispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::Render) }
function Set-Progress { param([int]$Value); $maxWidth = $progressFill.Parent.ActualWidth; if ($maxWidth -le 0) { $maxWidth = 500 }; $progressFill.Width = ($Value / 100) * $maxWidth; $window.Dispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::Render) }
function Update-WizardButtons {
    switch ($script:CurrentStep) {
        1 { $btnBack.Visibility = "Collapsed"; $btnNext.Content = if ($script:BaseToolsInstalled) { "Next: Userscript Manager" } else { "Install Base Tools" } }
        2 { $btnBack.Visibility = "Visible"; $btnNext.Content = "Next: Install Userscript" }
        3 { $btnBack.Visibility = "Visible"; $btnNext.Content = "Finish" }
        4 { $btnBack.Visibility = "Collapsed"; $btnNext.Visibility = "Collapsed" }
    }
}

function Show-BrowserLinks {
    param([string]$Browser)
    $pnlBrowserLinks.Visibility = "Visible"
    $txtSelectedBrowser.Text = $Browser
    $pnlManagerLinks.Children.Clear()
    $managers = $script:UserscriptManagers[$Browser]
    foreach ($manager in $managers.GetEnumerator()) {
        $linkPanel = New-Object System.Windows.Controls.StackPanel; $linkPanel.Orientation = "Horizontal"; $linkPanel.Margin = "0,8,0,0"
        $bullet = New-Object System.Windows.Controls.TextBlock; $bullet.Text = ">"; $bullet.Foreground = [System.Windows.Media.Brushes]::LimeGreen; $bullet.FontFamily = New-Object System.Windows.Media.FontFamily("Cascadia Code, Consolas"); $bullet.Margin = "0,0,8,0"
        $link = New-Object System.Windows.Controls.TextBlock; $link.Cursor = [System.Windows.Input.Cursors]::Hand
        $hyperlink = New-Object System.Windows.Documents.Hyperlink; $hyperlink.Inlines.Add($manager.Key); $hyperlink.Foreground = [System.Windows.Media.Brushes]::DodgerBlue; $hyperlink.TextDecorations = $null
        $url = $manager.Value; $hyperlink.Add_Click({ Start-Process $url }.GetNewClosure())
        $link.Inlines.Add($hyperlink); $linkPanel.Children.Add($bullet); $linkPanel.Children.Add($link); $pnlManagerLinks.Children.Add($linkPanel)
    }
}

# Event handlers
$btnBrowseDownload.Add_Click({ $dialog = New-Object System.Windows.Forms.FolderBrowserDialog; $dialog.SelectedPath = $txtDownloadPath.Text; if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $txtDownloadPath.Text = $dialog.SelectedPath } })
$btnChrome.Add_Click({ Show-BrowserLinks -Browser "Chrome" })
$btnFirefox.Add_Click({ Show-BrowserLinks -Browser "Firefox" })
$btnEdge.Add_Click({ Show-BrowserLinks -Browser "Edge" })
$btnSafari.Add_Click({ Show-BrowserLinks -Browser "Safari" })
$btnOpera.Add_Click({ Show-BrowserLinks -Browser "Opera" })
$btnInstallUserscript.Add_Click({ Start-Process $script:UserscriptUrl })
$btnOpenFolder.Add_Click({ if (Test-Path $script:InstallPath) { Start-Process explorer.exe -ArgumentList $script:InstallPath } })
$btnBack.Add_Click({ if ($script:CurrentStep -eq 4) { $script:CurrentStep = 1; $tabWizard.SelectedIndex = 0; $btnNext.Visibility = "Visible" } elseif ($script:CurrentStep -gt 1) { $script:CurrentStep--; $tabWizard.SelectedIndex = $script:CurrentStep - 1 }; Update-WizardButtons })
$btnUninstall.Add_Click({ $script:CurrentStep = 4; $tabWizard.SelectedIndex = 3; Update-WizardButtons })
$btnCancelUninstall.Add_Click({ $script:CurrentStep = 1; $tabWizard.SelectedIndex = 0; $btnNext.Visibility = "Visible"; Update-WizardButtons })
$btnConfirmUninstall.Add_Click({
    if ([System.Windows.MessageBox]::Show("Are you sure you want to uninstall MediaDL?", "Confirm", "YesNo", "Warning") -eq "Yes") {
        try {
            Get-Process -Name "yt-dlp","ffmpeg" -ErrorAction SilentlyContinue | Stop-Process -Force
            Remove-Item -Path "HKCU:\Software\Classes\ytdl" -Recurse -Force -ErrorAction SilentlyContinue
            if (Test-Path $script:InstallPath) { Remove-Item -Path $script:InstallPath -Recurse -Force }
            Remove-Item "$env:USERPROFILE\Desktop\MediaDL Download.lnk" -Force -ErrorAction SilentlyContinue
            [System.Windows.MessageBox]::Show("MediaDL uninstalled. Remove userscript manually from browser.", "Done", "OK", "Information")
            $window.Close()
        } catch { [System.Windows.MessageBox]::Show("Error: $($_.Exception.Message)", "Error", "OK", "Error") }
    }
})

$btnNext.Add_Click({
    switch ($script:CurrentStep) {
        1 {
            if (-not $script:BaseToolsInstalled) {
                $btnNext.IsEnabled = $false
                $txtStatus.Text = "Starting installation..."
                Set-Progress 0
                try {
                    Update-Status "Creating directories..."
                    if (!(Test-Path $script:InstallPath)) { New-Item -ItemType Directory -Path $script:InstallPath -Force | Out-Null }
                    Update-Status "  [OK] $($script:InstallPath)"
                    $dlPath = $txtDownloadPath.Text
                    if (!(Test-Path $dlPath)) { New-Item -ItemType Directory -Path $dlPath -Force | Out-Null }
                    Update-Status "  [OK] $dlPath"
                    Set-Progress 10
                    
                    Update-Status "Downloading yt-dlp..."
                    $ytdlpPath = Join-Path $script:InstallPath "yt-dlp.exe"
                    Invoke-WebRequest -Uri $script:YtDlpUrl -OutFile $ytdlpPath -UseBasicParsing
                    Update-Status "  [OK] yt-dlp downloaded"
                    Set-Progress 30
                    
                    Update-Status "Downloading ffmpeg..."
                    $ffmpegZipUrl = "https://github.com/yt-dlp/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
                    $ffmpegZip = Join-Path $script:InstallPath "ffmpeg.zip"
                    $ffmpegPath = Join-Path $script:InstallPath "ffmpeg.exe"
                    if (!(Test-Path $ffmpegPath)) {
                        try {
                            Invoke-WebRequest -Uri $ffmpegZipUrl -OutFile $ffmpegZip -UseBasicParsing
                            Update-Status "  [OK] ffmpeg archive downloaded"
                            Add-Type -AssemblyName System.IO.Compression.FileSystem
                            $zip = [System.IO.Compression.ZipFile]::OpenRead($ffmpegZip)
                            $entry = $zip.Entries | Where-Object { $_.Name -eq "ffmpeg.exe" } | Select-Object -First 1
                            if ($entry) { [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $ffmpegPath, $true) }
                            $zip.Dispose()
                            Remove-Item $ffmpegZip -Force -ErrorAction SilentlyContinue
                            Update-Status "  [OK] ffmpeg extracted"
                        } catch { Update-Status "  [!] ffmpeg download failed" }
                    }
                    Set-Progress 50
                    
                    Update-Status "Saving config..."
                    @{ DownloadPath = $dlPath; AutoUpdate = $chkAutoUpdate.IsChecked; Notifications = $chkNotifications.IsChecked; YtDlpPath = $ytdlpPath; FfmpegPath = $ffmpegPath } | ConvertTo-Json | Set-Content (Join-Path $script:InstallPath "config.json") -Encoding UTF8
                    Update-Status "  [OK] Config saved"
                    Set-Progress 60
                    
                    Update-Status "Creating handler..."
                    $handler = @'
param([string]$url)
Add-Type -AssemblyName System.Windows.Forms
$config = Get-Content (Join-Path $PSScriptRoot "config.json") -Raw | ConvertFrom-Json
$videoUrl = [System.Uri]::UnescapeDataString($url -replace '^ytdl://', '')
$audioOnly = $videoUrl -match "ytyt_audio_only=1"
$videoUrl = $videoUrl -replace "[&?]ytyt_audio_only=1", ""
$form = New-Object System.Windows.Forms.Form
$form.Text = "MediaDL"; $form.Size = "420,100"; $form.FormBorderStyle = "None"; $form.StartPosition = "Manual"; $form.BackColor = [System.Drawing.Color]::FromArgb(18,18,18); $form.TopMost = $true
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$form.Location = "$($screen.Right - 436),$($screen.Bottom - 116)"
$lbl = New-Object System.Windows.Forms.Label; $lbl.Text = "Downloading..."; $lbl.ForeColor = "White"; $lbl.Font = "Segoe UI,10"; $lbl.Location = "16,16"; $lbl.AutoSize = $true; $form.Controls.Add($lbl)
$pnl = New-Object System.Windows.Forms.Panel; $pnl.Size = "380,8"; $pnl.Location = "16,50"; $pnl.BackColor = [System.Drawing.Color]::FromArgb(50,50,50); $form.Controls.Add($pnl)
$fill = New-Object System.Windows.Forms.Panel; $fill.Size = "0,8"; $fill.BackColor = if($audioOnly){[System.Drawing.Color]::FromArgb(108,92,231)}else{[System.Drawing.Color]::FromArgb(0,184,148)}; $pnl.Controls.Add($fill)
$close = New-Object System.Windows.Forms.Label; $close.Text = "X"; $close.ForeColor = "Gray"; $close.Font = "Segoe UI,10,Bold"; $close.Location = "390,10"; $close.Cursor = "Hand"; $close.Add_Click({$form.Close()}); $form.Controls.Add($close)
$prog = Join-Path $env:TEMP "mdl_$([guid]::NewGuid().ToString('N')).txt"
$ffLoc = Split-Path $config.FfmpegPath -Parent
$outTpl = if($audioOnly){Join-Path $config.DownloadPath "%(title)s.mp3"}else{Join-Path $config.DownloadPath "%(title)s.%(ext)s"}
$job = if($audioOnly){Start-Job{param($y,$f,$o,$u,$p);&$y -f bestaudio --extract-audio --audio-format mp3 --newline --ffmpeg-location $f -o $o $u 2>&1|%{$_|Out-File $p -Append;$_}}-Arg $config.YtDlpPath,$ffLoc,$outTpl,$videoUrl,$prog}else{Start-Job{param($y,$f,$o,$u,$p);&$y -f "bestvideo[height<=1080]+bestaudio/best" --merge-output-format mp4 --newline --ffmpeg-location $f -o $o $u 2>&1|%{$_|Out-File $p -Append;$_}}-Arg $config.YtDlpPath,$ffLoc,$outTpl,$videoUrl,$prog}
$timer = New-Object System.Windows.Forms.Timer; $timer.Interval = 500
$timer.Add_Tick({if(Test-Path $prog){$l=Get-Content $prog -ErrorAction SilentlyContinue|Select -Last 1;if($l-match'(\d+)%'){$fill.Width=[int]([double]$matches[1]/100*380)}};if($job.State-eq"Completed"){$timer.Stop();$fill.Width=380;Start-Sleep 1;$form.Close()}elseif($job.State-eq"Failed"){$timer.Stop();$lbl.Text="Failed";Start-Sleep 2;$form.Close()}})
$form.Add_Shown({$timer.Start()})
$form.Add_FormClosed({$timer.Stop();Stop-Job $job -EA 0;Remove-Job $job -Force -EA 0;Remove-Item $prog -Force -EA 0})
[System.Windows.Forms.Application]::Run($form)
'@
                    $handler | Set-Content (Join-Path $script:InstallPath "ytdl-handler.ps1") -Encoding UTF8
                    Update-Status "  [OK] Handler created"
                    Set-Progress 75
                    
                    Update-Status "Registering protocol..."
                    $handlerPath = Join-Path $script:InstallPath "ytdl-handler.ps1"
                    New-Item -Path "HKCU:\Software\Classes\ytdl" -Force | Out-Null
                    Set-ItemProperty -Path "HKCU:\Software\Classes\ytdl" -Name "(Default)" -Value "URL:YTDL Protocol"
                    Set-ItemProperty -Path "HKCU:\Software\Classes\ytdl" -Name "URL Protocol" -Value ""
                    New-Item -Path "HKCU:\Software\Classes\ytdl\shell\open\command" -Force | Out-Null
                    Set-ItemProperty -Path "HKCU:\Software\Classes\ytdl\shell\open\command" -Name "(Default)" -Value "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$handlerPath`" `"%1`""
                    Update-Status "  [OK] Protocol registered"
                    Set-Progress 90
                    
                    if ($chkDesktopShortcut.IsChecked) {
                        $WshShell = New-Object -ComObject WScript.Shell
                        $shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\MediaDL Download.lnk")
                        $shortcut.TargetPath = "powershell.exe"
                        $shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -Command `"Add-Type -AssemblyName System.Windows.Forms;`$u=[System.Windows.Forms.Clipboard]::GetText();if(`$u-match'http'){Start-Process('ytdl://'+`$u)}`""
                        $shortcut.IconLocation = "$env:SystemRoot\System32\shell32.dll,175"
                        $shortcut.Save()
                        Update-Status "  [OK] Shortcut created"
                    }
                    Set-Progress 100
                    Update-Status "`n========================================"
                    Update-Status "Installation complete!"
                    Update-Status "========================================"
                    $script:BaseToolsInstalled = $true
                    $btnNext.Content = "Next: Userscript Manager"
                } catch { Update-Status "`n[ERROR] $($_.Exception.Message)"; [System.Windows.MessageBox]::Show("Installation failed: $($_.Exception.Message)", "Error", "OK", "Error") }
                $btnNext.IsEnabled = $true
            } else { $script:CurrentStep = 2; $tabWizard.SelectedIndex = 1; Update-WizardButtons }
        }
        2 { $script:CurrentStep = 3; $tabWizard.SelectedIndex = 2; Update-WizardButtons }
        3 { $window.Close() }
    }
})

Update-WizardButtons
$window.ShowDialog() | Out-Null
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
