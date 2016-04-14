#2016-04-13 - Release 0.2.0
###Features
 - added documentation for `windows_smb::manage_smb_server_config`.
 - bug fixes
 - __improvements!__

###Bugfixes
 - fixed validator of Uint32 for various params in `windows_smb::manage_smb_share` - was allowing out of range value.

###Improvements
 - added support for MaxSessionPerConnection control in `windows_smb::manage_smb_server_config`
 - found defaults for `smb_server_max_channel_per_session` - removed defaulting to `undef` for this param in `windows_smb::manage_smb_server_config`


#2016-04-13 - Release 0.1.3
###Features
 - added smb server settings class and example in init, documentation to come.  `windows_smb::manage_smb_server_config` safe to use.

###Bugfixes
 - N/A

###Improvements
 - N/A

#2016-04 - Release 0.1.0
###Summary

  Initial release - NOTE SUPPORT FOR SMB CLIENT AND SERVER SETTINGS NOT YET IMPLEMENTED - `windows_smb::manage_smb_share` ok to use

###Features
 - added support for managing smb shares on windows systems

###Bugfixes
 - N/A

###Improvements
 - N/A

