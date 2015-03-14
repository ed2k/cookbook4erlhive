
```
-module(telnetlib).

-export([connect/0, connect/2, write/2, close/1]).
-export([test/0]).


% Telnet protocol characters (don't change)                                     
-define(IAC  ,255). % "Interpret As Command"                                        
-define(DONT ,254).                                                                 
-define(DO   ,253).                                                                 
-define(WONT ,252).                                                                 
-define(WILL ,251).                                                                 
-define(NULL ,0).                                                                
                                                                                
-define(SE  ,240). % Subnegotiation End                                            
-define(NOP ,241). % No Operation                                                  
-define(DM  ,242). % Data Mark                                                     
-define(BRK ,243). % Break                                                         
-define(IP  ,244). % Interrupt process                                             
-define(AO  ,245). % Abort output                                                  
-define(AYT ,246). % Are You There                                                 
-define(EC  ,247). % Erase Character                                               
-define(EL  ,248). % Erase Line                                                    
-define(GA  ,249). % Go Ahead                                                      
-define(SB  ,250). % Subnegotiation Begin                                          
                                            
% Telnet protocol options code (don't change)                                   
% These ones all come from arpa/telnet.h                                        
-define(BINARY ,0). % 8-bit data path                                               
-define(ECHO ,1). % echo                                                            
-define(RCP ,2). % prepare to reconnect                                             
-define(SGA ,3). % suppress go ahead                                                
-define(NAMS ,4). % approximate message size                                        
-define(STATUS ,5). % give status                                                   
-define(TM ,6). % timing mark                                                       
-define(RCTE ,7). % remote controlled transmission and echo                         
-define(NAOL ,8). % negotiate about output line width                               
-define(NAOP ,9). % negotiate about output page size                                
-define(NAOCRD ,10). % negotiate about CR disposition                               
-define(NAOHTS ,11). % negotiate about horizontal tabstops                          
-define(NAOHTD ,12). % negotiate about horizontal tab disposition                   
-define(NAOFFD ,13). % negotiate about formfeed disposition                         
-define(NAOVTS ,14). % negotiate about vertical tab stops                           
-define(NAOVTD ,15). % negotiate about vertical tab disposition                     
-define(NAOLFD ,16). % negotiate about output LF disposition                        
-define(XASCII ,17). % extended ascii character set                                 
-define(LOGOUT ,18). % force logout                                                 
-define(BM ,19). % byte macro                                                       
-define(DET ,20). % data entry terminal                                             
-define(SUPDUP ,21). % supdup protocol                
-define(SUPDUPOUTPUT ,22). % supdup output                                          
-define(SNDLOC ,23). % send location                                                
-define(TTYPE ,24). % terminal type                                                 
-define(EOR ,25). % end or record                                                   
-define(TUID ,26). % TACACS user identification                                     
-define(OUTMRK ,27). % output marking                                               
-define(TTYLOC ,28). % terminal location number                                     
-define(VT3270REGIME ,29). % 3270 regime                                            
-define(X3PAD ,30). % X.3 PAD                                                       
-define(NAWS ,31). % window size                                                    
-define(TSPEED ,32). % terminal speed                                               
-define(LFLOW ,33). % remote flow control                                           
-define(LINEMODE ,34). % Linemode option                                            
-define(XDISPLOC ,35). % X Display Location                                         
-define(OLD_ENVIRON ,36). % Old - Environment variables                             
-define(AUTHENTICATION ,37). % Authenticate                                         
-define(ENCRYPT ,38). % Encryption option                                           
-define(NEW_ENVIRON ,39). % New - Environment variables                             
% the following ones come from                                                  
% http://www.iana.org/assignments/telnet-options                                
% Unfortunately, that document does not assign identifiers                      
% to all of them, so we are making them up                                      
-define(TN3270E ,40). % TN3270E                                                     
-define(XAUTH ,41). % XAUTH
-define(CHARSET ,42). % CHARSET                                                     
-define(RSP ,43). % Telnet Remote Serial Port                                       
-define(COM_PORT_OPTION ,44). % Com Port Control Option                             
-define(SUPPRESS_LOCAL_ECHO ,45). % Telnet Suppress Local Echo                      
-define(TLS ,46). % Telnet Start TLS                                                
-define(KERMIT ,47). % KERMIT                                                       
-define(SEND_URL ,48). % SEND-URL                                                   
-define(FORWARD_X ,49). % FORWARD_X                                                 
-define(PRAGMA_LOGON ,138). % TELOPT PRAGMA LOGON                                   
-define(SSPI_LOGON ,139). % TELOPT SSPI LOGON                                       
-define(PRAGMA_HEARTBEAT ,140). % TELOPT PRAGMA HEARTBEAT                           
-define(EXOPL ,255). % Extended-Options-List                                        
-define(NOOPT ,0).  

-define(dbg(X,Y),io:format(X,Y)).

-record(state, {
  sock = undefined,
  buffer = "",
  iac = undefined,
  st = undefined

   }).



test() ->
  Conn = connect(),
  sleep(2),
  write(Conn,"root"),
  sleep(2),
  write(Conn, "root"),
  sleep(2),
  write(Conn, "cat /proc/stat"),
  sleep(10),
  write(Conn, "exit"),
  
  close(Conn).

sleep(Sec) -> receive aaa -> aaa after Sec*1000 -> aaa end.

connect() ->
        connect("xxxx", 23).

connect(Server, Port) ->
        case gen_tcp:connect(Server, Port, [binary, {packet, 0}], 3000) of
                {ok, Socket} ->  {ok, Socket, connect_receiver(Socket)};
                {error, Reason} -> {error, Reason}
        end.
        
write({ok, Socket, _}, Data) ->
        gen_tcp:send(Socket, Data ++ "\r\n").

close({ok, Socket, ReceiverPID}) ->
        ReceiverPID ! die,
        gen_tcp:close(Socket).

receiver(Socket) ->
        receiver(Socket, "", undefined).

receiver(Socket, Log, Writer) ->
        receive
                {tcp, Socket, Data} ->
                        %io:format("D: ~w~n",[Data]),
			handle_recv(Data,#state{st=ok,sock=Socket},""),
                        receiver(Socket, Log, Writer);
                {tcp_closed, Socket} ->
                        receiver(Socket, Log, Writer);
                die ->
                        ok;
                {get_log, Sender} ->
                        Sender ! {log, Log},
                        receiver(Socket, Log, Writer)
        end.

dbgs(Text) -> ?dbg("~s", [Text]).

% assume IAC command is complete in one Data segment
handle_recv(<<>>, State, "") -> State;
handle_recv(<<>>, S, Text) ->
        dbgs(Text),
	Data = S#state.buffer,
        S#state{buffer = Data++Text };

handle_recv(<<?IAC, Tail/binary>>, #state{st=iac}=S, Text) -> handle_recv(Tail, S#state{st=undefined}, Text++?IAC);
handle_recv(<<C, Tail/binary>>, #state{st=iac}=S, Text) -> handle_recv(Tail, S#state{st=iac2,iac=C}, Text);
handle_recv(<<Head, Tail/binary>>, #state{iac=?WILL, sock=Sock} = S, Text) -> 
   iac_echo(Sock, ?DONT, Head),
   handle_recv(Tail, S#state{st=undefined, iac=undefined}, Text);
handle_recv(<<Head, Tail/binary>>, #state{iac=?WONT, sock=Sock} = S, Text) -> 
   iac_echo(Sock, ?DONT, Head),
   handle_recv(Tail, S#state{st=undefined, iac=undefined}, Text);
handle_recv(<<Head, Tail/binary>>, #state{iac=?DO, sock=Sock} = S, Text) -> 
   iac_echo(Sock, ?WONT, Head),
   handle_recv(Tail, S#state{st=undefined, iac=undefined}, Text);
handle_recv(<<Head, Tail/binary>>, #state{iac=?DONT, sock=Sock} = S, Text) -> 
   iac_echo(Sock, ?WONT, Head),
   handle_recv(Tail, S#state{st=undefined, iac=undefined}, Text);

handle_recv(<<?IAC, Tail/binary>>, S, Text) ->
   handle_recv(Tail, S#state{st=iac}, Text);
handle_recv(<<?NULL, Tail/binary>>, S, Text) -> handle_recv(Tail, S, Text);
handle_recv(<<?XASCII, Tail/binary>>, S, Text) -> handle_recv(Tail, S, Text);

handle_recv(<<Char, Tail/binary>>, State, Text) ->
   %io:format("char ~p~n",[Char]),
   handle_recv(Tail,State,Text++[Char]);
handle_recv(_,_,_) -> io:format("something wrong~n").


iac_echo(Sock, Cmd, Opt) -> 
  %?dbg("echo IAC ~w ~w~n",[Cmd,Opt]),
  gen_tcp:send(Sock, <<?IAC,Cmd,Opt>>).

connect_receiver(Socket) ->
        Receiver = spawn(fun() -> receiver(Socket) end),
        gen_tcp:controlling_process(Socket, Receiver),
        Receiver.
```