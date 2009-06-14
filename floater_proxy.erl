-module(floater_proxy).

-compile(export_all).
%-export([test/0,start/3,listen/3,one_socket/1]).


test() -> start("111.113.118.116",10100).

start(Host,Port)->
    {ok, SockTarget} = gen_tcp:connect(Host,Port, [binary, {packet, 0}]),      
    Pid = spawn(?MODULE,one_socket,["flproxyA","flproxyB",SockTarget]),
    inet:setopts(SockTarget, [{active, true}]),
    gen_tcp:controlling_process(SockTarget, Pid),
    io:format("fl_proxy: target ~p handler ~p~n",[SockTarget,Pid]).


debug_http("t ",_) -> undefined;                  
debug_http(ID,Bytes)->
    String = binary_to_list(Bytes),
    {ok,[Headers|_]} = regexp:split(String,"\r\n\r\n"),
    {ok,[First|_]} = regexp:split(Headers,"\r\n"),
    io:format("~s~s~n",[ID,First]).

debug_bytes(ID,Bytes= <<"GIOP",_/binary>>)->
    % need to trap location_forward exception from request, dec_target_key
    M = cdr_decode:dec_message(any:create(),Bytes),
    io:format("~s~p~n",[ID,M]);
debug_bytes(ID,Bytes= <<"GET",_/binary>>)->debug_http(ID,Bytes);
debug_bytes(ID,Bytes= <<"POST",_/binary>>)->debug_http(ID,Bytes);
debug_bytes(ID,Bytes= <<"HTTP",_/binary>>)->debug_http(ID,Bytes);
debug_bytes(ID,Bytes) ->
    String = binary_to_list(Bytes),
    Len = string:len(String),
    io:format("~s~p ~s~n",[ID,Len,string:substr(String,1,10)]).

filter(Bytes= <<"GET",_/binary>>) ->
    String = binary_to_list(Bytes),
    {ok,[Headers|_]} = regexp:split(String,"\r\n\r\n"),
    {ok,[First|_]} = regexp:split(Headers,"\r\n"),
    {ok,[_,Path | _]} = regexp:split(First," "),  
    case regexp:split(Path,$.) of
        {ok,[_,"giff"]} ->
            {stop};
        _ -> 
            {undefined}
    end;
filter(_)->
    {undefined}.
dbg(T) -> io:format("~p~n",[T]). 	
one_socket(From, To, SockTarget)->
    receive
        {tcp, SockTarget, Bytes} ->
            debug_bytes("t ",Bytes),
            yawsinit:message_send(From,To, Bytes),
            one_socket(From, To, SockTarget);
        Other ->
            io:format("tcpproxy: got msg ~p~n", [Other])
    after 1000 -> 
        case  yawsinit:message_recv(From) of [] -> nothing;
          [{_, M} | _]  -> gen_tcp:send(SockTarget, M),
	    dbg(M)
        end,
        one_socket(From, To, SockTarget)
    end.
