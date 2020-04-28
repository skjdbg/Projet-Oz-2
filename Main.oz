functor
import
   GUI
   Input
   PlayerManager
   System(show:Show print:Print)
   OS
define
    % iterates over ListPlayerTypes and creates a list of the corresponding players' ports
    % Id is just an accumulator and should start as 1
   fun {TakeNth L N}
      if N > 1 then
	      case L
         of _|T then
            {TakeNth T N-1}
         end
      else
	      L.1
      end 
   end

   fun {PlayerMaker ListPlayerTypes Id}
      case ListPlayerTypes
      of H|T then
         % threads because why not
	      thread {PlayerManager.playerGenerator H {TakeNth Input.colors Id} Id} end|{PlayerMaker T Id+1}
      [] nil then
	      nil
      end
   end

   proc {WaitForN N S}
      if N > 0 then
         case S
         of H|T then
            {Wait H}
            {WaitForN N-1 T}
	      end
      else
	      skip
      end
   end

   fun {MakeUnboundList N Acc}
      if N > 0 then
	      {MakeUnboundList N-1 _|Acc}
      else
	      Acc
      end
   end

   % creates a list of of port in L and 
   % returns the list of the corresponding Streams shifted by one so that
   % Ports :   [A B C D]
   % Streams : [D A B C]
   fun {MakeStreamList ?L Carry1 Carry2 I}
      case L
      of H|T then 
         if I == 0 then
            Car1 Car2
         in
            H = {NewPort Car1}
            Car2|{MakeStreamList T Car1 Car2 1}
         else
            Car1
         in
            H = {NewPort Car1}
            Carry1|{MakeStreamList T Car1 Carry2 I}
         end
      [] nil then
         Carry2 = Carry1
         nil
      end
   end

   proc {SkipTurn SWait PForward}
      %TODO kill every thread once all is Done
      case SWait
      of H|T then
         if H \= 'end' then
            {Send PForward unit}
            {SkipTurn T PForward}
         else
            {Send PForward 'end'}
         end
      else
         skip
      end
   end


   % Port => this submarine's port
   % EPL => List of the ennemies' port
   % DiveStatus == 0 => the submarine is underwater
   % DiveStatus > 0  => the submarine has surfaced and has to wait DiveStatus turns
   proc {HandlePlayer SWait PForward DiveStatus GUI EPL Port Synch}
      case SWait
      of H|T then
         if H == 'end' then
            {Send PForward 'end'}
         else
            if DiveStatus > 0 then
               {Send PForward unit}
               {HandlePlayer T PForward DiveStatus-1 GUI EPL Port Synch}
            else
               Id Pos Dir
            in
               {Send Port dive}
               {Send Port move(Id Pos Dir)}
               {Wait Id}
               % if the player is dead it's useless to propose him any action
               if Id == null then
                  {Send PForward unit}
                  {Send Synch 1}
                  {SkipTurn SWait PForward}
               else
                  {Wait Pos}
                  {Wait Dir}
                  case Dir
                  of surface then
                     % Player has chosen to make surface => make him skip Input.turnSurface turns (including this one)
                     {Broadcast EPL saySurface(Id)}
                     {Send GUI surface(Id)}
                     {Send PForward unit}
                     {HandlePlayer T PForward Input.turnSurface-1 GUI EPL Port Synch}
                  else
                     IdCharge ItemKind
                     IdFire FireKind PosMiss
                     IdMine Mine
                  in
                     {Broadcast EPL sayMove(Id Dir)}
                     {Send GUI movePlayer(Id Pos)}

                     {Send Port chargeItem(IdCharge ItemKind)}
                     {Wait IdCharge}
                     if IdCharge == null then
                        {Send PForward unit}
                        {Send Synch 1}
                        {SkipTurn SWait PForward}
                     else
                        {Wait ItemKind}

                        if ItemKind \= null then
                           {Broadcast EPL sayCharge(IdCharge ItemKind)}
                        end

                        {Send Port fireItem(IdFire FireKind)}
                        {Wait IdFire}
                        if IdFire == null then
                           {Send PForward unit}
                           {Send Synch 1}
                           {SkipTurn SWait PForward}
                        else
                           {Wait FireKind}
                           case FireKind
                           of mine(Pos) then
                              {Send GUI putMine(IdFire Pos)}
                              {Broadcast EPL sayMinePlaced(IdFire)}
                           [] missile(PosMiss) then
                              {Send GUI explosion(IdFire PosMiss)}
                              {BroadcastMissExp EPL IdFire PosMiss GUI}
                           [] drone then
                              {Send GUI drone(IdFire FireKind)}
                              {BroadcastDrone EPL Port FireKind}
                           [] sonar then
                              {Send GUI sonar(IdFire)}
                              {BroadcastSonar EPL Port}
                           [] _ then  % includes the "null" case
                              skip
                           end

                           {Send Port fireMine(IdMine Mine)}
                           {Wait IdMine}
                           if IdMine == null then
                              {Send PForward unit}
                              {Send Synch 1}
                              {SkipTurn SWait PForward}
                           else
                              {Wait Mine}
                              case Mine
                              of null then
                                 skip
                              else
                                 {BroadcastMineExp EPL IdMine Mine GUI}
                                 {Send GUI explosion(IdMine Mine)}
                                 {Send GUI removeMine(IdMine Mine)}
                              end
                              {Send PForward unit}
                              {HandlePlayer T PForward DiveStatus GUI EPL Port Synch}
                           end
                        end
                     end
                  end
               end
            end
         end
      end
   end

   proc {RunTurnByTurn GUI EPL}
      proc {LaunchPlayers SL PL GUI EPL PortList Sync}
         case SL#PL#PortList %PL
         of (HS|TS)#(HP|TP)#(Port|List) then
            thread {HandlePlayer HS HP 0 GUI EPL Port Sync}end
            {LaunchPlayers TS TP GUI EPL List Sync}
         else
            skip
         end
      end
      PortList
      StreamList
      StreamSync
   in
      PortList = {MakeUnboundList Input.nbPlayer nil}
      StreamList = {MakeStreamList PortList nil nil 0}
      {LaunchPlayers StreamList PortList GUI EPL EPL {NewPort StreamSync}}
      {Send PortList.1 unit}
      {WaitForN Input.nbPlayer-1 StreamSync} % we wait for exactly 1 winner (more precisely 1 or less)
      {Broadcast PortList 'end'} % shuts down every thread
      {Show 'Game Over'}
   end


   proc {RunSimultaneous EPL GUI}
      %Proc to plays player's turn
      proc{TurnPlayer Port Synch}

         % TODO END when 1 player still alive 
	  
	      %1 beginning with dive
	      {Send Port dive}
	  
	      %2 Simulate thinking player
	      {SimulateThink}

	      %3 ask choose direction
         local Id Pos Dir in
            {Send Port move(Id Pos Dir)}
            {Wait Id}
            if (Id == null) then
               {Send Synch 1}
               skip
            else
               {Wait Pos}
               {Wait Dir}

               %4 Surface has been choosen
               case Dir 
               of surface then
                  {Broadcast EPL saySurface(Id)}
                  {Send GUI surface(Id)}
                  %delay *1000
                  {Delay (Input.turnSurface * 1000)}
                  {TurnPlayer Port Synch}

               %5 broadcast direction
               else
                  {Broadcast EPL sayMove(Id Dir)}
                  {Send GUI movePlayer(Id Pos)}

                  %6 Simulate thinking player
                  {SimulateThink}

                  %7 charge item
                  local IdCharge ItemKind in
                     {Send Port chargeItem(IdCharge ItemKind)}
                     {Wait IdCharge}
                     if (IdCharge == null) then
                        {Send Synch 1}
                        skip
                     else
                        {Wait ItemKind}
                        if ItemKind \= null then
                           {Broadcast EPL sayCharge(IdCharge ItemKind)}
                        end

                        %8 Simulate thinking player
                        {SimulateThink}

                        %9 Fire Item
                        local IdFire FireKind PosMiss in
                           {Send Port fireItem(IdFire FireKind)}
                           {Wait IdFire}
                           if (IdFire == null) then
                              {Send Synch 1}
                              skip
                           else
                              {Wait FireKind}
                              case FireKind
                              of mine(Pos) then
                                 {Send GUI putMine(IdFire Pos)}
                                 {Broadcast EPL sayMinePlaced(IdFire)}
                              [] missile(PosMiss) then
                                 {Send GUI explosion(IdFire PosMiss)}
                                 {BroadcastMissExp EPL IdFire PosMiss GUI}
                              [] drone then
                                 {Send GUI drone(IdFire FireKind)}
                                 {BroadcastDrone EPL Port FireKind}
                              [] sonar then
                                 {Send GUI sonar(IdFire)}
                                 {BroadcastSonar EPL Port}
                              [] _ then  % includes the "null" case
                                 skip
                              end

                              %10 Simulate thinking player
                              {SimulateThink}

                              %11 explode mine
                              local IdMine Mine in
                                 {Send Port fireMine(IdMine Mine)}
                                 {Wait IdMine}
                                 if (IdMine == null) then
                                    {Send Synch 1}
                                    skip
                                 else
                                    {Wait Mine}
                                    case Mine
                                    of null then
                                       skip
                                    else
                                       {BroadcastMineExp EPL IdMine Mine GUI}
                                       {Send GUI explosion(IdMine Mine)}
                                       {Send GUI removeMine(IdMine Mine)}
                                    end

                                    %12 Loop finished, go back to 1
                                    {TurnPlayer Port Synch}
                                 end
                              end
                           end
                        end
                     end
                  end
               end
            end
	      end
      end
      Sync
      StreamSync
   in
      {NewPort StreamSync Sync}
      {List.forAll EPL (proc{$ Port} thread {TurnPlayer Port Sync} end end)}
      {WaitForN Input.nbPlayer-1 StreamSync} % we wait for exactly 1 winner (more precisely 1 or less)
      {Show 'Game Over'}
   end

   proc {InitPlayers PL GUI}
      Id Pos
   in
      case PL
      of P|L then
         {Send P initPosition(Id Pos)}
         {Wait Id}
         {Wait Pos}
         {Send GUI initPlayer(Id Pos)}

	      {InitPlayers L GUI}
      [] nil then
	      skip
      end
   end

   proc {Broadcast PL Msg}
      case PL
      of P|L then
         {Send P Msg}
         {Broadcast L Msg}
      [] nil then
         skip
      end
   end

   proc {BroadcastMissExp PL Id MissPos GUI}
      case PL
      of P|T then
         Ans
      in
         %TODO ce show fait des trucs bizares avec player072random je pense
         %{Show P}
         {Send P sayMissileExplode(Id MissPos Ans)}
         {Wait Ans}
         case Ans
         of sayDeath(Id) then
            {Broadcast PL Ans}
            {Send GUI removePlayer(Id)}
         [] sayDamageTaken(Id _ LifeLeft) then
            {Broadcast PL Ans}
            {Send GUI lifeUpdate(Id LifeLeft)}
         else 
            skip
         end
         {BroadcastMissExp T Id MissPos GUI}
      [] nil then
         skip
      end
   end        
    
   proc {BroadcastDrone PL PAns Drone}
      case PL
      of P|T then
         Id Ans
      in
         {Send P sayPassingDrone(Drone Id Ans)}
         {Wait Id}
         if Id \= null then
            {Wait Ans}
            {Send PAns sayAnswerDrone(Drone Id Ans)}
         end
         {BroadcastDrone T PAns Drone}
      [] nil then
	      skip
      end
   end

   proc {BroadcastSonar PL PAns}
      case PL
      of P|T then
	      Id Ans
      in
         {Send P sayPassingSonar(Id Ans)}
         {Wait Id}
         if Id \= null then
            {Wait Ans}
            {Send PAns sayAnswerSonar(Id Ans)}
         end
         {BroadcastSonar T PAns}
      [] nil then
	      skip
      end
   end

   proc {BroadcastMineExp PL Id MinePos GUI}
      case PL
      of P|T then
	      Ans
      in
      {Send P sayMineExplode(Id MinePos Ans)}
      {Wait Ans}
	      case Ans
	      of sayDeath(Id) then
            {Broadcast PL Ans}
            {Send GUI removePlayer(Id)}
	      [] sayDamageTaken(Id _ LifeLeft) then
            {Broadcast PL Ans}
            {Send GUI lifeUpdate(Id LifeLeft)}
         else 
	         skip
	      end
	      {BroadcastMineExp T Id MinePos GUI}
      [] nil then
	      skip
      end
   end

    %Wait (thinMin - thinkMax)
   proc{SimulateThink}
      {Delay (({OS.rand} mod (Input.thinkMax - Input.thinkMin + 1)) + Input.thinkMin)}
   end

   PlayerPorts
   GUIPort
in
   PlayerPorts = {PlayerMaker Input.players 1}
   GUIPort = {GUI.portWindow}
   {Send GUIPort buildWindow}
   {InitPlayers PlayerPorts GUIPort}
   if Input.isTurnByTurn then
      {RunTurnByTurn GUIPort PlayerPorts}
   else
      {RunSimultaneous PlayerPorts GUIPort}
   end
end