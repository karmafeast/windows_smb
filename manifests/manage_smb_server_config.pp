define windows_smb::manage_smb_server_config (
  $ensure                                        = 'present',
  $smb_server_asynchronous_credits               = 512,
  $smb_server_smb2_credits_min                   = 512,
  $smb_server_smb2_credits_max                   = 8192,
  $smb_server_max_threads_per_queue              = 20,
  $smb_server_treat_host_as_stable_storage       = false,
  $smb_server_max_channel_per_session            = 32,
  $smb_server_max_session_per_connection         = 16384,
  $smb_server_additional_critical_worker_threads = 0,
  $smb_server_additional_delayed_worker_threads  = 0,
  $smb_server_ntfs_8dot3_name_creation           = undef,
  $smb_server_ntfs_disable_last_access_update    = undef) {
  if (!$::osfamily == 'windows') {
    fail('cannot run windows_smb::manage_smb_server_config against non-windows OS platform')
  }

  validate_re($ensure, '^(present|default)$', 'ensure must be one of \'present\', \'default\'')

  validate_integer($smb_server_asynchronous_credits, 4294967295, 1)
  validate_integer($smb_server_smb2_credits_min, 4294967295, 1)
  validate_integer($smb_server_smb2_credits_max, 4294967295, $smb_server_smb2_credits_min)
  validate_integer($smb_server_smb2_credits_min, $smb_server_smb2_credits_max, 1)
  validate_integer($smb_server_max_threads_per_queue, 4294967295, 1)
  validate_integer($smb_server_max_channel_per_session, 4294967295, 1)
  validate_integer($smb_server_max_session_per_connection, 4294967295, 1)
  validate_bool($smb_server_treat_host_as_stable_storage)

  validate_integer($smb_server_additional_critical_worker_threads, 4294967295, 0)
  validate_integer($smb_server_additional_delayed_worker_threads, 4294967295, 0)

  if ($smb_server_ntfs_8dot3_name_creation == undef) {
    $process_ntfs_8dot3 = false
  } else {
    validate_re($smb_server_ntfs_8dot3_name_creation, '^(0|1|2|enabled|disabled|per_volume)$', 'ensure must be one of \'0\', \'1\', \'2\', \'enabled\', \'disabled\', \'per_volume\''
    )
    $process_ntfs_8dot3 = true

    case $smb_server_ntfs_8dot3_name_creation {
      '0', 'enabled'    : {
        $nfts_8dot3_int = 0
      }
      '1', 'disabled'   : {
        $nfts_8dot3_int = 1
      }
      '2', 'per_volume' : {
        $nfts_8dot3_int = 2
      }
      default           : {
        fail('reached default case for 8dot3 name creation - should have been caught by validate_re - logic failure')
      }
    }
  }

  if ($smb_server_ntfs_disable_last_access_update == undef) {
    $process_ntfs_disable_last_access_update = false
  } else {
    validate_bool($smb_server_ntfs_disable_last_access_update)
    $process_ntfs_disable_last_access_update = true

    if ($smb_server_ntfs_disable_last_access_update) {
      $ntfs_disable_last_access_update_int = 1
    } else {
      $ntfs_disable_last_access_update_int = 0
    }
  }

  if ($ensure == 'present') {
    exec { 'ensure present - AsynchronousCredits':
      command   => "Set-SmbServerConfiguration -AsynchronousCredits ${smb_server_asynchronous_credits} -force",
      unless    => "if((Get-SmbServerConfiguration).\"AsynchronousCredits\" -eq ${smb_server_asynchronous_credits}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure present - Smb2CreditsMin':
      command   => "Set-SmbServerConfiguration -Smb2CreditsMin ${smb_server_smb2_credits_min} -force",
      unless    => "if((Get-SmbServerConfiguration).\"Smb2CreditsMin\" -eq ${smb_server_smb2_credits_min}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure present - Smb2CreditsMax':
      command   => "Set-SmbServerConfiguration -Smb2CreditsMax ${smb_server_smb2_credits_max} -force",
      unless    => "if((Get-SmbServerConfiguration).\"Smb2CreditsMax\" -eq ${smb_server_smb2_credits_max}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure present - MaxThreadsPerQueue':
      command   => "Set-SmbServerConfiguration -MaxThreadsPerQueue ${smb_server_max_threads_per_queue} -force",
      unless    => "if((Get-SmbServerConfiguration).\"MaxThreadsPerQueue\" -eq ${smb_server_max_threads_per_queue}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure present - TreatHostAsStableStorage':
      command   => "Set-SmbServerConfiguration -TreatHostAsStableStorage \$${smb_server_treat_host_as_stable_storage} -force",
      unless    => "if((Get-SmbServerConfiguration).\"TreatHostAsStableStorage\" -eq \$${smb_server_treat_host_as_stable_storage}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure present - MaxChannelPerSession':
      command   => "Set-SmbServerConfiguration -MaxChannelPerSession ${smb_server_max_channel_per_session} -force",
      unless    => "if((Get-SmbServerConfiguration).\"MaxChannelPerSession\" -eq ${smb_server_max_channel_per_session}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure present - MaxSessionPerConnection':
      command   => "Set-SmbServerConfiguration -MaxSessionPerConnection ${smb_server_max_session_per_connection} -force",
      unless    => "if((Get-SmbServerConfiguration).\"MaxSessionPerConnection\" -eq ${smb_server_max_session_per_connection}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure present - AdditionalCriticalWorkerThreads':
      command   => "Set-ItemProperty -Path \"HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Executive\" AdditionalCriticalWorkerThreads -Value ${smb_server_additional_critical_worker_threads} -Force",
      unless    => "if((Get-ItemProperty -Path \"HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Executive\").AdditionalCriticalWorkerThreads -eq ${smb_server_additional_critical_worker_threads}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure present - AdditionalDelayedWorkerThreads':
      command   => "Set-ItemProperty -Path \"HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Executive\" AdditionalDelayedWorkerThreads -Value ${smb_server_additional_delayed_worker_threads} -Force",
      unless    => "if((Get-ItemProperty -Path \"HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Executive\").AdditionalDelayedWorkerThreads -eq ${smb_server_additional_delayed_worker_threads}){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    if ($process_ntfs_8dot3) {
      exec { 'ensure present - NtfsDisable8dot3NameCreation':
        command   => "Set-ItemProperty -Path \"HKLM:\\SYSTEM\\CurrentControlSet\\Control\\FileSystem\" NtfsDisable8dot3NameCreation -Value ${nfts_8dot3_int} -Force",
        unless    => "if((Get-ItemProperty -Path \"HKLM:\\SYSTEM\\CurrentControlSet\\Control\\FileSystem\").NtfsDisable8dot3NameCreation -eq ${nfts_8dot3_int}){exit 0;}else{exit 1;}",
        provider  => powershell,
        logoutput => true,
      }
    }

    if ($process_ntfs_disable_last_access_update) {
      exec { 'ensure present - NtfsDisableLastAccessUpdate':
        command   => "Set-ItemProperty -Path \"HKLM:\\SYSTEM\\CurrentControlSet\\Control\\FileSystem\" NtfsDisableLastAccessUpdate -Value ${ntfs_disable_last_access_update_int} -Force",
        unless    => "if((Get-ItemProperty -Path \"HKLM:\\SYSTEM\\CurrentControlSet\\Control\\FileSystem\").NtfsDisableLastAccessUpdate -eq ${ntfs_disable_last_access_update_int}){exit 0;}else{exit 1;}",
        provider  => powershell,
        logoutput => true,
      }
    }

  } else {
    exec { 'ensure default - AsynchronousCredits':
      command   => 'Set-SmbServerConfiguration -AsynchronousCredits 512 -force',
      unless    => "if((Get-SmbServerConfiguration).\"AsynchronousCredits\" -eq 512){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure default - Smb2CreditsMin':
      command   => 'Set-SmbServerConfiguration -Smb2CreditsMin 512 -force',
      unless    => "if((Get-SmbServerConfiguration).\"Smb2CreditsMin\" -eq 512){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure default - Smb2CreditsMax':
      command   => 'Set-SmbServerConfiguration -Smb2CreditsMax 8192 -force',
      unless    => "if((Get-SmbServerConfiguration).\"Smb2CreditsMax\" -eq 8192){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure default - MaxThreadsPerQueue':
      command   => 'Set-SmbServerConfiguration -MaxThreadsPerQueue 20 -force',
      unless    => "if((Get-SmbServerConfiguration).\"MaxThreadsPerQueue\" -eq 20){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure default - TreatHostAsStableStorage':
      command   => "Set-SmbServerConfiguration -TreatHostAsStableStorage \$false -force",
      unless    => "if((Get-SmbServerConfiguration).\"TreatHostAsStableStorage\" -eq \$false){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure default - MaxChannelPerSession':
      command   => 'Set-SmbServerConfiguration -MaxChannelPerSession 32 -force',
      unless    => "if((Get-SmbServerConfiguration).\"MaxChannelPerSession\" -eq 32){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure present - MaxSessionPerConnection':
      command   => 'Set-SmbServerConfiguration -MaxSessionPerConnection 16384 -force',
      unless    => "if((Get-SmbServerConfiguration).\"MaxSessionPerConnection\" -eq 16384){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure default - AdditionalCriticalWorkerThreads':
      command   => "Set-ItemProperty -Path \"HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Executive\" AdditionalCriticalWorkerThreads -Value 0 -Force",
      unless    => "if((Get-ItemProperty -Path \"HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Executive\").AdditionalCriticalWorkerThreads -eq 0){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure default - AdditionalDelayedWorkerThreads':
      command   => "Set-ItemProperty -Path \"HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Executive\" AdditionalDelayedWorkerThreads -Value 0 -Force",
      unless    => "if((Get-ItemProperty -Path \"HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Executive\").AdditionalDelayedWorkerThreads -eq 0){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure default - NtfsDisable8dot3NameCreation':
      command   => "Set-ItemProperty -Path \"HKLM:\\SYSTEM\\CurrentControlSet\\Control\\FileSystem\" NtfsDisable8dot3NameCreation -Value 2 -Force",
      unless    => "if((Get-ItemProperty -Path \"HKLM:\\SYSTEM\\CurrentControlSet\\Control\\FileSystem\").NtfsDisable8dot3NameCreation -eq 2){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

    exec { 'ensure present - NtfsDisableLastAccessUpdate':
      command   => "Set-ItemProperty -Path \"HKLM:\\SYSTEM\\CurrentControlSet\\Control\\FileSystem\" NtfsDisableLastAccessUpdate -Value 1 -Force",
      unless    => "if((Get-ItemProperty -Path \"HKLM:\\SYSTEM\\CurrentControlSet\\Control\\FileSystem\").NtfsDisableLastAccessUpdate -eq 1){exit 0;}else{exit 1;}",
      provider  => powershell,
      logoutput => true,
    }

  }

}
