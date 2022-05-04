
```k
requires "../core/javalette-syntax-core.md"

module JAVALETTE-ARRAYS-SYNTAX
    imports JAVALETTE-SYNTAX-CORE

    syntax TypBox ::= r"\\[[ \\n\\t]*\\]" [token]
    syntax Type ::= Type TypBox [macro]

    syntax Exp ::= "new" Type Boxes      [unary]
                 | Exp Box               [funcall]
                 | Exp "." Id            [strict(1), unary]

    syntax Id ::= "length" [token]

    // array size
    syntax Box ::= "[" Exp "]"              [strict]
    syntax Boxes ::= NeList{Box, ""}

    syntax Stmt ::= "for" "(" Type Id ":" Exp ")" Stmt [strict(3)]

endmodule

module JAVALETTE-ARRAYS
    imports JAVALETTE-ARRAYS-SYNTAX
    imports JAVALETTE-TYPES
    imports JAVALETTE-EXECUTION
    imports JAVALETTE-RETURNCHECK

    syntax Type ::= "#arrayOf" "(" Type ")"
    rule T _:TypBox => #arrayOf(T)
    
    rule validDataType(#arrayOf(T)) => validDataType(T)

    rule inferExp(new T .Boxes) => T
    rule inferExp(new T [E] Bs) => arrayOf(inferExp(new T Bs))
        requires checkExp(int, E)

    syntax InferRes ::= arrayOf(InferRes) [function,functional]
    rule arrayOf(T:Type) => #arrayOf(T)
    rule arrayOf(#typeError) => #typeError

    rule inferExp(E . length) => int requires isArray(inferExp(E))
    
    syntax Bool ::= isArray(InferRes) [function,functional]
    rule isArray(#arrayOf(_)) => true
    rule isArray(_) => false [owise]
    
    rule isLValue(_:Exp [_]) => true    // array index
    rule isLValue(_ . length) => false    // array length
    rule isLValue(new _ _:Boxes) => false

    rule inferExp( Arr [ Ix ] ) => arrayElement(inferExp(Arr)) requires checkExp(int, Ix)
    syntax InferRes ::= arrayElement(InferRes) [function, functional]
    rule arrayElement( #arrayOf(T) ) => T
    rule arrayElement(_) => #typeError [owise]

    rule
        <tcode> (for( T X : Arr) Body) 
            => twithBlock( 
                (T X ;):Stmt ~> 
                twithBlock( Body )
            ) ... 
        </tcode>
        requires checkExp(#arrayOf(T), Arr)
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
    syntax Exp ::= "#elemAccess" "(" Exp "," Exp ")" [seqstrict]
    rule <k> (Arr:Exp ([Ix]):Box ):Exp => #elemAccess(Arr,Ix) ... </k>
    
    rule 
        <k> #elemAccess(array(Loc, Len), Ix) => X ...</k>
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
    
    rule defaultValue( #arrayOf(_) ) => array(0,0)
```

## For loops
For-loops are strict on the `Range` expression, so it is evaluated only once and before the loop. Consequently, the address and size of the array stays constant in the loop. 
```k

    rule 
        <k> for(T Var : Range) Body =>
            {   
                T Var;
                forUnroll(Var, Range, Body, 0)
            }
            ...
        </k>
        

    syntax Stmt ::= forUnroll(Id, Value, Stmt, Int)

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
    rule isLValue(newArray(_,_)) => false
    rule isLValue(_ . length) => false      [owise]

    rule retcheckStmt(for(_ _ : _)_) => false
```


Arrays do not support equality (`==` or `!=`) operators.
```k
    rule isEquality( #arrayOf(_) ) => false
endmodule
```
