
```k
requires "javalette-syntax.md"

module JAVALETTE-ENV
    imports JAVALETTE-SYNTAX
    imports MAP
    imports LIST
    imports BOOL
    

    syntax Bool ::= envContains(List, KItem) [function, functional]
    rule envContains(ListItem(A:Map) As, K) => (K in_keys(A)) 
                                       orBool envContains(As, K)
    rule envContains(_, _) => false [owise]
    
    syntax Type ::= envLookup(List, KItem) [function]
    rule envLookup(ListItem(M:Map) _, V)    => {M[V]}:>Type               requires V in_keys(M)
    rule envLookup(ListItem(_:Map) Rest, V) => envLookup(Rest, V) [owise]

    syntax Bool ::= envTopContains(List, KItem) [function, functional]
    rule envTopContains(ListItem(M:Map) _,    V) => true               requires V in_keys(M)
    rule envTopContains(                _,    _) => false              [owise]

    syntax List ::= envMake(Params) [function]
    rule envMake(Ps) => ListItem(mkFrame(Ps)) 
    syntax Map ::= mkFrame(Params)                   [function, private]
    syntax Map ::= mkFrameAcc(Params , Map)          [function, private]
    rule mkFrame( Ps:Params ) => mkFrameAcc(Ps , .Map)
    rule mkFrameAcc( .Params , Acc ) => Acc 
    rule mkFrameAcc( (T:Type V:Id , Ps:Params) , Acc:Map ) 
            => mkFrameAcc(Ps, (V |-> T) Acc) requires notBool (V in_keys(Acc))

    syntax List ::= envInsert(Id, Type, List) [function]
    rule envInsert(V, T, ListItem(M:Map) Rest) => ListItem(M[V <- T]) Rest

    
endmodule
```