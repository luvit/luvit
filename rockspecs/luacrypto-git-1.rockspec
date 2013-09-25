package = "LuaCrypto"
version = "git-1"
description = {
	summary = "A Lua frontend to OpenSSL",
	detailed = [[LuaCrypto is a Lua frontend to the OpenSSL cryptographic library. The OpenSSL features that are currently exposed are: 
digests (MD5, SHA-1, HMAC, and more), encryption, decryption and crypto-grade random number generators.]],
	homepage = "http://mkottman.github.com/luacrypto/",
	license = "MIT",
}
dependencies = {
	"lua >= 5.1",
}
source = {
	url = [[git://github.com/mkottman/luacrypto.git]],
	dir = "luacrypto"
}
build = {
	platforms = {
		windows = {
			type = "command",
			build_command = [[vcbuild ./luacrypto.vcproj Release /useenv /rebuild]],
			install_command = [[copy ".\Release\crypto.dll" "$(LIBDIR)\crypto.dll" /y ]]
		},
		unix = {
			type = "make",
			variables = {
				INCONCERT_DEVEL = "$(INCONCERT_DEVEL)",
				LUA_LUADIR = "$(LUADIR)",
				LUA_LIBDIR = "$(LIBDIR)",
				LUA_PREFIX  = "$(PREFIX)"
			}
		}
	},
	copy_directories = { "doc" }
}
