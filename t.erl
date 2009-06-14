-module(t).
-export([checkpass/2]).
-include("./yaws_api.hrl").

% is argument from http cookie
checkpass(A, Mod) ->
  H = A#arg.headers,
  C = H#headers.cookie,
  Cookie = yaws_api:find_cookie_val("erlHiveWho", C) ,
  case yaws_api:cookieval_to_opaque(Cookie) of
     {ok, {auth, <<"root">>}} ->
     Mod(A)
  end.

