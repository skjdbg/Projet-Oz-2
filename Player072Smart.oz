functor
import
   Input
   OS
   System(show:Show)
export
   portPlayer:StartPlayer
define
	StartPlayer
	TreatStream
	InitPosition
	FindElem
	Move
	ValidPath
	AllPosition
	ValidPosItem
	IntList
	ContainsPt
	MoveNthInDir
	AddToNth
	InsideOut
	IsOcean
	MatchToMap
	ContainsAt
	SetNth
	DistantMine
	SetTileList
	Validate
	SendToNeighbors
	DestFunction
	TileFunction
	NewTileObject
	MapToPortObject
	PosToDir
	IsEnnemyFound
	NewWall
	WallFun
in
	% TODO
	% Stream : 
	% IDPlayer : 	either null if we have been killed or our <id> ::= id(id:<IdNum> color:<Color>)
	% Pos : 		our position pt(x:X y:Y)
	% Path : 		list of positions since last surface
	% Life : 		ammount of health left
	% IsDive : 		true if underwater, false if not
	% LoadMine : 	TODO
	% LoadMissile : TODO
	% ListMine : 	TODO
	% EPaths : 		list of the ennemies' paths. used to try and guess where they are. if an ennemy's position is known, contains only this position
	%				EPaths ::=  <List <carddirection>> '|' <EPaths>
	%							| <position> '|' <EPaths>
	%							| nil
	% EIDs : 		list of the ennemies' id. used to identify what path is whose (bijection with EPaths)
	% EFound : 		list of either true of false. true if there is one and only one possible position for the corresponding ennemy
   	proc {TreatStream Stream IDPlayer Pos Path Life IsDive LoadMine LoadMissile ListMine EPaths EIDs EFound}
		case Stream
		of nil then 
			skip
		%all case of Stream
		
		[] initPosition(?ID ?Position)|T then
			ID = IDPlayer
			
			%Choose random position in the grid to begin
			Position = {InitPosition}
			
			{TreatStream T IDPlayer Position Position|nil Input.maxDamage false LoadMine LoadMissile ListMine EPaths EIDs EFound}

		[] move(?ID ?Position ?Direction)|T then
			%TODO it sometimes makes weird moves that are not allowed ?
			% =>they don't match with the wait it really moves.
			local
				Dest = {IsEnnemyFound EPaths EFound}
			in
				ID = IDPlayer
				if Dest == nil then
					local ListMove in
						%collect the retrun list of function Move ( [direction position path IsDive] )
						ListMove = {Move Pos Path IsDive}
						%dir and pos
						Direction = ListMove.1
						Position = ListMove.2.1

						%end
						{TreatStream T IDPlayer ListMove.2.1 ListMove.2.2.1 Life ListMove.2.2.2.1 LoadMine LoadMissile ListMine EPaths EIDs EFound}
					end
				elseif {ContainsPt Path.2 Dest} then
					Position = Pos
					Direction = surface
					{TreatStream T IDPlayer Pos Pos|nil Life false LoadMine LoadMissile ListMine EPaths EIDs EFound}
				else
					local 
						Mapo = {MapToPortObject Input.map 1 1}
						Return
						ListMove
						Pathy
					in
						{SetTileList Mapo Mapo}

						{Send {Nth {Nth Mapo Dest.x} Dest.y} setAsDest(Return)}
						{Send {Nth {Nth Mapo Pos.x} Pos.y} sayCost(0 nil)}
						{Wait Return}
						%if Dest == Origin
						if Return == nil orelse Return.2 == nil then
							local ListMove in
								%collect the retrun list of function Move ( [direction position path IsDive] )
								ListMove = {Move Pos Path IsDive}
								%dir and pos
								Direction = ListMove.1
								Position = ListMove.2.1

								%end
								{TreatStream T IDPlayer ListMove.2.1 ListMove.2.2.1 Life ListMove.2.2.2.1 LoadMine LoadMissile ListMine EPaths EIDs EFound}
							end
						else

							Pathy = {InsideOut Return nil}
							Position = Pathy.2.1
							Direction = {PosToDir Pos Position}

							{TreatStream T IDPlayer Position Position|Path Life IsDive LoadMine LoadMissile ListMine EPaths EIDs EFound}
						
							/*%collect the retrun list of function Move ( [direction position path IsDive] )
							ListMove = {Move Pos Path IsDive}
							%dir and pos
							Direction = ListMove.1
							Position = ListMove.2.1

							%end
							{TreatStream T IDPlayer ListMove.2.1 ListMove.2.2.1 Life ListMove.2.2.2.1 LoadMine LoadMissile ListMine EPaths EIDs EFound}*/
						end
					end
				end
			end

		[] dive|T then
			{TreatStream T IDPlayer Pos Path Life true LoadMine LoadMissile ListMine EPaths EIDs EFound}

			%The Random Player don't use Sonar and Drone (He use only mine and missile)
		[] chargeItem(?ID ?KindItem)|T then
			ID = IDPlayer
			%check loadmine and loadmissile

			%if Mine AND Missile are Ready
			if (LoadMine == Input.mine andthen LoadMissile == Input.missile) then
				%all the possible items are already charged
				KindItem = null
				{TreatStream T IDPlayer Pos Path Life IsDive LoadMine LoadMissile ListMine EPaths EIDs EFound}

			%if Mine is charged then charge Missile
			elseif (LoadMine == Input.mine) then
				KindItem = missile
				{TreatStream T IDPlayer Pos Path Life IsDive LoadMine LoadMissile+1 ListMine EPaths EIDs EFound}

			%If Missile is charger then charge mine
			elseif (LoadMissile == Input.missile) then
				KindItem = mine
				{TreatStream T IDPlayer Pos Path Life IsDive LoadMine+1 LoadMissile ListMine EPaths EIDs EFound}

			%else choose item randomly
			else
				KindItem = {Nth [mine missile] (({OS.rand} mod 2) +1)}

				case KindItem 
				of mine then
					{TreatStream T IDPlayer Pos Path Life IsDive LoadMine+1 LoadMissile ListMine EPaths EIDs EFound}
				[] missile then
					{TreatStream T IDPlayer Pos Path Life IsDive LoadMine LoadMissile+1 ListMine EPaths EIDs EFound}
				end
			end
		
		[] fireItem(?ID ?KindFire)|T then
			ID = IDPlayer

			%no ready item
			if (LoadMine \= Input.mine andthen LoadMissile \= Input.missile) then
				KindFire = null
				{TreatStream T IDPlayer Pos Path Life IsDive LoadMine LoadMissile ListMine EPaths EIDs EFound}
			else
				local KindItem PosMatrix CorrectPos RandomPos in
					%All pos in the map
					PosMatrix = {AllPosition Input.nRow Input.nColumn Input.nColumn}
					
					%choose random item
					if (LoadMine == Input.mine andthen LoadMissile == Input.missile) then
						KindItem = {Nth [mine missile] (({OS.rand} mod 2) +1)}
						%random is mine
						case KindItem 
						of mine then
							CorrectPos = {ValidPosItem PosMatrix Pos Input.minDistanceMine Input.maxDistanceMine}
							RandomPos = {Nth CorrectPos (({OS.rand} mod {Length CorrectPos}) +1)}
							KindFire = mine(RandomPos)
							{TreatStream T IDPlayer Pos Path Life IsDive 0 LoadMissile RandomPos|ListMine EPaths EIDs EFound}

						%random is missile
						[] missile then
							%no suicide
							if Input.minDistanceMissile >= 2 then
								CorrectPos = {ValidPosItem PosMatrix Pos Input.minDistanceMissile Input.maxDistanceMissile}
							else
								CorrectPos = {ValidPosItem PosMatrix Pos 2 Input.maxDistanceMissile}
							end
							RandomPos = {Nth CorrectPos (({OS.rand} mod {Length CorrectPos}) +1)}
							KindFire = missile(RandomPos)
							{TreatStream T IDPlayer Pos Path Life IsDive LoadMine 0 ListMine EPaths EIDs EFound}
						end

					%fire mine
					elseif (LoadMine == Input.mine) then
						CorrectPos = {ValidPosItem PosMatrix Pos Input.minDistanceMine Input.maxDistanceMine}
						RandomPos = {Nth CorrectPos (({OS.rand} mod {Length CorrectPos}) +1)}
						KindFire = mine(RandomPos)
						{TreatStream T IDPlayer Pos Path Life IsDive 0 LoadMissile RandomPos|ListMine EPaths EIDs EFound}

					%fire missile
					else
						%no suicide
						if Input.minDistanceMissile >= 2 then
							CorrectPos = {ValidPosItem PosMatrix Pos Input.minDistanceMissile Input.maxDistanceMissile}
						else
							CorrectPos = {ValidPosItem PosMatrix Pos 2 Input.maxDistanceMissile}
						end
						RandomPos = {Nth CorrectPos (({OS.rand} mod {Length CorrectPos}) +1)}
						KindFire = missile(RandomPos)
						{TreatStream T IDPlayer Pos Path Life IsDive LoadMine 0 ListMine EPaths EIDs EFound}
					end
				end
			end
		[] fireMine(?ID ?Mine)|T then
			ID = IDPlayer

			local NewListMine in
				NewListMine = {DistantMine Pos ListMine}
				%check if ListMine is empty
				if {Length NewListMine} == 0 then
					Mine = null
					{TreatStream T IDPlayer Pos Path Life IsDive LoadMine LoadMissile ListMine EPaths EIDs EFound}
				else
					Mine = {Nth NewListMine (({OS.rand} mod {Length NewListMine}) +1)}
					local MineListReturn in
					MineListReturn = {List.subtract ListMine Mine}
					{TreatStream T IDPlayer Pos Path Life IsDive LoadMine LoadMissile MineListReturn EPaths EIDs EFound}
					end
				end
			end

		[] isDead(?Answer)|T then
			Answer = Life == 0
			{TreatStream T IDPlayer Pos Path Life IsDive LoadMine LoadMissile ListMine EPaths EIDs EFound}

		[] sayMissileExplode(_ Position ?Message)|T then
			local Dista in
				% Dista = Distance MissileExplode-PlayerPosition
				Dista = {Number.abs (Position.x-Pos.x)} + {Number.abs (Position.y-Pos.y)}
				if (Dista >= 2) then
					Message = null
					{TreatStream T IDPlayer Pos Path Life IsDive LoadMine LoadMissile ListMine EPaths EIDs EFound}
				elseif (Dista == 1) then
					if (Life == 1) then
						Message = sayDeath(IDPlayer)
						{TreatStream T null Pos Path 0 IsDive LoadMine LoadMissile ListMine EPaths EIDs EFound}
					else
						Message = sayDamageTaken(IDPlayer 1 Life-1)
						{TreatStream T IDPlayer Pos Path Life-1 IsDive LoadMine LoadMissile ListMine EPaths EIDs EFound}
					end
				else
					if (Life =< 2) then
						Message = sayDeath(IDPlayer)
						{TreatStream T null Pos Path 0 IsDive LoadMine LoadMissile ListMine EPaths EIDs EFound}
					else
						Message = sayDamageTaken(IDPlayer 2 Life-2)
						{TreatStream T IDPlayer Pos Path Life-2 IsDive LoadMine LoadMissile ListMine EPaths EIDs EFound}
					end
				end
			end

		[] sayMineExplode(_ Position ?Message)|T then
			local Dista in
				% Dista = Distance MineExplode-PlayerPosition
				Dista = {Number.abs (Position.x-Pos.x)} + {Number.abs (Position.y-Pos.y)}
				if (Dista >= 2) then
					Message = null
					{TreatStream T IDPlayer Pos Path Life IsDive LoadMine LoadMissile ListMine EPaths EIDs EFound}
				elseif (Dista == 1) then
					if (Life == 1) then
						Message = sayDeath(IDPlayer)
						{TreatStream T null Pos Path 0 IsDive LoadMine LoadMissile ListMine EPaths EIDs EFound}
					else
						Message = sayDamageTaken(IDPlayer 1 Life-1)
						{TreatStream T IDPlayer Pos Path Life-1 IsDive LoadMine LoadMissile ListMine EPaths EIDs EFound}
					end
				else
					if (Life =< 2) then
						Message = sayDeath(IDPlayer)
						{TreatStream T null Pos Path 0 IsDive LoadMine LoadMissile ListMine EPaths EIDs EFound}
					else
						Message = sayDamageTaken(IDPlayer 2 Life-2)
						{TreatStream T IDPlayer Pos Path Life-2 IsDive LoadMine LoadMissile ListMine EPaths EIDs EFound}
					end
				end
			end

		[] sayPassingDrone(Drone ?ID ?Answer)|T then
			ID = IDPlayer
			case Drone 
			of drone(row X) then
				Answer = X == Pos.x
			[] drone(column Y) then
				Answer = Y == Pos.y
			end
			{TreatStream T IDPlayer Pos Path Life IsDive LoadMine LoadMissile ListMine EPaths EIDs EFound}

		[] sayPassingSonar(?ID ?Answer)|T then
			ID = IDPlayer
			%strategy : return always true row and false column
			local ListRow FCol in
				ListRow = {List.subtract {IntList Input.nColumn 1} Pos.y}
				FCol = {Nth ListRow (({OS.rand} mod (Input.nColumn - 1)) + 1)}
				Answer = pt(x:Pos.x y:FCol)
			end
			{TreatStream T IDPlayer Pos Path Life IsDive LoadMine LoadMissile ListMine EPaths EIDs EFound}

		%The RandomPlayer ignore SayMove, SaySurface, SayCharge, SayMinePlaced, SayAnswerDrone, SayAnswerSonar, SayDeath and SayDamageTaken
		%These ignored case therefore enter in basic case
		[] sayMove(ID Direction)|T then
			N
		in
			% we don't need to track ourselves
			if ID == IDPlayer then
				{TreatStream T IDPlayer Pos Path Life IsDive LoadMine LoadMissile ListMine EPaths EIDs EFound}
			% a known ennemy moved. add to path and try to find him
			elseif {ContainsAt EIDs ID 1 N} then
				NewEPaths
			in
				% if position is already certain, update it
				if {Nth EFound N} == true then
					NewEPaths = {MoveNthInDir EPaths N Direction}
					%{Delay 20000}
					{TreatStream T IDPlayer Pos Path Life IsDive LoadMine LoadMissile ListMine NewEPaths EIDs EFound}
				%if position uncertain, add to path and try to pinpoint ennemy
				else
					NewPath ResultMatch
				in
					NewEPaths = {AddToNth EPaths N Direction NewPath}
					ResultMatch = {MatchToMap Input.map NewPath}
					case ResultMatch
					% more than one match
					of null then
						{TreatStream T IDPlayer Pos Path Life IsDive LoadMine LoadMissile ListMine NewEPaths EIDs EFound}
					% found ennemy
					[] pt(x:_ y:_) then
						NewEFound NewNewEPaths
					in
						%{Show IDPlayer#'Ennemy found'}
						%{Show IDPlayer#ID}
						%{Show IDPlayer#ResultMatch}
						%{Delay 5000}
						%delay is to debug and see if it works TODO remove once checked
						
						%TODO replace path with position 
						NewNewEPaths = {SetNth EPaths ResultMatch N}
						%{Show IDPlayer#New}
						NewEFound = {SetNth EFound true N}
						{TreatStream T IDPlayer Pos Path Life IsDive LoadMine LoadMissile ListMine NewNewEPaths EIDs NewEFound}
					% the given path can't fit in the Map
					% either an ennemy is cheating or we have a bug to correct
					[] reset then
						{Show IDPlayer#'No possible Match, reset'}

						% TODO: reset this path
						{TreatStream T IDPlayer Pos Path Life IsDive LoadMine LoadMissile ListMine NewEPaths EIDs EFound}
					end
				end
			% unknown ennemy. add him to the tracking list
			else
				{TreatStream T IDPlayer Pos Path Life IsDive LoadMine LoadMissile ListMine (Direction|nil)|EPaths ID|EIDs false|EFound}
			end
		[] sayDeath(_)|T then
			%TODO
			{TreatStream T IDPlayer Pos Path Life IsDive LoadMine LoadMissile ListMine EPaths EIDs EFound}
		%basic case
		[] _|T then
			{TreatStream T IDPlayer Pos Path Life IsDive LoadMine LoadMissile ListMine EPaths EIDs EFound}
		end
		
	end

	fun {IsEnnemyFound PosL FoundL}
		case PosL#FoundL
		of (HP|TP)#(HF|TF) then
			if HF == true then
				HP
			else
				{IsEnnemyFound TP TF}
			end
		else
			nil
		end
	end

	fun {PosToDir Start Dest}
		case Start#Dest
		of pt(x:XS y:YS)#pt(x:XD y:YD) then
			if XS-XD < 0 then
				south
			elseif XS-XD > 0 then
				north
			elseif YS-YD < 0 then
				east
			else
				west
			end
		else
			error
		end
	end

	fun {SetNth L E N}
		if N > 1 then
			case L
			of H|T then
				H|{SetNth T E N-1}
			% should never happen
			else
				nil
			end
		else
			case L
			of _|T then
				E|T
			else
				nil
			end
		end
	end

	% returns true if E is in L and sets N to the corresponding index
	% if E is not contained N will not be bound
	% Acc should start at 1
	fun {ContainsAt L E Acc ?N}
		case L
		of H|T then
			if H == E then
				N = Acc
				true
			else
				{ContainsAt T E Acc+1 N}
			end
		else
			false
		end
	end

	% if more that one match is found return null
	% if one and only one is found, return a <position> corresponding to the ennemy's position
	% if no match is found returns reset => should never happen, but allows to restart from 0
	fun {MatchToMap Map Path}
		% if path fits in Map from given X and Y returns end position of path
		% else return null
		fun {CheckPath Map Path X Y}
			%TODO: change name ? there are two functions with the same name
			if {IsOcean Map X Y} then
				case Path
				of H|T then
					case H
					of east then
						{CheckPath Map T X Y+1}
					[] west then
						{CheckPath Map T X Y-1}
					[] north then
						{CheckPath Map T X-1 Y}
					[] south then
						{CheckPath Map T X+1 Y}
					end
				else
					pt(x:X y:Y)
				end
			else
				null
			end
		end
		fun {MatchToMapIn Map Path X Y PathFound}
			NewPathFound
		in
			NewPathFound = {CheckPath Map Path X Y}
			% if this path is not possible
			if NewPathFound == null then
				% continue on the same column
				if X < Input.nRow then
					{MatchToMapIn Map Path X+1 Y PathFound}
				% go to the next column
				elseif Y < Input.nColumn then
					{MatchToMapIn Map Path 1 Y+1 PathFound}
				% reached the end
				else
					PathFound
				end
			% if it's the first path found 
			elseif PathFound == null then
				% continue on the same column
				if X < Input.nRow then
					{MatchToMapIn Map Path X+1 Y NewPathFound}
				% go to the next column
				elseif Y < Input.nColumn then
					{MatchToMapIn Map Path 1 Y+1 NewPathFound}
				% reached the end
				else
					NewPathFound
				end
			% we found two paths
			else
				null
			end
		end
		ReversedPath = {InsideOut Path nil}
	in
		{MatchToMapIn Map ReversedPath 1 1 null}
	end
	
	fun {IsOcean Map X Y}
		if (X =< Input.nRow andthen X > 0 andthen Y > 0 andthen Y =< Input.nColumn ) then
			{Nth {Nth Map X} Y} == 0
		else
			false
		end
	end

	%{Browse {IsOcean [[0 0 0 0 0 0 0 0 0 0] [0 0 0 0 0 0 0 0 0 0] [0 0 0 1 1 0 0 0 0 0] [0 0 1 1 0 0 1 0 0 0] [0 0 0 0 0 0 0 0 0 0] [0 0 0 0 0 0 0 0 0 0] [0 0 0 1 0 0 1 1 0 0] [0 0 1 1 0 0 1 0 0 0] [0 0 0 0 0 0 0 0 0 0] [0 0 0 0 0 0 0 0 0 0]] 3 4}}


	% given L = [a b ... y z], returns [z y ... b a]
	% Acc should start as nil
	fun {InsideOut L Acc}
		case L
		of H|T then
			{InsideOut T H|Acc}
		else
			% L's terminating nil should not be added to the list
			Acc
		end
	end

	% prepends Dir to the Nth path
	% Paths : list of paths
	% N : TODO
	% Dir : TODO
	% Path : the updated path
	fun {AddToNth Paths N Dir ?Path}
		if N > 1 then
			case Paths
			of H|T then
				H|{AddToNth T N-1 Dir Path}
			% should probably never happen
			else
				Path = nil
				nil
			end
		else
			case Paths
			of H|T then
				Path = Dir|H
				(Dir|H)|T
			% should probably never happen
			else
				Path = nil
				nil
			end
		end
	end
	% {Browse {AddToNth [nil north|east|nil north|nil] 2 east}}

	% updates the Nth position in Dir direction
	% does nothing if N is bigger than {Length Paths}
	% if N < 1 behaves as if N = 1
	fun {MoveNthInDir Paths N Dir}
		if N > 1 then
			case Paths
			of H|T then
				H|{MoveNthInDir T N-1 Dir}
			% should probably never happen
			else
				nil
			end
		else
			case Paths
			of H|T then
				case Dir
				of east then
					pt(x:H.x y:H.y+1)|T
				[] west then
					pt(x:H.x y:H.y-1)|T
				[] north then
					pt(x:H.x-1 y:H.y)|T
				[] south then
					pt(x:H.x+1 y:H.y)|T
				end
			% should probably never happen
			else
				nil
			end
		end
	end
	%{Browse {MoveNthInDir [north|nil pt(x:1 y:1) pt(x:3 y:3)] 2 east}}

	%function for init position
	fun {InitPosition}
		
		local Row NRow NZero NCol NbrZero in
		
		%random row
		NRow = ({OS.rand} mod Input.nRow) + 1
		
		%choose random column (position doesn't contain 1 in Input.Map
		Row = {Nth Input.map NRow}
		
		%count number of 0 in row
		NbrZero = {Length {Filter Row (fun {$ Number} Number == 0 end)}}
		%if NbZero = 0 choose another row
		if (NbrZero == 0) then
			{InitPosition}
			
		else
			%choose random column with element "0"
			NZero = ({OS.rand} mod NbrZero) + 1
			%Find this random Column 
			NCol = {FindElem Row (fun {$ Number} Number == 0 end) NZero}

			%return
			pt(x:NRow y:NCol)
		end
		
		end
	end

	%fonction find the Nth element of a list with condition
	fun {FindElem X F C}
		fun{Aux X I Acc}
			if I == C then Acc
			else
				case X 
				of nil then 
					0
				[] Xs|Xr then
					if {F Xs} then 
						{Aux Xr I+1 Acc+1}
					else 
						{Aux Xr I Acc+1}
					end
				end
			end
		end
	in
		{Aux X 0 0}	   
	end


		%fonction move, the player move to a ramdom position
	fun{Move Pos Path IsDive}
		local AllDir CorrectPos in
			
			%All possible direction
			AllDir = [[pt(x:Pos.x-1 y:Pos.y) north] [pt(x:Pos.x+1 y:Pos.y) south] [pt(x:Pos.x y:Pos.y-1) west] [pt(x:Pos.x y:Pos.y+1) east]]

			%Check which position is valid (with fonction ValidPath)
			CorrectPos = {ValidPath AllDir Path}

			if {Length CorrectPos} == 0 then
				[surface Pos Pos|nil false]
			else
				local ChooseDir NameDir ExactPos in 
					%choose random direction
					ChooseDir = {Nth CorrectPos (({OS.rand} mod {Length CorrectPos}) + 1)}
					%Name of Direction
					NameDir = ChooseDir.2.1
					%New Position
					ExactPos = ChooseDir.1
					%return [direction position path IsDive]
					[NameDir ExactPos ExactPos|Path IsDive]
				end
			end
		end
	end	
	
	fun {ContainsPt L E}
		case L
		of H|T then
			if H.x==E.x andthen H.y==E.y then
				true
			else
				{ContainsPt T E}
			end
		else
			false
		end
	end

	%fonction ValidPath for check if direction is valid and return the list of valid direction
	fun {ValidPath Directions Path}
		case Directions 
		of nil then 
			nil
		[] H|T then
			case H 
			of [pt(x:X y:Y) _] then

				%check if is on map and is on water, and if NewPosition is not Visited
				if ({IsOcean Input.map X Y} andthen {Not {ContainsPt Path.2 H.1}} )then   %(if (Path == nil) then true else {Not {List.all Path.2 (fun{$ Elem} H.1\= Elem end)}} end)) %contains
					H|{ValidPath T Path}
				else
					{ValidPath T Path}
				end
			end
		end
	end



	%fonction generate list of all matrix position
	fun {AllPosition NRow NCol I}
		if (NRow == 0) then
			nil
		elseif NCol == 0 then
			{AllPosition NRow-1 I I}
		else
			pt(x:NRow y:NCol)|{AllPosition NRow NCol-1 I}
		end
	end


	%fonction ValidPath for check if direction is valid and return the list of valid direction
	fun {ValidPosItem ListAll Pos DistMin DistMax}
		case ListAll 
		of nil then 
			nil
		[] pt(x:X y:Y)|T then
			local Dista in
				Dista = {Number.abs (X-Pos.x)} + {Number.abs (Y-Pos.y)}
				if (({Nth {Nth Input.map X} Y} == 0) andthen (Dista >= DistMin) andthen (Dista =< DistMax)) then
					pt(x:X y:Y)|{ValidPosItem T Pos DistMin DistMax}
				else
					{ValidPosItem T Pos DistMin DistMax}
				end
			end
		end
	end

	%Make Int List
	fun {IntList Number Acc}
		if (Number+1 == Acc) then
			nil
		else
			Acc|{IntList Number Acc+1}
		end
	end

	%Filter and substract nearby Mine
	fun{DistantMine MyPos ListMine}
		case ListMine of nil then nil
		[] pt(x:X y:Y)|T then
			local Dista in
				Dista = {Number.abs (X-MyPos.x)} + {Number.abs (Y-MyPos.y)}
				if (Dista >= 2) then
					pt(x:X y:Y)|{DistantMine MyPos T}
				else
					{DistantMine MyPos T}
				end
			end
		end
	end

	%%%%%%%%%%%%%%%%%
	%% PathFinding %%
	%%%%%%%%%%%%%%%%%

	proc {SetTileList LL Acc}
		proc {SetTileListIn LL Acc}
			case Acc
			of wall|T then
				{SetTileListIn LL T}
			[] H|T then
				{Send H setListTiles(LL)}
				{SetTileListIn LL T}
			else
				skip
			end
		end
	in
		case Acc
		of H|T then
			{SetTileListIn LL H}
			{SetTileList LL T}
		else
			skip
		end
	end

	%takes a list of pt(x:X y:Y) and filters out all invalid movements
	fun {Validate Map L}
		case L
		of pt(x:X y:Y)|T then
			if X > 0 andthen Y > 0 andthen X =< Input.nRow andthen Y =< Input.nColumn then
				pt(x:X y:Y)|{Validate Map T}
			else
				{Validate Map T}
			end
		else
			nil
		end
	end

	proc {SendToNeighbors LL Pos Msg}
		proc {SendToNeighborsIn LL ValidL Msg}
			case ValidL
			of pt(x:X y:Y)|T then
				{Send {Nth {Nth LL X} Y} Msg}
				{SendToNeighborsIn LL T Msg}
			else 
				skip
			end
		end
	in
		case Pos
		of pt(x:X y:Y) then
			ValidNeighbors
		in
			ValidNeighbors = {Validate LL [pt(x:X+1 y:Y) pt(x:X-1 y:Y) pt(x:X y:Y+1) pt(x:X y:Y-1)]}
			{SendToNeighborsIn LL ValidNeighbors Msg}
		end
	end

	proc {DestFunction Stream ListTiles Pos ?Return}
		case Stream
		of sayCost(_ Path)|_ then
			Return = Path
			%{Show Path}
			{SendToNeighbors ListTiles Pos found}
		end
	end

	proc {TileFunction Stream SelfPos SelfGCost PathToOrigin ListTiles}
		case Stream
		of found|_ then
			{SendToNeighbors ListTiles SelfPos found}
		[] sayCost(Cost Path)|T then
			if (Cost + 1) < SelfGCost then
				{SendToNeighbors ListTiles SelfPos sayCost(Cost+1 SelfPos|Path)}
				{TileFunction T SelfPos Cost+1 SelfPos ListTiles}
			else
				{TileFunction T SelfPos SelfGCost PathToOrigin ListTiles}
			end
		[] setListTiles(Tiles)|T then
			{TileFunction T SelfPos SelfGCost PathToOrigin Tiles}
		[] setAsDest(?Return)|T then
			{DestFunction T ListTiles SelfPos Return}
		end
	end

	fun {NewTileObject Pos ListTiles}
		Stream
		Port = {NewPort Stream}
	in
		thread
			{TileFunction Stream Pos 99999 nil ListTiles}
		end
		Port
	end

	fun {MapToPortObject Map X Y}
		fun {RowToPortObject Row X Y}
			case Row
			of H|T then
				if H == 0 then
					{NewTileObject pt(x:X y:Y) nil}|{RowToPortObject T X Y+1}
				else
					{NewWall}|{RowToPortObject T X Y+1}
				end
			else
				nil
			end
		end
	in
		case Map
		of H|T then
			{RowToPortObject H X Y}|{MapToPortObject T X+1 Y}
		else
			nil
		end
	end

	proc {WallFun Strema}
		case Strema
		of found|_ then
			skip
		[] H|T then
			{WallFun T}
		end
	end

	fun {NewWall}
		Stream
		Port = {NewPort Stream}
	in
		thread
			{WallFun Stream}
		end
		Port
	end

	%%%%%%%%%%%%%%%%%%%%%
	%% End PathFinding %%
	%%%%%%%%%%%%%%%%%%%%%
	
	%Launch Player
	fun {StartPlayer Color ID}
		Stream
		Port
		
	in
		{NewPort Stream Port}
		% initialise Random Player
		thread
			{TreatStream Stream id(id:ID color:Color name:smartAI) pt(x:0 y:0) nil Input.maxDamage false 0 0 nil nil nil nil}
		end
		%return
		Port
	end
end