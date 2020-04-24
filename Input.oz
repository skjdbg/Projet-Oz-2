functor
import
   OS
export
   isTurnByTurn:IsTurnByTurn
   nRow:NRow
   nColumn:NColumn
   map:Map
   nbPlayer:NbPlayer
   players:Players
   colors:Colors
   thinkMin:ThinkMin
   thinkMax:ThinkMax
   turnSurface:TurnSurface
   maxDamage:MaxDamage
   missile:Missile
   mine:Mine
   sonar:Sonar
   drone:Drone
   minDistanceMine:MinDistanceMine
   maxDistanceMine:MaxDistanceMine
   minDistanceMissile:MinDistanceMissile
   maxDistanceMissile:MaxDistanceMissile
   guiDelay:GUIDelay
define
   IsTurnByTurn
   NRow
   NColumn
   Map
   NbPlayer
   Players
   Colors
   ThinkMin
   ThinkMax
   TurnSurface
   MaxDamage
   Missile
   Mine
   Sonar
   Drone
   MinDistanceMine
   MaxDistanceMine
   MinDistanceMissile
   MaxDistanceMissile
   GUIDelay

   RowMin
   RowMax
   ColMin
   ColMax
   ColGenerator
   RowGenerator
   PercentIsland
in

%%%% Style of game %%%%

   IsTurnByTurn = false

%%%% Description of the map %%%%

   %Minimum and Maximun number of row/column
   RowMin = 5
   RowMax = 10
   ColMin = 5
   ColMax = 10
   %Genrate random NRow and Ncolumn
   NRow = (({OS.rand} mod (RowMax - RowMin)) + RowMin)
   NColumn = (({OS.rand} mod (ColMax - ColMin)) + ColMin)

   %Percent of island (Exemple : if 10% then 100/10 -> number = 10, if 20% then 100/20 -> number = 5
   PercentIsland = 10

   %Generate random Column
   fun{ColGenerator Col}
      if (Col == 0) then nil
      else
         %if number random = 3 then island (1) else water (0)
         if (({OS.rand} mod PercentIsland) == 3) then
            1|{ColGenerator Col-1}
         else
            0|{ColGenerator Col-1}
         end
      end
   end

   fun{RowGenerator Row}
      if (Row =< 0) then nil
      else
         {ColGenerator NColumn}|{RowGenerator Row-1}
      end
   end


   Map = {RowGenerator NRow}
   /*NRow = 10
   NColumn = 10
   Map = [[0 0 0 0 0 0 0 0 0 0]
	  [0 0 0 0 0 0 0 0 0 0]
	  [0 0 0 1 1 0 0 0 0 0]
	  [0 0 1 1 0 0 1 0 0 0]
	  [0 0 0 0 0 0 0 0 0 0]
	  [0 0 0 0 0 0 0 0 0 0]
	  [0 0 0 1 0 0 1 1 0 0]
	  [0 0 1 1 0 0 1 0 0 0]
	  [0 0 0 0 0 0 0 0 0 0]
	  [0 0 0 0 0 0 0 0 0 0]] */

%%%% Players description %%%%

   NbPlayer = 3
   Players = [player player player]
   Colors = [red green c(155 200 0)]

%%%% Thinking parameters (only in simultaneous) %%%%

   ThinkMin = 100
   ThinkMax = 300

%%%% Surface time/turns %%%%

   TurnSurface = 3

%%%% Life %%%%

   MaxDamage = 3

%%%% Number of load for each item %%%%

   Missile = 3
   Mine = 3
   Sonar = 3
   Drone = 3

%%%% Distances of placement %%%%

   MinDistanceMine = 1
   MaxDistanceMine = 2
   MinDistanceMissile = 1
   MaxDistanceMissile = 4

%%%% Waiting time for the GUI between each effect %%%%

   GUIDelay = 500 % ms

end
