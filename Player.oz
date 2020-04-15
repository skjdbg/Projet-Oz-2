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
    proc{TreatStream Stream IDPlayer Pos}
       case Stream
       of nil then skip


	  %all case of Stream
	  
       [] initPosition(?ID ?Position)|T then
	  ID = IDPlayer
	  
	  %Choose random position in the grid to begin
	  Position = {InitPosition}
	  
	  {TreatStream T IDPlayer Position}

       [] move(?ID ?Position ?Direction)|T then
	  %TODO
	  skip

       [] dive|T then
	  %TODO
	  skip

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
	  %TODO
	  skip

       [] sayMove(ID Direction)|T then
	  %TODO
	  skip
	  
       [] saySurface(ID)|T then
	  %TODO
	  skip

       [] sayCharge(ID KindItem)|T then
	  %TODO
	  skip

       [] sayMinePlaced(ID)|T then
	  %TODO
	  skip
	  
       [] sayMissileExplode(ID Position ?Message)|T then
	  %TODO
	  skip

       [] sayMineExplode(ID Position ?Message)|T then
	  %TODO
	  skip
	  
       [] sayPassingDrone(Drone ?ID ?Answer)|T then
	  %TODO
	  skip

       [] sayAnswerDrone(Drone ID Answer)|T then
	  %TODO
	  skip

       [] sayPassingSonar(?ID ?Answer)|T then
	  %TODO
	  skip

       [] sayAnswerSonar(ID Answer)|T then
	  %TODO
	  skip

       [] sayDeath(ID)|T then
	  %TODO
	  skip

       [] sayDamageTaken(ID Damage LifeLeft)|T then
	  %TODO
	  skip


       %basic case
       [] _|T then
	  {TreatStream T IDPlayer Pos}
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
	  {TreatStream Stream id(id:ID color:Color name:"AIRandom") pt(x:0 y:0)}
       end

       %return
       Port
       
    end
end
