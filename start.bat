:restart
	echo @Restart server
	luajit start.lua
	goto :restart