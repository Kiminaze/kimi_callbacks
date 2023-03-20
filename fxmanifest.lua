fx_version "cerulean"
games { "gta5" }

author "Philipp Decker"
description "Easy to use server and client callbacks!"
version "1.3.0"

lua54 "yes"

server_scripts {
	"server/ServerCallback.lua"
}

client_scripts {
	"client/ClientCallback.lua"
}
