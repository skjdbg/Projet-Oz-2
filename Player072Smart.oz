functor
import
   Input
   OS
   System(showInfo:Print)
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
in
	% TODO
	% Stream : 
	% IDPlayer : either null if we have been killed or our <id> ::= id(id:<IdNum> color:<Color>)
	% Pos : our position pt(x:X y:Y)
	% Path : list of positions since last surface
	% Life : ammount of health left
	% IsDive : true if underwater, false if not
	% LoadMine : TODO
	% LoadMissile : TODO
	% ListMine : TODO
	% EPaths : list of the ennemies' paths. used to try and guess where they are. if an ennemy's position is known, contains only this position
	% EIDs : list of the ennemies' id. used to identify what path is whose (bijection with EPaths)
	% EFound : list of either true of false. true if there is one and only one possible position for the corresponding ennemy
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
		
			ID = IDPlayer
			local ListMove in
				%collect the retrun list of fonction Move ( [direction position path IsDive] )
				ListMove = {Move Pos Path IsDive}
				%dir and pos
				Direction = ListMove.1
				Position = ListMove.2.1

				%end
				{TreatStream T IDPlayer ListMove.2.1 ListMove.2.2.1 Life ListMove.2.2.2.1 LoadMine LoadMissile ListMine EPaths EIDs EFound}
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
							CorrectPos = {ValidPosItem PosMatrix Pos Input.minDistanceMissile Input.maxDistanceMissile}
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
						CorrectPos = {ValidPosItem PosMatrix Pos Input.minDistanceMissile Input.maxDistanceMissile}
						RandomPos = {Nth CorrectPos (({OS.rand} mod {Length CorrectPos}) +1)}
						KindFire = missile(RandomPos)
						{TreatStream T IDPlayer Pos Path Life IsDive LoadMine 0 ListMine EPaths EIDs EFound}
					end
				end
			end
		[] fireMine(?ID ?Mine)|T then
			ID = IDPlayer

			%check if ListMine is empty
			if {Length ListMine} == 0 then
				Mine = null
				{TreatStream T IDPlayer Pos Path Life IsDive LoadMine LoadMissile ListMine EPaths EIDs EFound}
			else
				Mine = {Nth ListMine (({OS.rand} mod {Length ListMine}) +1)}
				local NewMineList in
				NewMineList = {List.subtract ListMine Mine}
				{TreatStream T IDPlayer Pos Path Life IsDive LoadMine LoadMissile NewMineList EPaths EIDs EFound}
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
						{TreatStream T IDPlayer Pos Path 0 IsDive LoadMine LoadMissile ListMine EPaths EIDs EFound}
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
						{TreatStream T IDPlayer Pos Path 0 IsDive LoadMine LoadMissile ListMine EPaths EIDs EFound}
					else
						Message = sayDamageTaken(IDPlayer 1 Life-1)
						{TreatStream T IDPlayer Pos Path Life-1 IsDive LoadMine LoadMissile ListMine EPaths EIDs EFound}
					end
				else
					if (Life =< 2) then
						Message = sayDeath(IDPlayer)
						{TreatStream T IDPlayer Pos Path 0 IsDive LoadMine LoadMissile ListMine EPaths EIDs EFound}
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
		[] sayMove(ID Direction) then
			if {Contains EIDs ID} then

			else

			end
		[] saySurface(ID) then

		[] sayCharge(ID KindItem) then

		[] sayMinePlaced(ID) then

		[] sayAnswerDrone(Drone ID Answer) then

		[] sayAnswerSonar(ID Answer) then

		[] sayDeath(ID) then

		[] sayDamageTaken(ID Damage LifeLeft) then

		%basic case
		[] _|T then
			{TreatStream T IDPlayer Pos Path Life IsDive LoadMine LoadMissile ListMine EPaths EIDs EFound}
		end
		
	end

	%fonction for init position
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
	fun {Move Pos Path IsDive}
		local AllDir CorrectPos ChooseDir NameDir ExactPos Tmp in
			
			%All possible direction
			AllDir = [[pt(x:Pos.x y:Pos.y) surface] [pt(x:Pos.x-1 y:Pos.y) north] [pt(x:Pos.x+1 y:Pos.y) south] [pt(x:Pos.x y:Pos.y-1) west] [pt(x:Pos.x y:Pos.y+1) east]]

			%Check which position is valid (with fonction ValidPath)
			CorrectPos = {ValidPath AllDir Path}


			%choose random direction
			ChooseDir = {Nth CorrectPos (({OS.rand} mod {Length CorrectPos}) + 1)}
			%Name of Direction
			NameDir = ChooseDir.2.1
			%New Position
			ExactPos = ChooseDir.1
			%return [direction position path IsDive]
			if (NameDir == surface) then
				[NameDir ExactPos ExactPos|nil false]
			else
				[NameDir ExactPos ExactPos|Path IsDive]
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
				if (X >= 1 andthen X =< Input.nRow andthen Y >= 1 andthen Y =< Input.nColumn andthen ({Nth {Nth Input.map X} Y} == 0) andthen {Not {ContainsPt Path.2 H.1}} )then   %(if (Path == nil) then true else {Not {List.all Path.2 (fun{$ Elem} H.1\= Elem end)}} end)) %contains
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
	
	%Launch Player
	fun {StartPlayer Color ID}
		Stream
		Port
		
	in
		{NewPort Stream Port}
		% initialise Random Player
		thread
			{TreatStream Stream id(id:ID color:Color name:smartAI) pt(x:0 y:0) nil Input.maxDamage false 0 0 nil}
		end
		%return
		Port
	end
end