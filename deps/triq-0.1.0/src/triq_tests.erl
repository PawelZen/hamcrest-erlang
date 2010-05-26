%%
%% This file is part of Triq - Trifork QuickCheck
%%
%% Copyright (c) 2010 by Trifork
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%  
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%

%%
%% This file contains some sample properties, which also
%% function as a very simple test suite for Triq itself.
%%

-module(triq_tests).

% including this also auto-exports all properties
-include("triq.hrl").

% use eunit
-include_lib("eunit/include/eunit.hrl").

%% eunit test!
triq_test() ->
    true = triq:check(?MODULE).

boolean_test() ->
    Unique = fun ordsets:from_list/1,
    ?assertEqual([false, true], Unique(triq:sample(boolean()))).

prop_append() ->
    ?FORALL({Xs,Ys},{list(int()),list(int())},
       ?TRAPEXIT(lists:reverse(Xs++Ys)
		 ==
		 lists:reverse(Ys) ++ lists:reverse(Xs))).
					 
delete_test() ->
    false = triq:check(
    ?FORALL(L,list(int()), 
	?IMPLIES(L /= [],
	    ?FORALL(I,elements(L), 
		?WHENFAIL(io:format("L=~p, I=~p~n", [L,I]),
		    not lists:member(I,lists:delete(I,L))))))).


inverse('<') -> '>=';
inverse('>') -> '=<';
inverse('==') -> '/=';
inverse('=:=') -> '=/=';
inverse('=/=') -> '=:=';
inverse('/=') -> '=='.

prop_binop() ->
    ?FORALL({A,B,OP}, {any(),any(),elements(['>','<','==','=:=','=/=','/='])},
	    erlang:OP(A,B) 
	    ==
	    begin 
		ROP = inverse(OP),
		not  ( erlang:ROP(A,B) )
	    end
	   ).


prop_timeout() ->
 fails(
   ?FORALL(N,choose(50,150),
     ?TIMEOUT(100,
       timer:sleep(N) == ok))).

prop_sized() ->
    ?FORALL(T, ?SIZED(S, {true, choose(0,S)}),
	    (erlang:tuple_size(T) == 2)
	    and
	    begin {true, Int} = T, Int >= 0 end
	   ).

prop_simple1() ->
    ?FORALL(V, [], V == []).

prop_simple2() ->
    ?FORALL(V, {}, V == {}).

prop_simple3() ->
    ?FORALL(V, atom(), 
	    ?IMPLIES(V /= '',
		     begin
			 [CH|_] = erlang:atom_to_list(V),
			 (CH >= $a) and (CH =< $z)
		     end)).


%%
%% This should be able to succeed
%%
prop_suchthat() ->
    ?FORALL({X,Y}, 
	    ?SUCHTHAT({XX,YY}, 
		      {int(),int()}, 
		      XX < YY), 
	    X < Y).


tuple_failure_test() ->
    false = check(?FORALL(T, {int()},
			  begin
			      {V} = T,
			      V > 0
			  end)).

oneof_test() ->
    [{X,Y}] = triq:counterexample(
	      ?FORALL({X,Y}, 
		      ?SUCHTHAT({A,B},
				{oneof([int(),real()]),
				 oneof([int(),real()])},
				A < B),
		      is_integer(X) == is_integer(Y))),

    %% Note: 0 == 0.0
    ?assert((X == 0) and (Y == 0)).

%%
%% This test makes sure that X shrinks only to 3. 
%%
oneof2_test() ->
    [X] = triq:counterexample
	    (?FORALL(X, 
		     oneof([choose(3,7)]),
		     false)),
    3 = X.

%%
%% Test that vector doesn't shrink the length
%%
vector_test() ->
    [L] = triq:counterexample
            (?FORALL(L, vector(4, choose(3,7)),
		     false)),
    [3,3,3,3] = L.

    
%%
%% Test binary shrinking
%%
binary_test() ->
    [X] = triq:counterexample
	    (?FORALL(X, binary(2), false)),
    <<0,0>> = X.

not_reach_rsn() ->
       ?LET(Rsn,choose(0,3),<<Rsn>>).

binary2_test() ->
    [X] = triq:counterexample
            (?FORALL(X, not_reach_rsn(), false)),

    case X of
	<<0>> -> ok;
	<<1>> -> ok;
	<<2>> -> ok;
	<<3>> -> ok
    end.

%%
%% Test shrinking of elements
%%
elements_test() ->
    [X] = triq:counterexample
	    (?FORALL(X, 
		     elements([one,two,three]),
		     false)),
    one = X.

