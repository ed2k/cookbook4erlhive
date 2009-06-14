-module(yawsinit).
-compile(export_all).
%-export([start/0,update_ip/0,postit_server/1,postit_get/0,postit_new/1]).
% TODO
% test in process postit server impl.
% test ip update
start() ->
  erlang:set_cookie(node(),'sunyin'),
  mnesia:start(),
  Pid = spawn(?MODULE,postit_server,[""]),
  register(postit_server,Pid),
  R = update_ip(),
  error_logger:info_report(R),
  mqueue_server_new(),
  done.

update_ip() ->
 % get extern ip
 {ok,{_,_,S}}= http:request("http://checkip.dyndns.com"),
 Idx = string:str(S,"Address: "),
 S1 = string:substr(S,Idx),
 I2 = string:str(S1, "<"),
 IP = string:substr(S1, 10, I2-10),
 % inet:getaddr("ed2k.selfip.org",inet) -> ok, OldIP
 % check if need to update ip
 URL = "http://urusernamehere:c6f08145330f335462bf8ef27707b500@members.dyndns.org/nic/update?hostname=ed2k.selfip.org&myip="++IP++"&wildcard=NOCHG&mx=NOCHG&backmx=NOCHG",
 http:request(get,{URL,[{"User-Agent","Erlang-Http-0.1"}]},[],[]).

postit_get() ->
 Pid = whereis(postit_server),
 Pid ! {get, self()},
 receive Data -> Data end.

postit_new(Data) ->
 Pid = whereis(postit_server),
 Pid ! {new, Data}.

postit_server(Data) ->
  receive 
   {new, NewData} -> postit_server(NewData);
   {get, PID} -> PID ! Data, postit_server(Data);
   stop -> stop
  end.

mqueue_server_new() ->
  Pid = spawn(?MODULE,mqueue_server,[[]]),
  register(mqueue_server,Pid).
    
mqueue_get() ->
 Pid = whereis(mqueue_server),
 Pid ! {get, self()},
 receive Data -> Data end.

mqueue_server([]) ->
  Tid = ets:new(mqueue_pid_dict,[public]),
  mqueue_server(Tid);
mqueue_server(Data) ->
  receive 
   {get, PID} -> PID ! Data, mqueue_server(Data);
   stop -> stop
  end.

message_recv(To) ->
    PidDict = mqueue_get(),
    
    case ets:lookup(PidDict,To) of [] -> [];
        [{To,D}] -> ets:delete(PidDict, To),
                    D
    end.

message_send(From, To,Data) ->
    D = message_recv(To),
    PidDict = mqueue_get(),
    ets:insert(PidDict, {To, [{From, Data} | D]}).
    

% input list of directories, how many days to look back
% return list of files
whatsnew(ListOfDirs, WhithinDays) when is_integer(WhithinDays) ->
  Fdir = fun(Dir, Acc) ->
    {ok, F1} = file:list_dir(Dir),
    N = [filename:join(Dir,X) || X <- F1],
    Acc ++ N
  end,
  L = lists:foldl(Fdir, [], ListOfDirs),  
  Today = calendar:date_to_gregorian_days(date()),
  % get file whithin a week
  Filter = fun(File) ->
   {T,_} = filelib:last_modified(File),
   D1 = calendar:date_to_gregorian_days(T),
   if (D1+WhithinDays) > Today -> true;
     true -> false
   end
  end,
  lists:filter(Filter,L).

