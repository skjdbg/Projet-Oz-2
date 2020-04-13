functor
import
    GUI
    Input
    PlayerManager
define
    % iterates over ListPlayerTypes and creates a list of the corresponding players' ports
    % Id is just an accumulator and should start as 1
    fun {PlayerMaker ListPlayerTypes Id}
        case ListPlayerTypes
        of H|T then
            % we are not certain Input.nbPlayers is equal to the number of players in Input.players
            % hence the if which looks redundant
            if Id <= Input.nbPlayers then
                % TODO: how do we chose Color ?
                % threads because why not
                thread {PlayerManager.playerGenerator H Color Id} end|{PlayerMaker Id+1}
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
                {SumN N-1 T}
            end
        else
            skip
        end
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
    {WaitForN Input.nbPlayers PlayersInitStream}

    % Launch game ... how ?
end
