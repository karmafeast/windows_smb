class windows_smb {
  include ::windows_smb::features::prerequisites

  # TODO: write feature classes to ensure windows file sharing installed ^ in there

  # caller responsible for proper file resource creation to ensure that the directory being shared exists.  make
  # windows_smb::manage_smb_share depend on that file resource
  file { 'c:\temp1': ensure => directory, }

  # the below will result in creation of two shares of path 'c:\temp1':
  # testshare and testshare1 - both with have the local 'administrators' group assigned 'full' permissions

  windows_smb::manage_smb_share { 'testshare':
    smb_share_directory               => 'c:\temp1',
    ensure  => present,
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
    require => File['c:\temp1'],
  }

  # with defaults - note ensure is assumed => 'present'
  windows_smb::manage_smb_share { 'testshare1':
    smb_share_directory               => 'c:\temp1',
    smb_share_access_full             => ['Everyone'],
    require                           => File['c:\temp1'],
  }

}
