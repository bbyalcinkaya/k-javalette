
```k
requires "../core/javalette-syntax.md"

module JAVALETTE-ARRAYS
    imports JAVALETTE-SYNTAX
    imports JAVALETTE-TYPES
    imports JAVALETTE-EXECUTION

    rule inferExp(new T .Boxes) => T
    rule inferExp(new T [E] Bs) => arrayOf(inferExp(new T Bs))
        requires checkExp(int, E)

    syntax InferRes ::= arrayOf(InferRes) [function,functional]
    rule arrayOf(T:Type) => T[]
    rule arrayOf(#typeError) => #typeError
    
    rule inferExp(E . F) => int requires hasField(inferExp(E), F)
    
    syntax Bool ::= hasField(InferRes, Id) [function,functional]
    rule hasField(#typeError, _) => false
    rule hasField(_ [], length) => true 
    rule hasField(_, _) => false [owise]
    
    syntax Bool ::= isArray(InferRes, Id) [function,functional]
    rule isArray(_:Type [], length) => true
    rule isArray(_, _) => false [owise]
    
    rule isLValue(_:Exp [_]) => true    // array index
    
    rule inferExp( Arr [ Ix ] ) => arrayElement(inferExp(Arr)) requires checkExp(int, Ix)
    syntax InferRes ::= arrayElement(InferRes) [function, functional]
    rule arrayElement(T []) => T
    rule arrayElement(_) => #typeError [owise]

    rule
        <tcode> checkStmt(for( T X : Arr) Body) 
            => pushTBlock ~> checkStmt(T X ;) ~> checkStmt(Body) ~> popTBlock ... 
        </tcode>
        requires checkExp(T[], Arr)
```
## Creating arrays
```k
    syntax Value ::= array(Int, Int) // array(Location, Length)

    rule
        <k> (new T Bs):Exp => Bs ~> newArrayOf(T) ... </k>

    syntax KItem ::= newArrayOf(Type)
    syntax Exp ::= newArray(Type, Values)

    rule <k> Vs:Values ~> newArrayOf(T) => newArray(T, Vs) ... </k>
    rule <k> newArray(T, .Values) => defaultValue(T) ... </k>

    rule 
        <k> newArray(T, (S:Int, Ss)) => makeArrayElems(I, S, newArray(T,Ss) ) ~> array(I, S) ... </k>
        <next-loc> I => I +Int S </next-loc>

    syntax KItem ::= makeArrayElems(Int, Int, Exp)
    rule <k> makeArrayElems(_, 0, _) => . ... </k>
    rule 
        <k> 
            makeArrayElems(Loc, I, Elem) => 
            (array(Loc, 1)[0] = Elem ;) ~>
            makeArrayElems(Loc +Int 1, I -Int 1, Elem) ... 
        </k>
        requires I =/=Int 0
```

## Element access
```k
    rule 
        <k> array(Loc, Len) [ Ix:Int ] => X ...</k>
        <store> ... (Loc +Int Ix ) |-> X ... </store>
        requires Len >Int Ix
```
```k
    rule 
        <k> locate(Arr [Ix]) => locateArray(Arr, Ix) ... </k>
        
    syntax KItem ::= locateArray(Exp, Exp) [seqstrict]
    rule 
        <k> locateArray(array(Loc, Length), Ix:Int) => Loc +Int Ix ... </k>
        requires Ix <Int Length 
    
    rule <k> array(_, Length) . length => Length ... </k>
```

Evaluate `Boxes` to `Values`

```k
    syntax KItem ::= evalBoxesTail(Boxes)
                   | evalBoxesHead(Value)
    
    rule <k> .Boxes => .Values ... </k>
    rule <k> [A] Bs:Boxes => A ~> evalBoxesTail(Bs) ... </k>
    rule <k> V:Value ~> evalBoxesTail(Bs) => Bs ~> evalBoxesHead(V) ... </k>
    rule <k> Vs:Values ~> evalBoxesHead(V) => (V, Vs):Values ... </k>
    
    rule defaultValue(_:Type []) => array(0,0)
```

## For loops
```k

    rule 
        <k> for(T Var : Range) Body =>
            {   
                T Var;
                forUnroll(Var, Range, Body, 0)
            }
            ...
        </k>
        

    syntax Stmt ::= forUnroll(Id, Exp, Stmt, Int) [strict(2)]

    rule 
        <k> 
            forUnroll(Var, array(Loc, Len), Body, I) =>
            Var = array(Loc, Len)[I]; ~> 
            Body ~> 
            forUnroll(Var, array(Loc, Len), Body, I +Int 1)
            ...
        </k>
        requires I <Int Len
    rule <k> forUnroll(_, array(_, Len), _, I) => . ... </k>
        requires I >=Int Len
    

```


```k
endmodule
```