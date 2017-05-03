#2017-05-03 - Release 0.4.2

needing this one again... fixed some bad client settings stuff for oplocks which doesnt seem to exist in 2016 at the very least... 

#2016-04-26 - Release 0.4.1

##NOTE NEW DEPENDENCY ON `puppetlabs_registry` as of 0.4.0 - see metadata.json

###Features
 -  N/A

###Bugfixes
 -  incorrect code block placement for registry defaults in `windows_smb::manage_client_config` - would cause ensure => default resource create to fail, fixed.
 -  doc typos fix

###Improvements
 - N/A

#2016-04-26 - Release 0.4.0

##NOTE NEW DEPENDENCY ON `puppetlabs_registry` - see metadata.json

###Features
 - complete rework of resources to manage `windows_smb::manage_client_config` and `windows_smb::manage_server_config` - now like 10x faster to apply due to direct reg mod and its providers direct interface with win APIs

###Bugfixes
 -  N/A

###Improvements
 - significant optimization of `windows_smb::manage_client_config` and `windows_smb::manage_server_config`

#2016-04-13 - Release 0.3.0

###Features
 - added documentation for `windows_smb::manage_smb_client_config`.
 - __improvements! many things for `managing smb client settings` on windows added - have fun!__

###Bugfixes
 -  N/A

###Improvements
 - many things for `managing smb client settings` on windows added

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

##Initial release - NOTE SUPPORT FOR SMB CLIENT AND SERVER SETTINGS NOT YET IMPLEMENTED - `windows_smb::manage_smb_share` ok to use

###Features
 - added support for managing smb shares on windows systems

###Bugfixes
 - N/A

###Improvements
 - N/A

