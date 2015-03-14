
```
erlhive:run_this_once().
mnesia:start().

erlhive:admin(fun(M) -> M:create_user(<<"sy">>, []) end).
erlhive:admin(fun(M) -> M:list_users() end).
erlhive:admin(fun(M) -> M:set_account_info(<<"sy">>,[coudebeanything,<<"test">>,{1,2},"aaa"]) end).
erlhive:admin(fun(M) -> M:describe_user(<<"joe">>) end).
erlhive:admin(fun(M) -> M:statistics(<<"root">>) end).

erlhive:with_user(<<"joe">>,fun(M) -> M:get_account_info() end).
erlhive:with_user(<<"joe">>,fun(M) -> M:list_variables() end).
erlhive:with_user(<<"joe">>,fun(M) -> M:delete_variable(n2) end).
erlhive:with_user(<<"joe">>,fun(M) -> M:get_variable(top_blog) end).
erlhive:with_user(<<"joe">>,fun(M) -> M:get_module_src(top_blog) end).
erlhive:with_user(<<"blog">>,fun(M) -> M:list_elements(ba) end).

erlhive:with_user(<<"blog">>,fun(M) -> M:apply(erlhive.user,list_blog,<<"joe">>) end).
erlhive:with_user(<<"sy">>,fun(M) -> M:get_account_info() end).
erlhive:with_user(<<"sy">>,fun(M) -> M:create_variable(va,[]) end).
erlhive:with_user(<<"sy">>,fun(M) -> M:list_elements(va) end).

% get all data select *
mnesia:transaction(fun() -> qlc:eval(qlc:q([X||X <- mnesia:table(blog)])) end).
mnesia:transaction(fun() -> mnesia:select(blog,[{#r{key='$1', _='_'},[],['$1']}]) end). 

mnesia:transaction(fun() -> mnesia:read(sy_meta,userData,read) end).
erlhive:with_user(<<"blog">>,fun(M) -> M:list_elements([ba,<<"joe">>]) end).


```