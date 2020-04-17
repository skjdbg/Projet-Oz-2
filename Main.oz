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
        proc {Broadcast PL Msg}
            for P in PL do
                {Send P Msg}
            end
        end

        proc {BroadcastMissExp PL Id MissPos}
            case PL
            of P|T then
                Ans
            in
                thread
                    {Send P sayMissileExplode(Id MissPos Ans)}
                    {Wait Ans}
                    case Ans
                    of null then skip
                    else
                        {Broadcast PL Ans}
                    end
                end
                {BroadcastMissExp T Id MissPos}
            [] nil then
                skip
            end
        end

        proc {BroadcastDrone PL PAns Drone}
            case PL
            of P|T then
                Id Ans
            in
                thread
                    {Send P sayPassingDrone(Drone Id Ans)}
                    {Wait Id}
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
                thread
                    {Send P sayPassingSonar(Id Ans)}
                    {Wait Id}
                    {Wait Ans}
                    {Send PAns sayAnswerSonar(Id Ans)}
                end
                {BroadcastDrone T PAns}
            [] nil then
                skip
            end

        end

        proc {BroadcastMineExp PL Id MinePos}
            case PL
            of P|T then
                Ans
            in
                thread
                    {Send P sayMineExplode(Id MinePos Ans)}
                    {Wait Ans}
                    case Ans
                    of null then skip
                    else
                        {Broadcast PL Ans}
                    end
                end
                {BroadcastMineExp T Id MinePos}
            [] nil then
                skip
            end
        end

        % Port => this submarine's port
        % EPL => List of the ennemies' port
        % DiveStatus < 1 => the submarine is underwater
        % DiveStatus > 0 => the submarine has surfaced and has to wait DiveStatus turns
        proc {HandlePlayer Port EPL DiveStatus}
            %TODO: Calls to GUI
            if DiveStatus > 0 then
                {HandlePlayer Port EPL surface(DiveStatus-1)}
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
                    {Broadcast EPL saySurface(Id)}
                    {Send GUI surface(Id)}
                    {HandlePlayer Port EPL Input.turnSurface-1}
                else
                    IdCharge ItemKind
                    IdFire FireKind
                    IdMine Mine
                in
                    {Broadcast EPL sayMove(Id Dir)}
                    {Send GUI movePlayer(Id Pos)}
                    {Send Port chargeItem(IdCharge ItemKind)}
                    {Wait IdCharge}
                    {Wait ItemKind}

                    if ItemKind \= null then
                        {Broadcast EPL sayCharge(IdCharge ItemKind)}
                    end

                    {Send Port fireItem(IdFire FireKind)}
                    {Wait IdFire}
                    {Wait FireKind}
                    case FireKind
                    of mine(Pos) then
                        {Broadcast EPL sayMinePlaced(IdFire)}
                    [] missile(PosMiss) then
                        {BroadcastMissExp PlayerPorts IdFire PosMiss}
                    [] drone() then
                        {BroadcastDrone PlayerPorts Port FireKind}
                    [] sonar then
                        {BroadcastSonar PlayerPorts Port}
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
                        {BroadcastMineExp PlayerPorts IdMine Mine}
                    end
                    {HandlePlayer Port EPL DiveStatus}
                end
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
