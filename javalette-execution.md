
```k
module JAVALETTE-EXECUTION
    imports INT
    imports FLOAT
    imports BOOL
    imports STRING
    imports K-IO

    imports JAVALETTE-CONFIGURATION
    imports JAVALETTE-SYNTAX
    imports JAVALETTE-ENV

    syntax KResult ::= Value
                     | Values
    syntax Value ::= Int
                   | Float 
                   | Bool  
                   | "nothing"

    syntax Values ::= List{Value, ","}
    syntax Exp ::= KResult

    syntax KItem ::= "set_code"

    rule 
        <k> execute_main ~> _ => . </k>
        <flag-run> 0 </flag-run>
        <status-code> _ => 0 </status-code>
    rule 
        <k> execute_main => main(.Args) ~> set_code ... </k>
        <flag-run> 1 </flag-run>

    rule 
        <k> I:Int ~> set_code => . ... </k>
        <status-code> _ => I </status-code>
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
    
    rule <k> I1:Int != I2 => I1 =/=Int I2 ... </k>
    rule <k> I1:Float != I2 => I1 =/=Float I2 ... </k>
```
### Logic operators
In `a && b` and `a || b`, if `a` evaluates to `false`, `b` is not evaluated. 
```k
    rule <k> false:Value && _ => false:Value ... </k>
    rule <k> true:Value  && E => E ... </k>
    
    rule <k> false:Value || E => E ...    </k> 
    rule <k> true:Value  || _ => true:Value ... </k>

    rule <k> ! true:Value   => false:Value </k>
    rule <k> ! false:Value  => true:Value </k>
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
    
    rule <k> printInt(I:Int) => writeln(Int2String(I)) ... </k>
    rule <k> printDouble(D:Float) => writeln(Float2String(D)) ... </k>
    rule <k> printString(S:String) => writeln(S) ... </k>
    rule <k> readInt() => 0 ... </k>
    rule <k> readDouble() => 0.0 ... </k>
    
    syntax KItem ::= writeln(String)
    rule <k> writeln(S) => 
        #write(#stdout, S) ~> 
        #write(#stdout, "\n") ~> 
        nothing ... 
    </k>
    

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

```k

    rule 
        <k> _:Type V:Id = E:Value ; => . ... </k>
        <env> ListItem(M) Rest => ListItem(M[V <- !I:Int]) Rest </env>
        <store> S => S[ !I <- E ] </store>

    rule <k> T:Type V:Id ; => T V = defaultValue(T) ; ... </k> [structural]
        
    syntax Value ::= defaultValue(Type) [function]
    rule defaultValue(int) => 0
    rule defaultValue(double) => 0.0
    rule defaultValue(boolean) => false
    

    rule 
        <k> 
            T:Type V:DeclItem , V2 , Vs:DeclItems ; 
                =>  
            T V; ~> T V2 , Vs ; ... 
        </k>         [structural]
    
```

### Assignment

```k
    rule
        <k> X = V; => . ... </k>
        <env> ENV </env>
        <store> S => S[ envLookup(ENV, X) <- V ] </store>
        
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