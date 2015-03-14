
```
<erl>
%% test user eval erlhive string 

a2d(A,Key) -> 
  case postvar(A,Key) of
     undefined -> "xxfun -> ";
     {ok,V} -> V
  end.

box(Str) ->
    {'div',[{class,"box"}],
     {pre,[], yaws_api:htmlize(Str)}}.

default_user(A) ->
    case postvar(A,"u") of
        undefined -> "sy";
        {ok, Val} ->
            Val
    end.

get_m_src(A) ->
  a2d(A,"src").

eval_str(A) ->
  W = list_to_binary(default_user(A)),
  Src= a2d(A,"src"),
  U = erlhive:with_user(W,fun(M)->M:eval(Src) end),
  lists:flatten(io_lib:print(U)).

out(A) ->
  [
  {ehtml,
    {'div', [],[
       {form,[{action,"/multi_line_input.yaws"},{method,post}
        ],
        [
         {input,[{type,text},{name,u},{value,default_user(A)}]},
         {input,[{type,submit},{value,"run src"}]},
         {textarea,[{rows,5},{cols,120},{name,src}],get_m_src(A)}
        ]},
        box(eval_str(A))
     ]}
   }].
</erl>
```