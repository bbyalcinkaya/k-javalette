
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
    imports JAVALETTE-ENV
    imports JAVALETTE-IO

    configuration
        <exec>
            // <code> .K </code>
            <env> .List </env>
            <stack> .List </stack>
            <store> .Map </store>
            <next-loc> 0 </next-loc>
            <flag-run > $RUN:Int </flag-run>
        </exec>
        //<output stream="stdout"> .List </output>
        



    syntax KItem ::= Execute( )
                   | "#executing"
                   | "#executedone" "(" Value ")"

    rule 
        <progress>  Execute( ) => #executing ... </progress>
        <k>     . => main(.Args) ... </k>
        <env>   _ => .List </env>
        <stack> _ => .List </stack>
        <store> _ => .Map </store>
        <flag-run> 1 </flag-run>
    
    rule 
        <progress>  Execute( ) => #executedone(0) ... </progress>
        <flag-run> 0 </flag-run>

    rule 
        <progress> #executing => #executedone(V) ... </progress>
        <k> V:Value ~> . => . </k>
        <env>   _ => .List </env>
        <stack> _ => .List </stack>
        <store> _ => .Map </store>
        <funs>  _ => .Map </funs>


    
    syntax KResult ::= Value
                     | Values // TODO is this necessary
    syntax Value ::= Int
                   | Float 
                   | Bool  
                   | "nothing"
                   
    syntax Values ::= List{Value, ","}// TODO is Values necessary
    syntax Exp ::= Value // TODO test this

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
In `a && b` and `a || b`, if `a` evaluates to `false`, `b` is not evaluated. 
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
        <env> ENV </env>
        <store> ... (envLookup(ENV, X) |-> V) ...</store>

    
```

### Function call
```k

    syntax KItem ::= applyFun( Id )
    rule <k> FUN:Id ( As ) => evalArgList(As) ~> applyFun( FUN ) ... </k> 
    rule 
        <k> As:Values ~> applyFun(FUN:Id) ~> REST => 
            
            declareArgs(Ps, As) ~> 
            BODY ~> return ; 
        </k>
        <env> ENV => ListItem(.Map) </env>
        <funs> ... FUN |-> (_TYPE FUN ( Ps ) BODY) ... </funs>
        //<stack> STACK => STACK </stack>    
        <stack> .List => ListItem( StackItem(REST, ENV) ) ... </stack>    
    
    
    //rule <k> .Args => .Values ... </k>
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
    
    rule <k> { Ss } => pushEBlock ~> Ss ~> popEBlock ... </k>

    rule <k> S:Stmt Ss:Stmts => S ~> Ss ... </k> [structural]
    rule <k> .Stmts => . ... </k> [structural]
    
    syntax KItem ::= "pushEBlock"
    syntax KItem ::= "popEBlock"
    
    rule <k> pushEBlock => . ... </k>
         <env> ENV => ListItem(.Map) ENV </env>
    rule <k> popEBlock => . ... </k>
         <env> ListItem(_) ENV => ENV </env>
    rule <k> popEBlock => . ... </k>
         <env> .List </env>
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
        <env> ListItem(M) Rest => ListItem(M[Var <- I]) Rest </env>
    
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
        <k> locate(X:Id) => envLookup(ENV, X) ...</k>
        <env> ENV </env>
```

### Control flow

```k
    rule <k> if(true:Value)  T else _ => pushEBlock ~> T ~> popEBlock ... </k>
    rule <k> if(false) _ else F => pushEBlock ~> F ~> popEBlock  ... </k>

    syntax KItem ::= freezeWhile(Exp, Stmt)
    rule <k> while(E) S => E ~> freezeWhile(E,S) ... </k>
    rule <k> true  ~> freezeWhile(E,S) => S ~> while(E) S ... </k>
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