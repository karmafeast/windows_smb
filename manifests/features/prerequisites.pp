class windows_smb::features::prerequisites {
  # TODO: fix this up for ensuring file share crap if user calls init.pp

  fail('windows_smb::features::prerequisites is not yet implemented - do not call this')
  # ninja'd this from iis module - below is junk - fixup for pre-reqs install for file services on a windows server...
  # debating to self the invasiveness of such coding practice... its 'plug and play' but starts creating resources that may well
  # exist elsewhere in a catalog
  # I don't like it, but I may support it...
  #
  #  case $::kernelmajversion {
  #    '6.2','6.3': {
  #      ensure_resource('windowsfeature', 'IIS-ASPNET' )
  #      ensure_resource('windowsfeature', 'IIS-ASPNET45' )
  #      ensure_resource('windowsfeature', 'IIS-NetFxExtensibility' )
  #      ensure_resource('windowsfeature', 'IIS-NetFxExtensibility45' )
  #      ensure_resource('windowsfeature', 'IIS-ISAPIExtentions' )
  #      ensure_resource('windowsfeature', 'IIS-ISAPIFilter' )
  #    }
  #    '6.0','6.1': {
  #      ensure_resource('windowsfeature', 'Web-Asp-Net' )
  #      ensure_resource('windowsfeature', 'Web-Net-Ext' )
  #      ensure_resource('windowsfeature', 'Web-ISAPI-Ext' )
  #      ensure_resource('windowsfeature', 'Web-ISAPI-Filter' )
  #    }
  #    default: {
  #      fail("Do not know how to install iis windows features for ${::kernelmajversion}")
  #    }
  #  }
}
