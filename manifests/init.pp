class windows_smb {
  include ::windows_smb::features::prerequisites

  # TODO: write feature classes to ensure windows file sharing installed ^ in there

  # caller responsible for proper file resource creation to ensure that the directory being shared exists.  make
  # windows_smb::manage_smb_share depend on that file resource
  file { 'c:\temp1': ensure => directory, }

  # the below will result in creation of two shares of path 'c:\temp1':
  # testshare and testshare1 - both with have the local 'administrators' group assigned 'full' permissions

  windows_smb::manage_smb_share { 'testshare':
    ensure                            => present,
    smb_share_directory               => 'c:\temp1',
    smb_share_comments                => 'puppet generated smb share test via call of init.pp',
    smb_share_concurrent_user_limit   => 0,
    smb_share_cache                   => 'None',
    smb_share_encrypt_data            => false,
    smb_share_folder_enum_mode        => 'AccessBased',
    smb_share_temporary               => true,
    smb_share_access_full             => ['Everyone'],
    smb_share_access_change           => [],
    smb_share_access_read             => [],
    smb_share_access_deny             => [],
    smb_share_autoinstall_branchcache => false,
    require                           => File['c:\temp1'],
  }

  # with defaults - note ensure is assumed => 'present'
  windows_smb::manage_smb_share { 'testshare1':
    smb_share_directory   => 'c:\temp1',
    smb_share_access_full => ['Everyone'],
    require               => File['c:\temp1'],
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

  #windows_smb::manage_smb_server_config { $::clientcert: ensure => default,}

  windows_smb::manage_smb_client_config{$::clientcert:
  ensure                                               => 'present',
  smb_client_connection_count_per_interface            => 16,
  smb_client_connection_count_per_rss_interface        => 16,
  smb_client_connection_count_per_rdma_interface       => 16,
  smb_client_connection_count_per_server_max           => 64,
  smb_client_dormant_directory_timeout_seconds         => 500,
  smb_client_directory_cache_lifetime_seconds          => 15,
  smb_client_dormant_file_limit                        => 4096,
  smb_client_directory_cache_entry_size_max_bytes      => 65580,
  smb_client_file_not_found_cache_lifetime_seconds     => 5,
  smb_client_file_not_found_cache_entries_max          => 2048,
  smb_client_file_info_cache_lifetime_seconds          => 5,
  smb_client_file_info_cache_entries_max               => 1024,
  smb_client_enable_bandwidth_throttling               => false,
  smb_client_enable_large_mtu                          => false,
  smb_client_enable_byte_range_locking_read_only_files => false,
  smb_client_enable_multichannel                       => false,
  smb_client_extended_session_timeout_seconds          => 999,
  smb_client_keep_connection_seconds                   => 555,
  smb_client_max_commands                              => 8192,
  smb_client_oplocks_disabled                          => true,
  smb_client_session_timeout_seconds                   => 45,
  smb_client_use_opportunistic_locking                 => false,
  smb_client_window_size_threshold                     => 16
  }

  #windows_smb::manage_smb_client_config{$::clientcert: ensure => default,}


}
