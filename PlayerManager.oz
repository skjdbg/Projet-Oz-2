functor
import
	Player072Random
	PlayerBasicAI
export
	playerGenerator:PlayerGenerator
define
	PlayerGenerator
in
	fun{PlayerGenerator Kind Color ID}
		case Kind
		of player072random then {Player072Random.portPlayer Color ID}
		[] player then {PlayerBasicAI.portPlayer Color ID}
		end
	end
end
