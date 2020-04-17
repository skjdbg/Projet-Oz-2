functor
import
   Input
export
   portPlayer:StartPlayer
define
   StartPlayer
   TreatStream
   InitPosition
   FindElem
   Move
   ValidPath
in
    proc{TreatStream Stream IDPlayer Pos Path Life isDive}
       case Stream
       of nil then skip


	  %all case of Stream
	  
       [] initPosition(?ID ?Position)|T then
	  ID = IDPlayer
	  
	  %Choose random position in the grid to begin
	  Position = {InitPosition}
	  
	  {TreatStream T IDPlayer Position Position|nil Input.maxDamage false}

       [] move(?ID ?Position ?Direction)|T then
	  
	  %stay alive ?
	  if (Life == 0) then
	     ID = null
	     Position = null
	     Direction = null
	     {TreatStream T IDPlayer Pos Path Life isDive}
	     
	  else
	     ID = IDPlayer
	     local ListMove in
		%collect the retrun list of fonction Move ( [direction position path isDive] )
		ListMove = {Move Pos Path isDive}
		%dir and pos
		Direction = ListMove.1
		Position = ListMove.2.1

		%end
		{TreatStream T IDPlayer ListMove.2.1 ListMove.2.2.1 Life ListMove.2.2.2.1}
	     end
	  end

       [] dive|T then
	  {TreatStream T IDPlayer Pos Path Life true}

       [] chargeItem(?ID ?KindItem)|T then
	  %TODO
	  skip
	  
       [] fireItem(?ID ?KindFire)|T then
	  %TODO
	  skip

       [] fireMine(?ID ?Mine)|T then
	  %TODO
	  skip

       [] isDead(?Answer)|T then
	  if (Life == 0) then
	     Answer = true
	  else
	     Answer = false
	  end
	  {TreatStream T IDPlayer Pos Path Life isDive}

       [] sayMineExplode(ID Position ?Message)|T then
	  %TODO
	  skip

       %The RandomPlayer ignore SayMove, SaySurface, SayCharge, SayMinePlaced, SayMissileExplode, SayPassingDrone, SayAnswerDrone, SayPassingSonar, SayAnswerSonar, SayDeath and SayDamageTaken
       %These ignored case therefore enter in basic case
	  
       %basic case
       [] _|T then
	  {TreatStream T IDPlayer Pos Path Life isDive}
       end
       
    end
    
    



    %fonction for init position
    fun{InitPosition}
       
       local Row NRow NZero NCol NbrZero in
	  
          %random row
	  NRow = ({OS.rand} mod Input.nRow) + 1
	  
          %choose random column (position doesn't contain 1 in Input.Map
	  Row = {Nth Input.Map NRow}
	  
	  %count number of 0 in row
	  NbrZero = {Length {Filter Row (fun {$ Number} Number == 0 end)}}
	  %if NbZero = 0 choose another row
	  if (NbrZero = 0) then
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
    fun{FindElem X F C}
       fun{Aux X I Acc}
	  if I == C then Acc
	  else
	     case X of nil then 0
	     [] Xs|Xr then
		if {F Xs} then {Aux Xr I+1 Acc+1}
		else {Aux Xr I Acc+1}
		end
	     end
	  end
       end
       
    in
       {Aux X 0 0}	   
    end


    %fonction move, the player move to a ramdom position
    fun{Move Pos Path isDive}
       local AllDir CorrectPos CorrectDir Dir in
	  
	  %All possible direction
	  AllDir = positions(surface : pt(x:Pos.x y:Pos.y)
			     north : pt(x:Pos.x-1 y:Pos.y)
			     south : pt(x:Pos.x+1 y:Pos.y)
			     west : pt(x:Pos.x y:Pos.y-1)
			     east : pt(x:Pos.x y:Pos.y+1))

	  %Check which position is valid (with fonction ValidPath)
	  CorrectPos = {Record.filter AllDir {ValidPath Path}}
	  CorrectDir = {Record.arity CorrectPos}

	  %choose random direction
	  Dir = {Nth CorrectDir (({OS.rand} mod {Length CorrectDir}) + 1)}
	  %return [direction position path isDive]
	  if (Dir == surface) then
	     [Dir AllDir.Dir AllDir.Dir|nil false]
	  else
	     [Dir AllDir.Dir AllDir.Dir|Path isDive]
	  end
	  		     
       end
    end

    %fonction ValidPath for check if direction is valid
    fun{ValidPath Path}
       fun{$ NewPos}
	  
	  local X Y in
	     pt(x:X y:Y) = NewPos

	     %return
	     %check if is on map and is on water, and if NewPosition is not Visited
	     X >= 1 andthen X =< Input.nRow andthen Y >= 1 andthen Y =< Input.nColumn andthen ({Nth {Nth Input.map X} Y} == 0)
	     andthen (if (Path == nil) then true
		      else {Not {List.all Path.2 (fun{$ Elem} X\= Elem end)}} end) %contains
	  end
       end 
    end

    


    %Launch Player
    fun{StartPlayer Color ID}
       Stream
       Port
       PlayerRandom
       
    in
       {NewPort Stream Port}

       % initialise Random Player
       thread
	  {TreatStream Stream id(id:ID color:Color name:"AIRandom") pt(x:0 y:0) nil 0 false}
       end

       %return
       Port
       
    end
end
