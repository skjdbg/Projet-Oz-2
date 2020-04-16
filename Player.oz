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
	     {TreatStream T null null null 0 isDive}
	     
	  else
	     ID = IDPlayer
	     %TODO
	  end

       [] dive|T then
	  {TreatStream T IDPlayer Position Path Life true}

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
       
       local Row NRow NZero NCol in
	  
          %random row
	  NRow = ({OS.rand} mod Input.nRow) + 1
          %choose random column (position doesn't contain 1 in Input.Map
	  Row = {Nth Input.Map NRow}
	  NZero = ({OS.rand} mod {Length {Filter Row (fun {$ Number} Number == 0 end)}}) + 1
	  NCol = {FindElem Row (fun {$ Number} Number == 0 end) NZero}

	  %return
	  pt(x:NRow y:NCol)

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
