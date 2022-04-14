
```k
requires "javalette-io.md"

module JAVALETTE-EXECUTION
    imports INT
    imports FLOAT
    imports BOOL
    imports STRING

    imports JAVALETTE-CONFIGURATION
    imports JAVALETTE-SYNTAX
    imports JAVALETTE-TYPES
    imports JAVALETTE-IO

    configuration
        <exec>
            <k> .K </k>
            <env> .Map </env>
            <stack> .List </stack>
            <store> .Map </store>
            <next-loc> 0 </next-loc>
            <flag-run > $RUN:Int </flag-run>
        </exec>
        //<output stream="stdout"> .List </output>
        



    syntax KItem ::= "#execute"
                   | "#executing"
                   | "#executedone" "(" Value ")"

    rule 
        <progress>  #execute => #executing ... </progress>
        <k>     . => main(.Args) ... </k>
        <env>   _ => .Map </env>
        <stack> _ => .List </stack>
        <store> _ => .Map </store>
        <flag-run> 1 </flag-run>
    
    rule 
        <progress>  #execute => #executedone(0) ... </progress>
        <flag-run> 0 </flag-run>

    rule 
        <progress> #executing => #executedone(V) ... </progress>
        <k> V:Value ~> . => . </k>
        <env>   _ => .Map </env>
        <stack> _ => .List </stack>
        <store> _ => .Map </store>
        <funs>  _ => .Map </funs>


    
    syntax KResult ::= Value

    syntax Value ::= Int
                   | Float 
                   | Bool  
                   | "nothing"
                   
    syntax Values ::= List{Value, ","}
    
    syntax Exp ::= Value
    
    rule isLValue(_:Value) => false
```

## Expression evaluation
In binary operations, evaluation order is from left to right.

### Arithmetic operators
```k
    rule <k> (I1:Int) + I2 => I1 +Int I2 ... </k>
    rule <k> (I1:Float) + I2 => I1 +Float I2 ... </k>
    
    rule <k> (I1:Int) - I2 => I1 -Int I2 ... </k>
    rule <k> (I1:Float) - I2 => I1 -Float I2 ... </k>
    
    rule <k> (I1:Int) * I2 => I1 *Int I2 ... </k>
    rule <k> (I1:Float) * I2 => I1 *Float I2 ... </k>
    
    rule <k> (I1:Int) / I2 => I1 /Int I2 ... </k>
        requires I1 =/=Int 0
    rule <k> (I1:Float) / I2 => I1 /Float I2 ... </k>

    rule <k> I1 % I2 => I1 %Int I2 ... </k>

    rule <k> - (I:Int)   => 0 -Int I ... </k>
    rule <k> - (I:Float) => 0.0 -Float I ... </k>
```
### Comparison operators
```k
    rule <k> I1:Int >  I2 => I1 >Int  I2 ... </k>
    rule <k> I1:Float >  I2 => I1 >Float I2 ... </k>
    
    rule <k> I1:Int >= I2 => I1 >=Int I2 ... </k>
    rule <k> I1:Float >= I2 => I1 >=Float I2 ... </k>
    
    rule <k> I1:Int <  I2 => I1 <Int  I2 ... </k>
    rule <k> I1:Float <  I2 => I1 <Float I2 ... </k>
    
    rule <k> I1:Int <= I2 => I1 <=Int I2 ... </k>
    rule <k> I1:Float <= I2 => I1 <=Float I2 ... </k>
    
    rule <k> I1:Int == I2 => I1 ==Int I2 ... </k>
    rule <k> I1:Float == I2 => I1 ==Float I2 ... </k>
    rule <k> I1:Bool == I2 => I1 ==Bool I2 ... </k>
    
    rule <k> I1:Int != I2 => I1 =/=Int I2 ... </k>
    rule <k> I1:Float != I2 => I1 =/=Float I2 ... </k>
    rule <k> I1:Bool != I2 => I1 =/=Bool I2 ... </k>
```
### Logic operators
In `a && b` and `a || b`, `b` is only evaluated when necessary. 
```k
    rule <k> false:Value && _ => false:Value ... </k>
    rule <k> true:Value  && E => E ... </k>
    
    rule <k> false:Value || E => E ...    </k> 
    rule <k> true:Value  || _ => true:Value ... </k>

    rule <k> ! true:Value   => false:Value ... </k>
    rule <k> ! false:Value  => true:Value ... </k>
```

### Variable lookup

```k
    rule 
        <k> X:Id => V ...</k>
        <env> ... X |-> L ... </env>
        <store> ... L |-> V ...</store>
```

