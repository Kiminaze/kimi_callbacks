fx_version 'cerulean'
games { 'gta5' }

author 'Philipp Decker'
description 'Easy to use server and client callbacks!'
version '1.0'

server_scripts {
	'server/ServerCallback.lua'
}

client_scripts {
	'client/ClientCallback.lua'
}

server_exports {
	'Register',
	'Trigger',
	'TriggerWithTimeout'
}

exports {
	'Register',
	'Trigger',
	'TriggerWithTimeout'
}
