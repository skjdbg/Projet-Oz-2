functor
import
    Input
export
    portPlayer:StartPlayer
define
    StartPlayer
    TreatStream
in
    proc{TreatStream Stream StatePlayer}
       case Stream
       of nil then skip

       [] initPosition(?ID ?Position)|T then
	  %TODO
	  {TreatStream T StatePlayer}

       [] move(?ID ?Position ?Direction)|T then
	  %TODO
	  {TreatStream T StatePlayer}

       [] dive|T then
	  %TODO
	  {TreatStream T StatePlayer}

       [] chargeItem(?ID ?KindItem)|T then
	  %TODO
	  {TreatStream T StatePlayer}
	  
       [] fireItem(?ID ?KindFire)|T then
	  %TODO
	  {TreatStream T StatePlayer}

       [] fireMine(?ID ?Mine)|T then
	  %TODO
	  {TreatStream T StatePlayer}

       [] isDead(?Answer)|T then
	  %TODO
	  {TreatStream T StatePlayer}

       [] sayMove(ID Direction)|T then
	  %TODO
	  {TreatStream T StatePlayer}
	  
       [] saySurface(ID)|T then
	  %TODO
	  {TreatStream T StatePlayer}

       [] sayCharge(ID KindItem)|T then
	  %TODO
	  {TreatStream T StatePlayer}

       [] sayMinePlaced(ID)|T then
	  %TODO
	  {TreatStream T StatePlayer}

       [] sayMissileExplode(ID Position ?Message)|T then
	  %TODO
	  {TreatStream T StatePlayer}

       [] sayMineExplode(ID Position ?Message)|T then
	  %TODO
	  {TreatStream T StatePlayer}

       [] sayPassingDrone(Drone ?ID ?Answer)|T then
	  %TODO
	  {TreatStream T StatePlayer}

       [] sayAnswerDrone(Drone ID Answer)|T then
	  %TODO
	  {TreatStream T StatePlayer}

       [] sayPassingSonar(?ID ?Answer)|T then
	  %TODO
	  {TreatStream T StatePlayer}

       [] sayAnswerSonar(ID Answer)|T then
	  %TODO
	  {TreatStream T StatePlayer}

       [] sayDeath(ID)|T then
	  %TODO
	  {TreatStream T StatePlayer}

       [] sayDamageTaken(ID Damage LifeLeft)|T then
	  %TODO
	  {TreatStream T StatePlayer}

       end
       
    end
    fun{StartPlayer Color ID}
       Stream
       Port
       PlayerRandom
       
    in
       {NewPort Stream Port}

       % initial Random Player
       PlayerRandom = player(id:ID color:Color name:AIRandom pos:_ path:_ immersed:_ life:_ loadMine:_ nbMine:_ mineList:_ loadMissile:_ nbMissile:_ loadDrone:_ nbDrone:_ loadSonar:_ nbSonar:_)

       thread
	  {TreatStream Stream PlayerRandom}
       end

       %return
       Port
       
    end
end
