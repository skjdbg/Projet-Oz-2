functor
import
   OS
   System(show:Show)
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
   NbColors
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
   %ColorGenerator
   RandomColor
   ConvertColors
   UserColors
in

%%%% Style of game %%%%

   IsTurnByTurn = false

%%%% Description of the map %%%%

  %%%%%%% USER Preferences %%%%%%%%%

   %Minimum and Maximun number of row/column
   RowMin = 5
   RowMax = 10
   ColMin = 5
   ColMax = 10

   %Average Percentage of island
   PercentIsland = 10

  %%%%%%%  End of USER Preferences %%%%%%%%%


  %Genrate random NRow and Ncolumn
   NRow = (({OS.rand} mod (RowMax - RowMin + 1)) + RowMin)
   NColumn = (({OS.rand} mod (ColMax - ColMin + 1)) + ColMin)

   

   %Generate random Column
   fun{ColGenerator Col}
      if (Col == 0) then nil
      else
         %if number random = 3 then island (1) else water (0)
         if (({OS.rand} mod 100) < PercentIsland) then
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

   /* NRow = 10
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
	  [0 0 0 0 0 0 0 0 0 0]]  */


%%%%% FUN COLOR GENRATOR %%%%%
/*fun{ColorGenerator NPlayer}
   if NPlayer == 0 then
      nil
   else
      c({RandomColor} {RandomColor} {RandomColor})|{ColorGenerator NPlayer-1}
   end
end*/

fun{RandomColor}
   {OS.rand} mod 256
end

fun {ConvertColors L}
   case L
   of random|T then
      c({RandomColor} {RandomColor} {RandomColor})|{ConvertColors T}
   [] H|T then
      H|{ConvertColors T}
   else
      nil
   end
end

%%%% Players description %%%%

   Players = [player072smart player player player]
   NbPlayer = {Length Players}

   % each random will be converted to a random color
   UserColors = [red blue random c(100 155 0)]

   Colors = {ConvertColors UserColors}
   NbColors = {Length Colors}
   if NbColors \= NbPlayer then
      {Show "Player Description incorrect"}
      {Show "The number of Players and Colors must be equal"}
   end



%%%% Thinking parameters (only in simultaneous) %%%%

   ThinkMin = 10
   ThinkMax = 30

%%%% Surface time/turns %%%%

   TurnSurface = 3

%%%% Life %%%%

   MaxDamage = 10

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