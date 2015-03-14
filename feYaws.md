
```
<erl>
%% simple file explorer

box(Str) ->
    {'div',[{class,"box"}],
     {pre,[], yaws_api:htmlize(Str)}}.

default_user(A) ->
    case queryvar(A,"f") of
        undefined -> "/mnt/hdc5/erlhive/nofrills-1.0/src";
        {ok, Val} ->
            Val
    end.

admin1(Cmd,F) ->
  case filelib:is_dir(F) of
    true -> {ok,U} = file:list_dir(F),
        lists:flatten(io_lib:print(U));
    _ -> {ok,U} = file:read_file(F),
         binary_to_list(U)
  end. 
    

out(A) ->
  [
  {ehtml,
      {'div',[{id, "entry"}], [
       {form,[{action,"/fe.yaws"}
        ],
        [
         {input,[{type,text},{name,f},{size,90},{value,default_user(A)}]},
         {input,[{type,submit},{value,"gooo"}]}
        ]},
        box(io_lib:format('~p', [yaws_api:parse_query(A)])),
        box(admin1(default_command,default_user(A)))
      ]}
   }].
</erl>

```