functor
import
    GUI
    Input
    PlayerManager
define
    % iterates over ListPlayerTypes and creates a list of the corresponding players' ports
    % Id is just an accumulator and should start as 1
    fun {TakeNth L N}
        if N > 1 then
            case L
            of H|T then
                {TakeNth T N-1}
            end
        else
            L.1
        end 
    end
    fun {PlayerMaker ListPlayerTypes Id}
        case ListPlayerTypes
        of H|T then
            % we are not certain Input.nbPlayers is equal to the number of players in Input.players
            % hence the if which looks redundant
            if Id =< Input.nbPlayer then
                % threads because why not
                thread {PlayerManager.playerGenerator H {TakeNth Input.colors N} Id} end|{PlayerMaker Id+1}
            else
                nil
            end
        [] nil then
            nil
        end
    end
    PlayerPorts = {PlayerMaker Input.players 1}
    GUIPort = {GUI.portWindow}

    % used to detect that all the players are initialized
    PlayersInitPort PlayersInitStream 
    {NewPort PlayersInitStream PlayersInitPort}

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

    proc {RunTurnByTurn PlayerPorts GUI}
        proc {HandlePlayer Port DiveStatus}
            case DiveStatus 
            of surface(N) then
                if N >= 0 then
                    {HandlePlayer Port surface(N-1)}
                else
                    Id Pos Dir
                in
                    {Send Port dive}
                    {Send Port move(Id Pos Dir)}
                    {Wait Id}
                    {Wait Pos}
                    {Wait Dir}
                    case Dir
                    of surface then
                        % Player has chosen to make surface => make him skip Input.turnSurface turns (including this one)
                        % TODO: broadcast to other players saySurface(Id)
                        {Send GUI surface(Id)}
                        {HandlePlayer Port surface(Input.turnSurface - 2)}
                    else
                        IdCharge ItemKind
                        IdFire FireKind
                        IdMine Mine
                    in
                        %TODO: broadcast to other players sayMove(Id Dir)
                        {Send GUI movePlayer(Id Pos)}
                        {Send Port chargeItem(IdCharge ItemKind)}
                        {Wait IdCharge}
                        {Wait ItemKind}

                        %TODO: find a way to implement this
                        if ItemKind \= null then   (means "if an item was produced")   =
                            %TODO: broadcast to other players sayCharge(IdCharge ItemKind)
                        end

                        {Send Port fireItem(IdFire FireKind)}
                        {Wait IdFire}
                        {Wait FireKind}
                        case FireKind
                        of mine(Pos) then
                            %TODO: broadcast to other players sayMinePlaced(IdFire)
                        [] missile(PosMiss) then
                            %TODO: broadcast to other players sayMissileExplode(IdFire PosMiss ?Message)
                            %TODO: broadcast to other players Message if any
                        [] drone() then
                            %TODO: broadcast to other players sayPassingDrone(Drone ?ID ?Answer)
                            %TODO: and send every answer to the player: sayAnswerDrone(Drone Id Answer)
                        [] sonar then
                            %TODO: broadcast to every(?) player sayPassingSonar(?Id ?Answer)
                            %TODO: and send answers back: sayAnswerSonar(Id Answer)
                        [] _ then  % includes the "null" case
                            skip
                        end

                        {Send Port fireMine(IdMine Mine)}
                        {Wait IdMine}
                        {Wait Mine}
                        case Mine
                        of null then
                            skip
                        else
                            %TODO: broadcast to other players sayMineExplode(IdMine Mine ?Message)
                            %TODO: broadcast to other players Message if any
                        end
                        {HandlePlayer Port DiveStatus}
                    end
                end
            else
                {Show "DiveStatus not correct :"}
                {Show DiveStatus}
            end
        end
    in
        for PP in PlayerPorts do
            {Send PP dive}
            thread {HandlePlayer PP true} end
        end
    end

    proc {RunSimultaneous PlayerPorts}

    end
in
    {Send GUIPort buildWindow}
    for PP in PlayerPorts do
        % multithreading because speeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeed
        thread
            Id Pos
        in
            {Send PP initPosition(Id Pos)}
            {Send GUIPort initPlayer(Id Pos)}
            {Wait Id}
            {Wait Pos}
            {Send PlayersInitPort 1}
        end
    end
    {WaitForN Input.nbPlayer PlayersInitStream}

    if Input.isTurnByTurn then
        {RunTurnByTurn PlayerPorts GUIPort}
    else
        {RunSimultaneous PlayerPorts GUIPort}
    end

    % Launch game ... how ?
end
