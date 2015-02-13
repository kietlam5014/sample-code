@rem = ' Perl for Windows NT
@echo off
color 1a
setlocal & pushd
set SCRIPT=%0
shift
IF NOT EXIST %SCRIPT% set SCRIPT=%SCRIPT%.bat
perl %SCRIPT% %* 2>&1
endlocal & popd
goto :endperl
@rem ';
#================================================================================#
# Copyright (c) 2009, Sony Ericsson
# All Rights Reserved.
#
# Description: This script setups the necessary environments, creates a temp dir,
#              and calls vendor's subscript.
#
# Revision History:
#
# Date      Author    Description
#--------------------------------------------------------------------------------
# 09/05/20  10101482  Updated for Vulcan
# 09/06/10  10101482  Removing any space in filename
# 09/06/16  10101482  DMS 506455, 506456, 506457
# 09/06/18  10101482  DMS 506568, 506569, 506357 (removed spbmobile panels, google settings)
# 09/06/20  10101482  DMS 476551: added Illumination
# 09/06/23  10101482  Removed Beatnik, skype, youtube, NIM
# 09/06/26  10101482  Build SEUS_VersionInfo cab
# 09/07/01  10101482  Removed DLNA & Video Telephony
# 09/07/02  10101482  Include DLNA back and remove SPB Dialer
# 09/07/08  10101482  Stage CABs to builtsw\CUSTAPPS\AUTOEXEC (used by generateSDR)
# 09/07/09  10101482  Output where all CABs are staged to
# 09/07/09  10101482  Added Customization support and modified to stage cabs to its
#                     own temp directory
# 09/07/15  10101482  Take CT (Contract) as UK
# 09/07/16  10101482  DMS00651139: F-Secure
# 09/07/17  10101482  DMS00507537 (remove Awox DLNA)
# 09/07/19  10101482  Convert user entered parameters to uppercase
# 09/07/21  10101482  Support diff space id based on language variant
# 09/07/29  10101482  Extract *.xml file from customization zip
# 09/08/12  10101482  Added languages support
# 09/08/24  10101482  Code cleanup
# 09/08/27  10101482  Added support to build without any customization SDR
# 09/09/03  10101482  Wrapped batch script around perl
# 09/09/08  10101482  Remove VIEW parameter
# 09/09/23  10101482  Removed ENGRCABS (not being used)
# 09/09/30  10101482  Added ability to not build tactel apps
# 09/10/02  10101482  Added PM Launcher
#================================================================================#
use strict;
use Win32::TieRegistry;
use Getopt::Long;
use Signfile;

## Set Environment
#
my $PATH = $ENV{'PATH'};
my $HOMEDRIVE = $ENV{'HOMEDRIVE'};
my $BUILTSW = "$HOMEDRIVE\\Temp\\builtsw";
my $TMPCABDIR = "$BUILTSW\\CABS";
my $TMPCOMMONCABDIR = "$BUILTSW\\CABS\\Common";
my $TMPCUSTDIR = "$BUILTSW\\CUSTCABS";

## Get installed location of tools
#
my $WINRAR_PATH = $Registry->{"HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows\\CurrentVersion\\App Paths\\WinRAR.exe\\\\Path"};
$ENV{'PATH'} = $PATH . ";" . $WINRAR_PATH;

## Routines
#
sub print_msg($);
sub create_dir($);
sub main();

main();


