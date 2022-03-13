# Cold Path Server Sources


Cold Path is turn-based multiplayer strategy game

You can start your own global server and play with players from all over the world.

The game server is highly customizable, you can customize it the way you want to create an interesting and unique server.


## How to use


Detailed guide versions:

[EN] https://book.denismakhortov.com/server/summary

[RU] https://book.denismakhortov.com/v/ru/server/summary


## Differences of this server from the built-in game


* "builtins.scripts.socket" to "socket" in require tcp_server.lua
* turn on plugins "essentials", "afk", "game_switch"
* move "admins.dat" from folder "server_data" to root
* remove save_system
* remove udp modules


## Why doesn't this repository have a clear commit history?


The server is the core of the game with some scripts, this repository is not used for development. The commit history will not display the changes. The server is built from the source of the game
