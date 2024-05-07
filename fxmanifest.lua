
fx_version "cerulean"
games { "gta5" }

author "Philipp Decker"
description "Easy to use server and client callbacks!"
version "1.4.0"

lua54 "yes"

server_scripts {
	"server/versionChecker.lua",
	"server/ServerCallback.lua"
}

client_scripts {
	"client/ClientCallback.lua"
}
