%!/usr/bin/env escript
%% tcp_server.erl
%% TCP echo + commands server (one-send fix)
%% Save as UTF-8 without BOM.

-module(tcp_server).
-export([main/1, start/0]).

-define(COMMANDS_FILE, "commands.txt").
-define(CONFIG_FILE, "server_config.json").
-define(LOG_FILE, "server.log").

%% escript entry
main(_Args) ->
    case do_start() of
        {ok, Port} ->
            io:format("Server started on port ~p. Logs -> ~s~n", [Port, ?LOG_FILE]),
            wait_forever();
        {error, Reason} ->
            io:format("Failed to start: ~p~n", [Reason]),
            halt(1)
    end.

start() ->
    case do_start() of
        {ok, Port} ->
            io:format("Server started on port ~p. Use Ctrl+C to stop.~n", [Port]),
            wait_forever();
        {error, Reason} ->
            io:format("Failed to start: ~p~n", [Reason]),
            {error, Reason}
    end.

do_start() ->
    case load_config() of
        {ok, Port} ->
            case load_commands() of
                {ok, Commands} ->
                    spawn(fun() -> listen_loop(Port, Commands) end),
                    {ok, Port};
                Error -> Error
            end;
        Error -> Error
    end.

wait_forever() ->
    receive
        after 1000000000 ->
            wait_forever()
    end.

%% Load port from server_config.json using regex
load_config() ->
    case file:read_file(?CONFIG_FILE) of
        {ok, Bin} ->
            S = binary_to_list(Bin),
            case re:run(S, "\"port\"\\s*:\\s*(\\d+)", [{capture, [1], list}]) of
                {match, [PortStr]} ->
                    try list_to_integer(PortStr) of
                        Port when is_integer(Port), Port > 0 ->
                            {ok, Port}
                    catch _:_ -> {error, invalid_port}
                    end;
                _ -> {error, port_not_found}
            end;
        {error, Reason} -> {error, {config_read_error, Reason}}
    end.

%% Read commands file: one command per line (case-insensitive)
load_commands() ->
    case file:read_file(?COMMANDS_FILE) of
        {ok, Bin} ->
            Lines = string:split(binary_to_list(Bin), "\n", all),
            Trimmed = [string:trim(L) || L <- Lines],
            Filtered = [string:to_upper(X) || X <- Trimmed, X =/= ""],
            {ok, Filtered};
        {error, Reason} -> {error, {commands_read_error, Reason}}
    end.

%% Networking: listen and accept
listen_loop(Port, Commands) ->
    Opts = [{active, false}, {packet, line}, {reuseaddr, true}],
    case gen_tcp:listen(Port, Opts) of
        {ok, ListenSock} ->
            io:format("Listening on port ~p~n", [Port]),
            accept_loop(ListenSock, Commands);
        {error, Reason} ->
            io:format("Failed to listen on ~p: ~p~n", [Port, Reason])
    end.

accept_loop(ListenSock, Commands) ->
    case gen_tcp:accept(ListenSock) of
        {ok, Sock} ->
            spawn(fun() -> client_process(Sock, Commands) end),
            accept_loop(ListenSock, Commands);
        {error, Reason} ->
            io:format("Accept error: ~p~n", [Reason]),
            timer:sleep(1000),
            accept_loop(ListenSock, Commands)
    end.

client_process(Sock, Commands) ->
    Peer = case inet:peername(Sock) of
               {ok, {IP, Port}} -> io_lib:format("~p:~p", [IP, Port]);
               _ -> "unknown"
           end,
    io:format("Client connected: ~s~n", [lists:flatten(Peer)]),
    loop_recv(Sock, Commands),
    gen_tcp:close(Sock),
    io:format("Client disconnected: ~s~n", [lists:flatten(Peer)]).

loop_recv(Sock, Commands) ->
    case gen_tcp:recv(Sock, 0) of
        {ok, Data} ->
            %% Data may be binary() or list()
            Line0 = case Data of
                        Bin when is_binary(Bin) -> binary_to_list(Bin);
                        L when is_list(L) -> L
                    end,
            Line = string:trim(Line0),
            {MaybeResult, _Logged} = maybe_execute_command(Line, Commands, Sock),
            Response = Line ++ "\r\n" ++ (case MaybeResult of [] -> []; R -> "RESULT: " ++ R ++ "\r\n" end),
            %% Отсылаем всё одним send
            ok = gen_tcp:send(Sock, Response),
            loop_recv(Sock, Commands);
        {error, closed} ->
            ok;
        {error, Reason} ->
            io:format("Recv error: ~p~n", [Reason]),
            ok
    end.

%% Если команда распознана и разрешена - возвращаем {ResultString, true}, иначе {[], false}.
maybe_execute_command(Line, Commands, _Sock) ->
    case string:tokens(Line, " \t") of
        [] -> {[], false};
        [Cmd|Rest] ->
            CmdUp = string:to_upper(Cmd),
            case lists:member(CmdUp, Commands) of
                true -> execute_command_nosend(CmdUp, Rest, Line);
                false -> {[], false}
            end
    end.

%% Возвращаемой строкой - только результат без "RESULT: " и без CRLF.
execute_command_nosend("TIME", _Args, Line) ->
    Res = format_time(),
    log_entry(Line, Res),
    {Res, true};
execute_command_nosend("REVERSE", Args, Line) ->
    Text = string:join(Args, " "),
    Res = lists:reverse(Text),
    ResStr = lists:flatten(Res),
    log_entry(Line, ResStr),
    {ResStr, true};
execute_command_nosend("UPPER", Args, Line) ->
    Text = string:join(Args, " "),
    Res = string:to_upper(Text),
    log_entry(Line, Res),
    {Res, true};
execute_command_nosend(Other, _Args, Line) ->
    Res = "UNKNOWN_COMMAND_HANDLER_" ++ Other,
    log_entry(Line, Res),
    {Res, true}.

format_time() ->
    {{Y, M, D}, {HH, MM, SS}} = calendar:local_time(),
    lists:flatten(io_lib:format("~4..0B-~2..0B-~2..0B ~2..0B:~2..0B:~2..0B",
                               [Y, M, D, HH, MM, SS])).

log_entry(CommandLine, Result) ->
    Ts = format_time(),
    Entry = lists:flatten(io_lib:format("~s - ~s - ~s~n", [Ts, CommandLine, Result])),
    case file:open(?LOG_FILE, [append]) of
        {ok, F} ->
            file:write(F, Entry),
            file:close(F);
        {error, Reason} ->
            io:format("Failed to write log: ~p~n", [Reason])
    end.