#----------------------------------------------------------------------#
# Subroutine    : main
# Purpose       : Main routine. prepare environments, variables, and
#                 loop thru each vendor and call its vmain.pl
# Parameters    :
# Returns       : 1 successful operations, otherwise 0 fail
#----------------------------------------------------------------------#
sub main() {
    ## Variables
    #
    my $ZIP = "rar";

    my ($PRODLB, $LANG, $CUSTLB, $OPR, $help);
    my ($CTRY, $OPRLANG, $SPACEID, $NOCUST, $NOTACT);
    my $error;
    
    GetOptions ('prodlb=s' => \$PRODLB, 'lang=s' => \$LANG, 'ctry=s' => \$CTRY, 'custlb=s' => \$CUSTLB,
                'opr=s' => \$OPR, 'nocust' => \$NOCUST, 'notact' => \$NOTACT, 'help|?' => \$help);

    if ( ! $PRODLB or defined $help ) {
       usage();
    }

    my $CUSTPATH = "\\\\corpusers.net\\ussv\\ConvergenceSW\\Vulcan\\SoftwareDrops\\Customization";
    my $VIEW = "Z:\\" . `cleartool pwv -short`;
    chop($VIEW);
    
    ## Get tool path
    #
    my $NOSPACE = "$VIEW\\USSV_Devtools\\cnh1012571_convergence_tools\\Scripts\\nospace.pl";

    my $cnh1012765_winmob = "cnh1012765_winmob_installableapplications\\NativeApplications";
   
    my %COMMON_VENDORS = (
        "3DHero"                 => "$VIEW\\USSV_SW_Southend_001\\cnh1012693_3d_hero\\vbuild.pl",
        "AdobeReader"            => "$VIEW\\USSV_SW_Microsoft_002\\cnh1012863_adobe_reader\\vbuild.pl",
        "PMBacklightSetup"       => "$VIEW\\USSV_SW_Teleca_001\\cnh1012611_backlight_pm_settings\\vbuild.pl",
        "BluetoothSettings"      => "$VIEW\\USSV_SW_Teleca_001\\cnh1012612_bluetooth_settings\\vbuild.pl",
        "Boingo"                 => "$VIEW\\LDS_SwModules_002\\$cnh1012765_winmob\\Boingo\\vbuild.pl",
        "ClearStorage"           => "$VIEW\\USSV_SW_Teleca_001\\cnh1012614_clear_storage\\vbuild.pl",
        "CommManager"            => "$VIEW\\USSV_SW_Teleca_001\\cnh1012574_communication_manager\\vbuild.pl",
        "ConnectionSetup"        => "$VIEW\\USSV_SW_Teleca_001\\cnh1012573_connection_setup_wizard\\vbuild.pl",
        "ContentPanel"           => "$VIEW\\USSV_SW_Teleca_001\\cnh1012870_content_panel\\vbuild.pl",
        "CNNPanel"               => "$VIEW\\LDS_SwModules_002\\$cnh1012765_winmob\\CNNpanel\\vbuild.pl",
        "DeviceInfo"             => "$VIEW\\USSV_SW_Teleca_001\\cnh1012616_device_info\\vbuild.pl",
        "DLNA"                   => "$VIEW\\USSV_SW_AwoX_001\\cnh1012889_mediactrl_server\\vbuild.pl",
        "EsmertecJava"           => "$VIEW\\USSV_SW_Esmertec_001\\cnh1012563_esmertec\\vbuild.pl",
        "FlashPanelPkg"          => "$VIEW\\USSV_SW_TelecaUK_001\\cnh1012798_flashpanel_pkg\\vbuild.pl",
        "ActiveXDeployment"      => "$VIEW\\USSV_SW_TelecaUK_001\\cnh1012692_activex_deployment\\vbuild.pl",
        "GoogleSearch"           => "$VIEW\\USSV_SW_Google_001\\cnh1012794_search\\vbuild.pl",
        "Googlemaps"             => "$VIEW\\USSV_SW_Google_001\\cnh1012685_maps\\vbuild.pl",
        "GrowingPanel"           => "$VIEW\\USSV_SW_UsTwo_001\\cnh1012686_growing_panel\\vbuild.pl",
        "IdleModeText"           => "$VIEW\\USSV_SW_Teleca_001\\cnh1012677_idle_mode_text\\vbuild.pl",
        "Illumination"           => "$VIEW\\USSV_SW_Teleca_001\\cnh1012617_illumination_settings\\vbuild.pl",
        "JMMS"                   => "$VIEW\\USSV_SW_Jataayu_001\\cnh1012796_jmms_client\\vbuild.pl",
        "MicrophoneACG"          => "$VIEW\\USSV_SW_Teleca_001\\cnh1012620_microphone_agc_settings\\vbuild.pl",
        "MobileData"             => "$VIEW\\USSV_SW_Teleca_001\\cnh1012623_advanced_network_settings\\vbuild.pl",
        "MyCPL"                  => "$VIEW\\USSV_SW_Teleca_001\\cnh1012621_my_cpl\\vbuild.pl",
        "OpticalJoystick"        => "$VIEW\\USSV_SW_Teleca_001\\cnh1012618_optical_joystick_settings\\vbuild.pl",
        "PhoneSettings"          => "$VIEW\\USSV_SW_Teleca_001\\cnh1012622_phone_settings\\vbuild.pl",
        "PixelCityDay"           => "$VIEW\\USSV_SW_UsTwo_001\\cnh1012689_pixel_city_day\\vbuild.pl",
        "PixelCityNight"         => "$VIEW\\USSV_SW_UsTwo_001\\cnh1012864_pixel_city_night\\vbuild.pl",
        "SetupSMM"               => "$VIEW\\USSV_SW_Teleca_001\\cnh1012575_ring_tone_enhancement\\vbuild.pl",
        "SpbMobileShell"         => "$VIEW\\USSV_SW_Softspb_001\\cnh1012862_spb_mobileshell\\vbuild.pl",
        "TaskManagerQuickWindow" => "$VIEW\\USSV_SW_Teleca_001\\cnh1012579_task_manager\\vbuild.pl",
        "TimeZoneService"        => "$VIEW\\USSV_SW_Teleca_001\\cnh1012674_time_zone_service\\vbuild.pl",
        "TVOut"                  => "$VIEW\\USSV_SW_Teleca_001\\cnh1012673_tv_out_settings\\vbuild.pl",
        "VulcanDialer"           => "$VIEW\\USSV_SW_Softspb_001\\cnh1012687_spb_dialer\\vbuild.pl",
        "SymSelector"            => "$VIEW\\USSV_SwModules_001\\cnh1012890_sym_selector\\vbuild.pl",
        "YouTube"		 => "$VIEW\\LDS_SwModules_002\\$cnh1012765_winmob\\YouTube\\vbuild.pl",
        "ActiveLauncher"         => "$VIEW\\USSV_SW_Tactel_001\\cnh1012690_active_launcher\\vbuild.pl",
        "Camera"                 => "$VIEW\\USSV_SW_Tactel_001\\cnh1012681_camera\\vbuild.pl",
        "DRM"                    => "$VIEW\\USSV_SW_Tactel_001\\cnh1012868_drm_cabinstaller\\vbuild.pl",
        "OEMNotification"        => "$VIEW\\USSV_SW_Tactel_001\\cnh1012885_oem_notification\\vbuild.pl",
        "PanelManager"           => "$VIEW\\USSV_SW_Tactel_001\\cnh1012679_panel_manager\\vbuild.pl",
        "PMLauncher"             => "$VIEW\\USSV_SW_Tactel_001\\cnh1012940_pm_launcher\\vbuild.pl",
        "XKeyHandler"            => "$VIEW\\USSV_SW_Tactel_001\\cnh1012852_xkeyhandler\\vbuild.pl",
        "XpFramework"            => "$VIEW\\USSV_SW_Tactel_001\\cnh1012691_xpframework\\vbuild.pl",       
    );

    my %VENDORS = (
             "Experiment13"           => "$VIEW\\USSV_SW_Southend_001\\cnh1012688_experiment13\\vbuild.pl",
#            "FacebookPanel"          => "$VIEW\\USSV_SW_Teleca_001\\cnh1012672_facebook_panel\\vbuild.pl",
#            "F-Secure"               => "$VIEW\\LDS_SwModules_002\\$cnh1012765_winmob\\F-Secure\\vbuild.pl",
#             "SpbBakcup"              => "$VIEW\\USSV_SW_Softspb_001\\cnh1012799_spb_backup\\vbuild.pl",
#            "TTYHAC"                 => "$VIEW\\USSV_SW_Teleca_001\\cnh1012619_tty_hac_settings\\vbuild.pl",
#             "USBToPC"                => "$VIEW\\USSV_SW_Teleca_001\\cnh1012675_usb_to_pc\\vbuild.pl",
             "WAPI"                   => "$VIEW\\USSV_WLAN_SW_001\\cnh1012910_wapi\\vbuild.pl",
             "Xt9"                    => "$VIEW\\USSV_SW_Nuance_001\\cnh1012625_xt9\\vbuild.pl",
             "Xtrakt"                 => "$VIEW\\USSV_SW_Southend_001\\cnh1012684_xtrakt\\vbuild.pl",
             "PatchCabs"              => "$VIEW\\USSV_SwModules_004\\cnh1012908_temp_patch\\vbuild.pl",
#	     "YouTubePanel"	      => "$VIEW\\LDS_SwModules_002\\$cnh1012765_winmob\\YouTubePanel\\vbuild.pl",
	     "UserGuide"	      => "$VIEW\\USSV_SwModules_004\\cnh1012937_userguide\\vbuild.pl",
	     "SlideviewPlugin"	      => "$VIEW\\USSV_SwModules_001\\cnh1012936_slideview_plugin\\vbuild.pl",
             "xt9_pti"                => "$VIEW\\USSV_SW_Nuance_001\\cnh1012886_xt9_pti\\vbuild.pl",
             "Email_signature"        => "$VIEW\\USSV_SwModules_001\\cnh1012884_email_signature\\vbuild.pl",
#             "FastGPS"                => "$VIEW\\USSV_SW_Teleca_001\\cnh1012883_fastgps\\vbuild.pl",
    );

    if (not defined $NOCUST) {
       if (! ($CTRY && $LANG && $CUSTLB && $OPR)) { die "--(ctry,lang,custlb,opr) require\n"; }
    }
    if (! ($PRODLB)) { die "Require --prodlb is missing\n"; }

    if (-e $TMPCABDIR) { system("del /q $TMPCABDIR"); }
    if (-e $TMPCUSTDIR) { system("rmdir /q/s $TMPCUSTDIR"); }

    if (! -e $TMPCABDIR) { create_dir($TMPCABDIR); }
    if (! -e $TMPCUSTDIR) { create_dir($TMPCUSTDIR); }
    if (! -e $TMPCOMMONCABDIR) { create_dir($TMPCOMMONCABDIR); }

    $LANG =~ tr/a-z/A-Z/;
    $OPR =~ tr/a-z/A-Z/;

    # Calling vbuild from each module

    # Get common cabs
    if (! -e "$TMPCOMMONCABDIR\\cm_$PRODLB") {
       system("del /q $TMPCOMMONCABDIR");   # clean common dir first
       foreach my $cmvendor (keys %COMMON_VENDORS) {
          my $vb = $COMMON_VENDORS{$cmvendor}; # gets fullpath to vendor's vbuild.pl
          print "Staging $cmvendor\n";
          require "$vb";
          vmain($VIEW, $TMPCOMMONCABDIR, $LANG, $OPR); # calls vendor's vbuild.pl's vmain routine    
       }
    }
    system("echo.>$TMPCOMMONCABDIR\\cm_$PRODLB");

    foreach my $vendor (keys %VENDORS) {
       my $vb = $VENDORS{$vendor}; # gets fullpath to vendor's vbuild.pl
       print "Staging $vendor\n";
       require "$vb";
       vmain($VIEW, $TMPCABDIR, $LANG, $OPR); # calls vendor's vbuild.pl's vmain routine
    }

    if ($LANG) { $LANG =~ tr/a-z/A-Z/; }
    if ($OPR) { $OPR =~ tr/a-z/A-Z/; }
    if ($PRODLB) { $PRODLB =~ tr/a-z/A-Z/; }
    if ($CUSTLB) { $CUSTLB =~ tr/a-z/A-Z/; }

    if (not defined $NOCUST) {
       print_msg("Staging customization file");
       $OPRLANG = $OPR . "_" . $LANG;    
       if ($CTRY eq "United_Kingdom") {
          if ((($OPR eq "VOD") || ($OPR eq "VODAFONE")) && (($LANG eq "UK") || ($LANG eq "EN") || ($LANG eq "CONTRACT"))) {
             system("dir /b $CUSTPATH\\$CTRY\\Vodafone_Contract\\*$CUSTLB*.zip");
             my $error = system("winrar x -av- $CUSTPATH\\$CTRY\\Vodafone_Contract\\*$CUSTLB*.zip *.cab *.xml $TMPCUSTDIR");
             if ($error) { die "\nError: $error\n"; }
          } else {
             $OPRLANG = $OPR . "_" . "UK" if ($LANG eq "EN");
             $error = system("dir /b $CUSTPATH\\$CTRY\\$OPRLANG\\*$CUSTLB*.zip");
             if ($error) { die "\nError: $CUSTPATH\\$CTRY\\$OPRLANG\\*$CUSTLB*.zip not found\n"; }
             $error = system("winrar x -av- $CUSTPATH\\$CTRY\\$OPRLANG\\*$CUSTLB*.zip *.cab *.xml $TMPCUSTDIR");
             if ($error) { die "\nError: $error\n"; }        
          }
       } else {
          $error = system("dir /b $CUSTPATH\\$CTRY\\$OPRLANG\\*$CUSTLB*.zip");
          if ($error) { die "\nError: $CUSTPATH\\$CTRY\\$OPRLANG\\*$CUSTLB*.zip not found\n"; }
          $error = system("winrar x -av- $CUSTPATH\\$CTRY\\$OPRLANG\\*$CUSTLB*.zip *.cab *.xml $TMPCUSTDIR");
          if ($error) { die "\nError: $error\n"; }        
       }

       # fail if $TMPCUSTDIR empty
       opendir(DIR,$TMPCUSTDIR) or die "$!";
       readdir DIR;
       readdir DIR;
       if (readdir DIR) {
       }
       else { die "customization file not exist\n"; }
       close DIR;
    }
        
    print "\nCabs staged to $BUILTSW\n\n";
}


