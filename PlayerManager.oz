functor
import
	Player
export
	playerGenerator:PlayerGenerator
define
	PlayerGenerator
in
	fun{PlayerGenerator Kind Color ID}
		case Kind
		of player2 then {Player.portPlayer Color ID}
		[] player1 then {Player.portPlayer Color ID}
		end
	end
end
