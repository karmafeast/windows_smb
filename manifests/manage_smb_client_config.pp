define windows_smb::manage_smb_client_config (
  $ensure                                               = 'present',
  $smb_client_connection_count_per_interface            = 1,
  $smb_client_connection_count_per_rss_interface        = 4,
  $smb_client_connection_count_per_rdma_interface       = 2,
  $smb_client_connection_count_per_server_max           = 32,
  $smb_client_dormant_directory_timeout_seconds         = 600,
  $smb_client_directory_cache_lifetime_seconds          = 10,
  $smb_client_dormant_file_limit                        = 1023,
  $smb_client_directory_cache_entries_max               = 16,
  $smb_client_directory_cache_entry_size_max_bytes      = 65536,
  $smb_client_file_not_found_cache_lifetime_seconds     = 5,
  $smb_client_file_not_found_cache_entries_max          = 128,
  $smb_client_file_info_cache_lifetime_seconds          = 10,
  $smb_client_file_info_cache_entries_max               = 64,
  $smb_client_enable_bandwidth_throttling               = true,
  $smb_client_enable_large_mtu                          = true,
  $smb_client_enable_byte_range_locking_read_only_files = true,
  $smb_client_enable_multichannel                       = true,
  $smb_client_extended_session_timeout_seconds          = 1000,
  $smb_client_keep_connection_seconds                   = 600,
  $smb_client_max_commands                              = 50,
  $smb_client_oplocks_disabled                          = false,
  $smb_client_session_timeout_seconds                   = 60,
  $smb_client_use_opportunistic_locking                 = true,
  $smb_client_window_size_threshold                     = 1) {
  if (!$::osfamily == 'windows') {
    fail('cannot run windows_smb::manage_smb_client_config against non-windows OS platform')
  }

  validate_re($ensure, '^(present|default)$', 'ensure must be one of \'present\', \'default\'')

  validate_integer($smb_client_connection_count_per_interface,16,1)
  validate_integer($smb_client_connection_count_per_rss_interface,16,1)
  validate_integer($smb_client_connection_count_per_rdma_interface,16,1)
  validate_integer($smb_client_connection_count_per_server_max,64,1)
  validate_integer($smb_client_dormant_directory_timeout_seconds,4294967295,0)
  validate_integer($smb_client_directory_cache_entry_size_max_bytes,16777216,65536)
  validate_integer($smb_client_file_not_found_cache_lifetime_seconds,4294967295,0)
  validate_integer($smb_client_file_info_cache_lifetime_seconds,4294967295,0)
  validate_integer($smb_client_extended_session_timeout_seconds,4294967295,0)
  validate_integer($smb_client_file_info_cache_entries_max,65536,1)
  validate_integer($smb_client_file_not_found_cache_entries_max,65536,1)
  validate_integer($smb_client_keep_connection_seconds,4294967295,0)
  validate_integer($smb_client_max_commands,65535,0)
  validate_integer($smb_client_session_timeout_seconds,65535,10)
  validate_integer($smb_client_window_size_threshold,4294967295,0)
  validate_integer($smb_client_dormant_file_limit,4294967295, 1)
  validate_integer($smb_client_directory_cache_lifetime_seconds,4294967295,0)
  validate_integer($smb_client_directory_cache_entries_max,4096,1)

  validate_bool($smb_client_enable_bandwidth_throttling)
  validate_bool($smb_client_enable_large_mtu)
  validate_bool($smb_client_enable_byte_range_locking_read_only_files)
  validate_bool($smb_client_enable_multichannel)
  validate_bool($smb_client_oplocks_disabled)
  validate_bool($smb_client_use_opportunistic_locking)

  if ($ensure == 'present') {
    exec { 'ensure present - ConnectionCountPerNetworkInterface':
      command   => "\
if((get-itemproperty -Path \"HKLM:\\System\\CurrentControlSet\\Services\\LanmanWorkstation\\Parameters\" ConnectionCountPerNetworkInterface) -eq \$null)\
{New-ItemProperty -Path \"HKLM:\\System\\CurrentControlSet\\Services\\LanmanWorkstation\\Parameters\" -Name ConnectionCountPerNetworkInterface -PropertyType \"DWord\" -Value ${smb_client_connection_count_per_interface} -Force;}\
else{Set-ItemProperty -Path \"HKLM:\\System\\CurrentControlSet\\Services\\LanmanWorkstation\\Parameters\" ConnectionCountPerNetworkInterface -Value ${smb_client_connection_count_per_interface} -Force;}",
      unless    => "\
if((get-itemproperty -Path \"HKLM:\\System\\CurrentControlSet\\Services\\LanmanWorkstation\\Parameters\" ConnectionCountPerNetworkInterface) -eq \$null){exit 1;}\
if((Get-ItemProperty -Path \"HKLM:\\System\\CurrentControlSet\\Services\\LanmanWorkstation\\Parameters\").ConnectionCountPerNetworkInterface -eq ${smb_client_connection_count_per_interface}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure present - ConnectionCountPerRssNetworkInterface':
      command   => "Set-SmbClientConfiguration -ConnectionCountPerRssNetworkInterface ${smb_client_connection_count_per_rss_interface} -force",
      unless    => "if((Get-SmbClientConfiguration).\"ConnectionCountPerRssNetworkInterface\" -eq ${smb_client_connection_count_per_rss_interface}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure present - ConnectionCountPerRdmaNetworkInterface':
      command   => "\
if((get-itemproperty -Path \"HKLM:\\System\\CurrentControlSet\\Services\\LanmanWorkstation\\Parameters\" ConnectionCountPerRdmaNetworkInterface) -eq \$null)\
{New-ItemProperty -Path \"HKLM:\\System\\CurrentControlSet\\Services\\LanmanWorkstation\\Parameters\" -Name ConnectionCountPerRdmaNetworkInterface -PropertyType \"DWord\" -Value ${smb_client_connection_count_per_rdma_interface} -Force;}\
else{Set-ItemProperty -Path \"HKLM:\\System\\CurrentControlSet\\Services\\LanmanWorkstation\\Parameters\" ConnectionCountPerRdmaNetworkInterface -Value ${smb_client_connection_count_per_rdma_interface} -Force;}",
      unless    => "\
if((get-itemproperty -Path \"HKLM:\\System\\CurrentControlSet\\Services\\LanmanWorkstation\\Parameters\" ConnectionCountPerRdmaNetworkInterface) -eq \$null){exit 1;}\
if((Get-ItemProperty -Path \"HKLM:\\System\\CurrentControlSet\\Services\\LanmanWorkstation\\Parameters\").ConnectionCountPerRdmaNetworkInterface -eq ${smb_client_connection_count_per_rdma_interface}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure present - MaximumConnectionCountPerServer':
      command   => "Set-SmbClientConfiguration -MaximumConnectionCountPerServer ${smb_client_connection_count_per_server_max} -force",
      unless    => "if((Get-SmbClientConfiguration).\"MaximumConnectionCountPerServer\" -eq ${smb_client_connection_count_per_server_max}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure present - DormantDirectoryTimeout':
      command   => "\
if((get-itemproperty -Path \"HKLM:\\System\\CurrentControlSet\\Services\\LanmanWorkstation\\Parameters\" DormantDirectoryTimeout) -eq \$null)\
{New-ItemProperty -Path \"HKLM:\\System\\CurrentControlSet\\Services\\LanmanWorkstation\\Parameters\" -Name DormantDirectoryTimeout -PropertyType \"DWord\" -Value ${smb_client_dormant_directory_timeout_seconds} -Force;}\
else{Set-ItemProperty -Path \"HKLM:\\System\\CurrentControlSet\\Services\\LanmanWorkstation\\Parameters\" DormantDirectoryTimeout -Value ${smb_client_dormant_directory_timeout_seconds} -Force;}",
      unless    => "\
if((get-itemproperty -Path \"HKLM:\\System\\CurrentControlSet\\Services\\LanmanWorkstation\\Parameters\" DormantDirectoryTimeout) -eq \$null){exit 1;}\
if((Get-ItemProperty -Path \"HKLM:\\System\\CurrentControlSet\\Services\\LanmanWorkstation\\Parameters\").DormantDirectoryTimeout -eq ${smb_client_dormant_directory_timeout_seconds}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure present - FileInfoCacheLifetime':
      command   => "Set-SmbClientConfiguration -FileInfoCacheLifetime ${smb_client_file_info_cache_lifetime_seconds} -force",
      unless    => "if((Get-SmbClientConfiguration).\"FileInfoCacheLifetime\" -eq ${smb_client_file_info_cache_lifetime_seconds}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure present - DirectoryCacheLifetime':
      command   => "Set-SmbClientConfiguration -DirectoryCacheLifetime ${smb_client_directory_cache_lifetime_seconds} -force",
      unless    => "if((Get-SmbClientConfiguration).\"DirectoryCacheLifetime\" -eq ${smb_client_directory_cache_lifetime_seconds}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure present - DirectoryCacheEntrySizeMax':
      command   => "Set-SmbClientConfiguration -DirectoryCacheEntrySizeMax ${smb_client_directory_cache_entry_size_max_bytes} -force",
      unless    => "if((Get-SmbClientConfiguration).\"DirectoryCacheEntrySizeMax\" -eq ${smb_client_directory_cache_entry_size_max_bytes}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure present - DirectoryCacheEntriesMax':
      command   => "Set-SmbClientConfiguration -DirectoryCacheEntriesMax ${smb_client_directory_cache_entries_max} -force",
      unless    => "if((Get-SmbClientConfiguration).\"DirectoryCacheEntriesMax\" -eq ${smb_client_directory_cache_entries_max}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure present - FileNotFoundCacheLifetime':
      command   => "Set-SmbClientConfiguration -FileNotFoundCacheLifetime ${smb_client_file_not_found_cache_lifetime_seconds} -force",
      unless    => "if((Get-SmbClientConfiguration).\"FileNotFoundCacheLifetime\" -eq ${smb_client_file_not_found_cache_lifetime_seconds}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure present - EnableBandwidthThrottling':
      command   => "Set-SmbClientConfiguration -EnableBandwidthThrottling \$${smb_client_enable_bandwidth_throttling} -force",
      unless    => "if((Get-SmbClientConfiguration).\"EnableBandwidthThrottling\" -eq \$${smb_client_enable_bandwidth_throttling}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure present - EnableLargeMtu':
      command   => "Set-SmbClientConfiguration -EnableLargeMtu \$${smb_client_enable_large_mtu} -force",
      unless    => "if((Get-SmbClientConfiguration).\"EnableLargeMtu\" -eq \$${smb_client_enable_large_mtu}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure present - EnableByteRangeLockingOnReadOnlyFiles':
      command   => "Set-SmbClientConfiguration -EnableByteRangeLockingOnReadOnlyFiles \$${smb_client_enable_byte_range_locking_read_only_files} -force",
      unless    => "if((Get-SmbClientConfiguration).\"EnableByteRangeLockingOnReadOnlyFiles\" -eq \$${smb_client_enable_byte_range_locking_read_only_files}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure present - EnableMultiChannel':
      command   => "Set-SmbClientConfiguration -EnableMultiChannel \$${smb_client_enable_multichannel} -force",
      unless    => "if((Get-SmbClientConfiguration).\"EnableMultiChannel\" -eq \$${smb_client_enable_multichannel}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure present - ExtendedSessionTimeout':
      command   => "Set-SmbClientConfiguration -ExtendedSessionTimeout ${smb_client_extended_session_timeout_seconds} -force",
      unless    => "if((Get-SmbClientConfiguration).\"ExtendedSessionTimeout\" -eq ${smb_client_extended_session_timeout_seconds}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure present - FileInfoCacheEntriesMax':
      command   => "Set-SmbClientConfiguration -FileInfoCacheEntriesMax ${smb_client_file_info_cache_entries_max} -force",
      unless    => "if((Get-SmbClientConfiguration).\"FileInfoCacheEntriesMax\" -eq ${smb_client_file_info_cache_entries_max}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure present - FileNotFoundCacheEntriesMax':
      command   => "Set-SmbClientConfiguration -FileNotFoundCacheEntriesMax ${smb_client_file_not_found_cache_entries_max} -force",
      unless    => "if((Get-SmbClientConfiguration).\"FileNotFoundCacheEntriesMax\" -eq ${smb_client_file_not_found_cache_entries_max}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure present - MaxCmds':
      command   => "Set-SmbClientConfiguration -MaxCmds ${smb_client_max_commands} -force",
      unless    => "if((Get-SmbClientConfiguration).\"MaxCmds\" -eq ${smb_client_max_commands}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure present - KeepConn':
      command   => "Set-SmbClientConfiguration -KeepConn ${smb_client_keep_connection_seconds} -force",
      unless    => "if((Get-SmbClientConfiguration).\"KeepConn\" -eq ${smb_client_keep_connection_seconds}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure present - OplocksDisabled':
      command   => "Set-SmbClientConfiguration -OplocksDisabled \$${smb_client_oplocks_disabled} -force",
      unless    => "if((Get-SmbClientConfiguration).\"OplocksDisabled\" -eq \$${smb_client_oplocks_disabled}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure present - SessionTimeout':
      command   => "Set-SmbClientConfiguration -SessionTimeout ${smb_client_session_timeout_seconds} -force",
      unless    => "if((Get-SmbClientConfiguration).\"SessionTimeout\" -eq ${smb_client_session_timeout_seconds}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure present - UseOpportunisticLocking':
      command   => "Set-SmbClientConfiguration -UseOpportunisticLocking \$${smb_client_use_opportunistic_locking} -force",
      unless    => "if((Get-SmbClientConfiguration).\"UseOpportunisticLocking\" -eq \$${smb_client_use_opportunistic_locking}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure present - WindowSizeThreshold':
      command   => "Set-SmbClientConfiguration -WindowSizeThreshold ${smb_client_window_size_threshold} -force",
      unless    => "if((Get-SmbClientConfiguration).\"WindowSizeThreshold\" -eq ${smb_client_window_size_threshold}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure present - DormantFileLimit':
      command   => "Set-SmbClientConfiguration -DormantFileLimit ${smb_client_dormant_file_limit} -force",
      unless    => "if((Get-SmbClientConfiguration).\"DormantFileLimit\" -eq ${smb_client_dormant_file_limit}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }
  } else {
    exec { 'ensure default - ConnectionCountPerNetworkInterface':
      command   => "\
if((get-itemproperty -Path \"HKLM:\\System\\CurrentControlSet\\Services\\LanmanWorkstation\\Parameters\" ConnectionCountPerNetworkInterface) -eq \$null)\
{New-ItemProperty -Path \"HKLM:\\System\\CurrentControlSet\\Services\\LanmanWorkstation\\Parameters\" -Name ConnectionCountPerNetworkInterface -PropertyType \"DWord\" -Value 1 -Force;}\
else{Set-ItemProperty -Path \"HKLM:\\System\\CurrentControlSet\\Services\\LanmanWorkstation\\Parameters\" ConnectionCountPerNetworkInterface -Value 1 -Force;}",
      unless    => "\
if((get-itemproperty -Path \"HKLM:\\System\\CurrentControlSet\\Services\\LanmanWorkstation\\Parameters\" ConnectionCountPerNetworkInterface) -eq \$null){exit 1;}\
if((Get-ItemProperty -Path \"HKLM:\\System\\CurrentControlSet\\Services\\LanmanWorkstation\\Parameters\").ConnectionCountPerNetworkInterface -eq 1){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure default - ConnectionCountPerRssNetworkInterface':
      command   => 'Set-SmbClientConfiguration -ConnectionCountPerRssNetworkInterface 4 -force',
      unless    => "if((Get-SmbClientConfiguration).\"ConnectionCountPerRssNetworkInterface\" -eq 4){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure default - ConnectionCountPerRdmaNetworkInterface':
      command   => "\
if((get-itemproperty -Path \"HKLM:\\System\\CurrentControlSet\\Services\\LanmanWorkstation\\Parameters\" ConnectionCountPerRdmaNetworkInterface) -eq \$null)\
{New-ItemProperty -Path \"HKLM:\\System\\CurrentControlSet\\Services\\LanmanWorkstation\\Parameters\" -Name ConnectionCountPerRdmaNetworkInterface -PropertyType \"DWord\" -Value 2 -Force;}\
else{Set-ItemProperty -Path \"HKLM:\\System\\CurrentControlSet\\Services\\LanmanWorkstation\\Parameters\" ConnectionCountPerRdmaNetworkInterface -Value 2 -Force;}",
      unless    => "\
if((get-itemproperty -Path \"HKLM:\\System\\CurrentControlSet\\Services\\LanmanWorkstation\\Parameters\" ConnectionCountPerRdmaNetworkInterface) -eq \$null){exit 1;}\
if((Get-ItemProperty -Path \"HKLM:\\System\\CurrentControlSet\\Services\\LanmanWorkstation\\Parameters\").ConnectionCountPerRdmaNetworkInterface -eq 2){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure default - MaximumConnectionCountPerServer':
      command   => 'Set-SmbClientConfiguration -MaximumConnectionCountPerServer 32 -force',
      unless    => "if((Get-SmbClientConfiguration).\"MaximumConnectionCountPerServer\" -eq 32){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure default - DormantDirectoryTimeout':
      command   => "\
if((get-itemproperty -Path \"HKLM:\\System\\CurrentControlSet\\Services\\LanmanWorkstation\\Parameters\" DormantDirectoryTimeout) -eq \$null)\
{New-ItemProperty -Path \"HKLM:\\System\\CurrentControlSet\\Services\\LanmanWorkstation\\Parameters\" -Name DormantDirectoryTimeout -PropertyType \"DWord\" -Value 600 -Force;}\
else{Set-ItemProperty -Path \"HKLM:\\System\\CurrentControlSet\\Services\\LanmanWorkstation\\Parameters\" DormantDirectoryTimeout -Value 600 -Force;}",
      unless    => "\
if((get-itemproperty -Path \"HKLM:\\System\\CurrentControlSet\\Services\\LanmanWorkstation\\Parameters\" DormantDirectoryTimeout) -eq \$null){exit 1;}\
if((Get-ItemProperty -Path \"HKLM:\\System\\CurrentControlSet\\Services\\LanmanWorkstation\\Parameters\").DormantDirectoryTimeout -eq 600){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure default - FileInfoCacheLifetime':
      command   => 'Set-SmbClientConfiguration -FileInfoCacheLifetime 10 -force',
      unless    => "if((Get-SmbClientConfiguration).\"FileInfoCacheLifetime\" -eq 10){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure default - DirectoryCacheLifetime':
      command   => 'Set-SmbClientConfiguration -DirectoryCacheLifetime 10 -force',
      unless    => "if((Get-SmbClientConfiguration).\"DirectoryCacheLifetime\" -eq 10){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure default - DirectoryCacheEntrySizeMax':
      command   => 'Set-SmbClientConfiguration -DirectoryCacheEntrySizeMax 65536 -force',
      unless    => "if((Get-SmbClientConfiguration).\"DirectoryCacheEntrySizeMax\" -eq 65536){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure default - DirectoryCacheEntriesMax':
      command   => 'Set-SmbClientConfiguration -DirectoryCacheEntriesMax 16 -force',
      unless    => "if((Get-SmbClientConfiguration).\"DirectoryCacheEntriesMax\" -eq 16){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure default - FileNotFoundCacheLifetime':
      command   => 'Set-SmbClientConfiguration -FileNotFoundCacheLifetime 5 -force',
      unless    => "if((Get-SmbClientConfiguration).\"FileNotFoundCacheLifetime\" -eq 5){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure default - EnableBandwidthThrottling':
      command   => "Set-SmbClientConfiguration -EnableBandwidthThrottling \$true -force",
      unless    => "if((Get-SmbClientConfiguration).\"EnableBandwidthThrottling\" -eq \$true){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure default - EnableLargeMtu':
      command   => "Set-SmbClientConfiguration -EnableLargeMtu \$true -force",
      unless    => "if((Get-SmbClientConfiguration).\"EnableLargeMtu\" -eq \$true){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure default - EnableByteRangeLockingOnReadOnlyFiles':
      command   => "Set-SmbClientConfiguration -EnableByteRangeLockingOnReadOnlyFiles \$true -force",
      unless    => "if((Get-SmbClientConfiguration).\"EnableByteRangeLockingOnReadOnlyFiles\" -eq \$true){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure default - EnableMultiChannel':
      command   => "Set-SmbClientConfiguration -EnableMultiChannel \$true -force",
      unless    => "if((Get-SmbClientConfiguration).\"EnableMultiChannel\" -eq \$true){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure default - ExtendedSessionTimeout':
      command   => 'Set-SmbClientConfiguration -ExtendedSessionTimeout 1000 -force',
      unless    => "if((Get-SmbClientConfiguration).\"ExtendedSessionTimeout\" -eq 1000){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure default - FileInfoCacheEntriesMax':
      command   => 'Set-SmbClientConfiguration -FileInfoCacheEntriesMax 64 -force',
      unless    => "if((Get-SmbClientConfiguration).\"FileInfoCacheEntriesMax\" -eq 64){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure default - FileNotFoundCacheEntriesMax':
      command   => 'Set-SmbClientConfiguration -FileNotFoundCacheEntriesMax 128 -force',
      unless    => "if((Get-SmbClientConfiguration).\"FileNotFoundCacheEntriesMax\" -eq 128){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure default - MaxCmds':
      command   => 'Set-SmbClientConfiguration -MaxCmds 50 -force',
      unless    => "if((Get-SmbClientConfiguration).\"MaxCmds\" -eq 50){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure default - KeepConn':
      command   => 'Set-SmbClientConfiguration -KeepConn 600 -force',
      unless    => "if((Get-SmbClientConfiguration).\"KeepConn\" -eq 600){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure default - OplocksDisabled':
      command   => "Set-SmbClientConfiguration -OplocksDisabled \$false -force",
      unless    => "if((Get-SmbClientConfiguration).\"OplocksDisabled\" -eq \$false}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure default - SessionTimeout':
      command   => 'Set-SmbClientConfiguration -SessionTimeout 60 -force',
      unless    => "if((Get-SmbClientConfiguration).\"SessionTimeout\" -eq 60){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure default - UseOpportunisticLocking':
      command   => "Set-SmbClientConfiguration -UseOpportunisticLocking \$true -force",
      unless    => "if((Get-SmbClientConfiguration).\"UseOpportunisticLocking\" -eq \$true){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure default - WindowSizeThreshold':
      command   => 'Set-SmbClientConfiguration -WindowSizeThreshold 8 -force',
      unless    => "if((Get-SmbClientConfiguration).\"WindowSizeThreshold\" -eq 8){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure default - DormantFileLimit':
      command   => 'Set-SmbClientConfiguration -DormantFileLimit 1023 -force',
      unless    => "if((Get-SmbClientConfiguration).\"DormantFileLimit\" -eq 1023){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }
  }

}