#----------------------------------------------------------------------#
# Subroutine    : print_msg
# Purpose       : prints message
# Parameters    : msg - message to print
# Returns       :
#----------------------------------------------------------------------#
sub print_msg($) {
   my ($msg) = @_;
   print "\n\n---------------------------------------------------------------------\n";
   print "$msg\n";
   print "---------------------------------------------------------------------\n";
}


#----------------------------------------------------------------------#
# Subroutine    : creat_dir
# Purpose       : Create delivery directory
# Parameters    : Full path directory location to create
# Returns       : 1 successful operations, otherwise 0 fail
#----------------------------------------------------------------------#
sub create_dir($) {
    my ($dir) = @_;
    my $result = system("mkdir $dir");
    return $result;
}


#----------------------------------------------------------------------#
# Subroutine    : zipup
# Purpose       : Zip up the delivery
# Parameters    : Name of Zip program
#                 Full path directory location to zip
# Returns       : 1 successful operations, otherwise 0 fail
#----------------------------------------------------------------------#
sub zipup($ $) {
    my ($zip, $dir) = @_;
    my $result = system("$zip a -ep1 $dir $dir");
    return $result;
}


#----------------------------------------------------------------------#
# Subroutine    : usage
# Purpose       : prints usage of this script
# Parameters    :
# Returns       :
#----------------------------------------------------------------------#
sub usage() {
    print "Unknown options: @_\n" if (@_);
    print "usage: stagecabs --prodlb product_label  --ctry country --lang language --custlb customization_label --opr operator\n";
    print "                 [--nocust] [--notact] [--help|-?]\n";
    print "   ex: stagecabs --prodlb  R1AA034 --ctry United_Kingdom --lang EN --custlb U2A --opr VOD\n";
    exit;
}

__END__
:endperl