### Function call
```k

    syntax KItem ::= StackItem(K, Map)
    syntax KItem ::= applyFun( Id )
    rule <k> FUN:Id ( As ) => evalArgList(As) ~> applyFun( FUN ) ... </k> 
    rule 
        <k> As:Values ~> applyFun(FUN:Id) ~> REST => 
            
            declareArgs(Ps, As) ~> 
            BODY ~> return ; 
        </k>
        <env> ENV => .Map </env>
        <funs> ... FUN |-> (_TYPE FUN ( Ps ) BODY) ... </funs>
        <stack> .List => ListItem( StackItem(REST, ENV) ) ... </stack>    
    
    
    syntax KItem ::= evalArgList(Args)
    syntax KItem ::= evalArgTail(Args) 
    syntax KItem ::= evalArgHead(Value)

    rule <k> evalArgList(.Args) => .Values ... </k>
    rule <k> evalArgList(A , As) => A ~> evalArgTail(As) ... </k>
    rule <k> V:Value ~> evalArgTail(As) => evalArgList(As) ~> evalArgHead(V) ... </k>
    rule <k> Vs:Values ~> evalArgHead(V:Value) => (V, Vs):Values ... </k>

```
Declare parameters as local variables and assign arguments as initial values.
```k
    syntax Stmts ::= declareArgs(Params, Values)  [function]
    rule declareArgs((T X, Ps), (A, As)) => T X=A; declareArgs(Ps,As)
    rule declareArgs(.Params,.Values) => .Stmts
```
### Input/Output

```k
    
    rule <k> printInt(I:Int) => writeln(Int2String(I)) ~> nothing ... </k>
    rule <k> printDouble(D:Float) => writeln(formatDouble(D)) ~> nothing ... </k>
    rule <k> printString(S:String) => writeln(S) ~> nothing ... </k>
    
    
    rule <k> readInt() => getStdinInt() ... </k>
    rule <k> readDouble() => getStdinFloat() ... </k>
    
```

## Statements

### Structural

```k
    rule <k> ; => . ... </k>
    
    rule <k> { Ss } => withBlock(Ss) ... </k>

    rule <k> S:Stmt Ss:Stmts => S ~> Ss ... </k> [structural]
    rule <k> .Stmts => . ... </k> [structural]
```

Rules for saving and restoring environments when entering and leaving blocks.
```k
    syntax KItem ::= envReminder(Map)
                   | withBlock(K)
    
    rule <k> envReminder(ENV) => . ... </k>
         <env> _ => ENV </env>

    rule <k> withBlock(S) => S ~> envReminder(ENV) ... </k>
         <env> ENV </env>
```

### Variable Declaration

Reserve a location in `store` for the variable, and put the initial value on top of the `k` cell for evaluation.
```k
    rule 
        <k> _:Type Var:Id = E:Exp ; => E ~> storeAt(Var) ... </k>
        
    syntax KItem ::= storeAt(Id)
    rule 
        <k> Val:Value ~> storeAt(Var) => . ... </k>
        <store> S => S[ I <- Val ] </store>
        <next-loc> I => I+Int 1 </next-loc>
        <env> ENV => ENV[Var <- I] </env>
    
    rule <k> (T:Type V:Id ;):Stmt => T V = defaultValue(T) ; ... </k> [structural]
        
    rule 
        <k> 
            T:Type V:DeclItem , V2 , Vs:DeclItems ; 
                =>  
            T V; ~> T V2 , Vs ; ... 
        </k>         [structural]
    
    syntax Value ::= defaultValue(Type) [function]
    rule defaultValue(int) => 0
    rule defaultValue(double) => 0.0
    rule defaultValue(boolean) => false
```

### Assignment


```k
    rule <k> X = Val; => locate(X) ~> storeValue(Val) ... </k>
        
    syntax KItem ::= storeValue(Value)
    rule 
        <k> I:Int ~> storeValue(Val) => . ... </k>
        <store> S => S[ I <- Val ] </store>

    syntax KItem ::= locate(Exp)
    rule 
        <k> locate(X:Id) => L ...</k>
        <env> ... X |-> L ... </env>
```

### Control flow

```k
    rule <k> if(true:Value)  T else _ => withBlock(T) ... </k>
    rule <k> if(false) _ else F => withBlock(F) ... </k>

    syntax KItem ::= freezeWhile(Exp, Stmt)
    rule <k> while(E) S => E ~> freezeWhile(E,S) ... </k>
    rule <k> true  ~> freezeWhile(E,S) => withBlock(S) ~> while(E) S ... </k>
    rule <k> false ~> freezeWhile(_,_) => .               ... </k>


```

### Return

```k
    rule 
        <k> return V ; ~> _ => V ~> Rest </k>
        <stack> ListItem( StackItem(Rest, ENV) ) => .List ... </stack>
        <env> _ => ENV </env>

    rule 
        <k> return ; => return nothing ; ... </k> [structural]
    
```

### Expression statement

```k
    rule <k> _:Value ; => . ... </k>
```

###



```k

endmodule

```