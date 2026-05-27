fx_version 'cerulean'

game 'gta5'
lua54 'yes'

name 'Az-Scoreboard'
author 'Azure(TheStoicBear)'
description 'Lore-friendly NUI scoreboard backed ONLY by Az-Framework exports (jobs, names, money, admin).'
version '1.2.0'

dependency 'Az-Framework'

shared_scripts {
  'config.lua'
}

server_scripts {
  'server.lua'
}

client_scripts {
  'client.lua'
}

ui_page 'ui/index.html'

files {
  'ui/index.html',
  'ui/config.js'
}
