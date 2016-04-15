class windows_smb {
  include ::windows_smb::features::prerequisites

  # TODO: write feature classes to ensure windows file sharing installed ^ in there

  # caller responsible for proper file resource creation to ensure that the directory being shared exists.  make
  # windows_smb::manage_smb_share depend on that file resource
  file { 'c:\temp1': ensure => directory, }

  # the below will result in creation of two shares of path 'c:\temp1':
  # testshare and testshare1 - both with have the local 'administrators' group assigned 'full' permissions

  windows_smb::manage_smb_share { 'testshare':
    ensure                                        => present,
    smb_share_directory                           => 'c:\temp1',
    smb_share_comments                            => 'puppet generated smb share test via call of init.pp',
    smb_share_concurrent_user_limit               => 0,
    smb_share_cache                               => 'None',
    smb_share_encrypt_data                        => false,
    smb_share_folder_enum_mode                    => 'AccessBased',
    smb_share_temporary                           => true,
    smb_share_access_full                         => ['Everyone'],
    smb_share_access_change                       => [],
    smb_share_access_read                         => [],
    smb_share_access_deny                         => [],
    smb_share_autoinstall_branchcache             => false,
    require                                       => File['c:\temp1'],
  }

  # with defaults - note ensure is assumed => 'present'
  windows_smb::manage_smb_share { 'testshare1':
    smb_share_directory                           => 'c:\temp1',
    smb_share_access_full                         => ['Everyone'],
    require                                       => File['c:\temp1'],
  }

  # server smb config settings example - note the 'title' / resource name isn't used in class
  # note that cannot set ensure to 'absent' as many of these settings REQUIRED for os to function properly - set ensure => 'default'
  # to reset to defaults
  windows_smb::manage_smb_server_config { $::clientcert:
    ensure                                        => present,
    smb_server_asynchronous_credits               => 1024,
    smb_server_smb2_credits_min                   => 1024,
    smb_server_smb2_credits_max                   => 16384,
    smb_server_max_threads_per_queue              => 64,
    smb_server_treat_host_as_stable_storage       => true,
    smb_server_max_channel_per_session            => 32,
    smb_server_additional_critical_worker_threads => 20,
    smb_server_additional_delayed_worker_threads  => 20,
    smb_server_ntfs_8dot3_name_creation           => 'disabled',
    smb_server_ntfs_disable_last_access_update    => true,
  }
}
