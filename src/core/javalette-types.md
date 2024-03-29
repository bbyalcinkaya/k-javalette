
```k

module JAVALETTE-TYPES
    imports JAVALETTE-CONFIGURATION
    imports JAVALETTE-SYNTAX

    imports LIST
    imports MAP
    imports SET
    imports BOOL
    imports K-EQUAL

    configuration
        <typecheck>
            <tcode> .K </tcode>
            <retType> void </retType>
            <tenv> .Map </tenv>
            <tenv-block> .Set </tenv-block>
        </typecheck>

    syntax KItem ::= "#typecheck"
                   | "#typechecking"
    rule 
        <progress> #typecheck => #typechecking ... </progress>
        <program> Prg </program>
        <tcode> _ => Prg </tcode>
        <retType> _ => void </retType>
        <tenv> _ => .Map </tenv>
        <tenv-block> _ => .Set </tenv-block>
        <funs> ... (main |-> int main(.Params) _) ... </funs>
    
    rule 
        <progress> #typechecking => . ... </progress>
        <tcode> . </tcode>
        <retType> _ => void </retType>
        <tenv> _ => .Map </tenv>
        <tenv-block> _ => .Set </tenv-block>
        
    rule <tcode> TD:TopDef Prg:Program => TD ~> Prg ... </tcode>  [structural]
    rule <tcode> .Program => . ... </tcode>  [structural]
```
## Valid data types

```k
    syntax Bool ::= validDataType(Type) [function,total]
    rule validDataType(int) => true
    rule validDataType(double) => true
    rule validDataType(boolean) => true
    rule validDataType(void) => false
```
## Built-in functions

```k
    syntax Set ::= "builtinFuns" [function, total]
    rule builtinFuns => SetItem("readInt") SetItem("readDouble") SetItem("printInt") SetItem("printDouble") SetItem("printString")
```

## Functions

Initialize the environment (`tenv`) with parameters and check the function body.

```k
    rule 
        <tcode> T:Type FName:Id ( Ps:Params ) { Ss } => twithBlock( Ss ) ... </tcode>
        <tenv> _       => paramMap(Ps) </tenv>
        <tenv-block> _ => .Set         </tenv-block>
        <retType> _    => T            </retType>
        requires 
            notBool(FName in builtinFuns  )
            andBool validParams(Ps)
    
    syntax Bool ::= validParams( Params ) [function,total]
                  | validParamsH( Params, Map ) [function,total]
    rule validParams(Ps) => validParamsH(Ps, .Map)
    rule validParamsH(.Params, _) => true 
    rule validParamsH((T V, Ps), M) => 
        validDataType(T) andBool 
        notBool(V in_keys(M)) andBool
        validParamsH(Ps, M[V <- T])
    
    syntax Map ::= paramMap(Params) [function, total]
                 | paramMapH(Params, Map) [function, total]
    rule paramMap(Ps) => paramMapH(Ps, .Map) 
    rule paramMapH( .Params , Acc ) => Acc 
    rule paramMapH( (T:Type V:Id , Ps:Params) , Acc:Map ) 
            => paramMapH(Ps, Acc[V <- T]) 

```

## Statements

```k
    rule <tcode> ( ; ) => . ... </tcode>
```

### Block

A block (`{...}`) introduces a new scope to the environment.

```k             
    rule <tcode> { Ss } => twithBlock( Ss ) ... </tcode>
    
    rule <tcode> ( .Stmts ) => . ... </tcode>
    rule <tcode> ( S:Stmt Ss:Stmts ) => S ~> Ss ... </tcode>
```

Rules for saving and restoring environments when entering and leaving blocks.

```k
    syntax KItem ::= tenvReminder(Map, Set)
                   | twithBlock(K)
    
    rule <tcode> tenvReminder(ENV,BLK) => . ... </tcode>
         <tenv> _ => ENV </tenv>
         <tenv-block> _ => BLK </tenv-block>
         
    rule <tcode> twithBlock(S) => S ~> tenvReminder(ENV,BLK) ... </tcode>
         <tenv> ENV </tenv>
         <tenv-block> BLK => .Set </tenv-block>

```


### Variable declaration

A variable can only be declared once in a block.
A variable declared in an outer scope may be redeclared in a block;
the new declaration then shadows the previous declaration for the rest of the block.

Variables can be declared without initial values. If an initial value is given, its type must match the variable type.

```k
    rule 
        <tcode> ( T:Type V:Id ; ):Stmt => . ... </tcode>
        <tenv> ENV => ENV[V <- T] </tenv>
        <tenv-block> BLK => SetItem(V) BLK </tenv-block>
        requires notBool(V in BLK)
                andBool validDataType(T)
```

When an initial value is provided, type of the expression must match the variable's type.

```k
    rule 
        <tcode> ( T:Type V:Id = E:Exp ; ):Stmt => ( T:Type V:Id; ):Stmt ... </tcode>
        requires checkExp(T, E)
    
    rule <tcode>
        (T:Type V:DeclItem , V2 , Vs:DeclItems ; ) 
                =>  
        (T V;) ~> ( T V2 , Vs ; ) ... 
    </tcode>
```

### Assignment

```k
    rule 
        <tcode> ( V = E ; ) => . ... </tcode>
        requires checkExp( inferExp(V) , E) 
                andBool isLValue( V )
    
    // Do not use [owise] rules
    syntax Bool ::= isLValue(Exp) [function,total]
    rule isLValue(_:Id) => true         // variable
    rule isLValue(_:Bool) => false
    rule isLValue(_:Int) => false
    rule isLValue(_:Float) => false
    rule isLValue(_:String) => false
    rule isLValue(_:Id (_:Args)) => false
    rule isLValue(- _) => false
    rule isLValue(! _) => false
    rule isLValue(_ * _) => false
    rule isLValue(_ / _) => false
    rule isLValue(_ % _) => false
    rule isLValue(_ - _) => false
    rule isLValue(_ + _) => false
    rule isLValue(_ == _) => false
    rule isLValue(_ != _) => false
    rule isLValue(_ >= _) => false
    rule isLValue(_ > _) => false
    rule isLValue(_ <= _) => false
    rule isLValue(_ < _) => false
    rule isLValue(_ && _) => false
    rule isLValue(_ || _) => false
```

### Increment/Decrement

Only for expressions of type `int`
```k
    rule 
        <tcode> ( E ++ ; ) => . ... </tcode>
        requires checkExp( int , E) 
                andBool isLValue( E )
    rule 
        <tcode> ( E -- ; ) => . ... </tcode>
        requires checkExp( int , E) 
                andBool isLValue( E )
```


### Return

The expression's type must match the return type. Empty return is only allowed in `void` functions.

```k
    rule 
        <tcode> ( return ; ) => . ... </tcode>
        <retType> void </retType>

    rule 
        <tcode> ( return E:Exp ; ) => . ... </tcode>
        <retType> T </retType>
        requires checkExp(T, E)
```

### Control flow

Conditions must be `boolean` expressions. 

```k
    rule 
        <tcode> ( if( E:Exp ) ST:Stmt else SF:Stmt  ) 
                => 
            twithBlock( ST ) ~>
            twithBlock( SF ) ... 
        </tcode>
        requires checkExp(boolean, E)
        
    rule 
        <tcode> ( while( E:Exp ) ST:Stmt ) 
                => 
            twithBlock( (ST) ) ... 
        </tcode>
        requires checkExp(boolean, E)
```

### Expression statement

The expression must be a `void` expression.

```k
    rule <tcode> (E:Exp ;) => . ... </tcode> requires checkExp(void, E)
```

## Expressions

Inferred type must match the expected type.

```k
    syntax Bool ::= equalType(InferRes, InferRes) [function, total]
    rule equalType(T1:Type, T2:Type)       => true requires T1 ==K T2
    rule equalType(_, _)                   => false [owise]
    
    syntax Bool ::= checkExp(InferRes, Exp) [function, total]
    rule checkExp( T:Type, E ) => equalType(T, inferExp(E))
    rule checkExp( #typeError, _ ) => false
    
    syntax InferRes ::= Type | "#typeError"
    syntax InferRes ::= inferExp(Exp) [function, total]
    
    rule inferExp(_) => #typeError [owise]
```

### Literals

```k
    rule inferExp(_:Int)           => int 
    rule inferExp(true)            => boolean 
    rule inferExp(false)           => boolean 
    rule inferExp(_:Float)         => double
    rule inferExp(_:String)        => #typeError
```

### Variable
Lookup the variable's name in the environment.

```k
    rule [[inferExp(V:Id) => T ]]
        <tenv> ... V |-> T ... </tenv> 
```

### Builtin I/O

```k
    rule inferExp(printInt(E:Exp , .Args))      => void requires checkExp(int, E)
    rule inferExp(printDouble(E:Exp, .Args))    => void requires checkExp(double, E)
    rule inferExp(printString(_:String, .Args)) => void
    rule inferExp(readInt(.Args))               => int
    rule inferExp(readDouble(.Args))            => double
```

### Function call

```k
    rule [[ inferExp(Fun:Id  ( As:Args ) )  => T ]]
        <funs> ... Fun |-> (T:Type _:Id ( Ps:Params ) _ ) ... </funs> requires checkArgs(As, Ps)
    
    syntax Bool ::= checkArgs(Args, Params) [function, total]
    rule checkArgs(.Args, .Params)       => true 
    rule checkArgs((A, As), ((T _), Ps)) => checkArgs(As, Ps) requires checkExp(T, A) 
    // OTHERWISE : type mismatch or invalid number of args
    rule checkArgs(_, _)                 => false [owise] 

```       

### Arithmetic operations

Any numeric value can be negated using `-`.

```k     
    rule inferExp( - E:Exp) => mustBeNumeric(inferExp(E))
```

Operands must be of the same numeric type.

```k    
    rule inferExp( E1:Exp + E2:Exp ) => inferArith(inferExp(E1), E2)
    rule inferExp( E1:Exp - E2:Exp ) => inferArith(inferExp(E1), E2)
    rule inferExp( E1:Exp / E2:Exp ) => inferArith(inferExp(E1), E2)
    rule inferExp( E1:Exp * E2:Exp ) => inferArith(inferExp(E1), E2)
    
    syntax InferRes ::= inferArith(InferRes, Exp) [function, total]
    rule inferArith(T:Type, E2:Exp) => T requires isNumeric(T) andBool checkExp(T, E2)
    rule inferArith(#typeError, _) => #typeError
```

```k
    rule inferExp( E1:Exp % E2:Exp ) => int requires checkExp(int, E1) andBool checkExp(int, E2)
```

### Comparison operations


```k
    rule inferExp( E1:Exp == E2:Exp ) => inferEq(inferExp(E1), E2)
    rule inferExp( E1:Exp != E2:Exp ) => inferEq(inferExp(E1), E2)
    
    syntax InferRes ::= inferEq(InferRes, Exp) [function, total]
    rule inferEq(T:Type, Other:Exp) => boolean requires isEquality(T)
                                                andBool checkExp(T, Other)
    rule inferEq(#typeError, _) => #typeError

    rule inferExp( E1:Exp >= E2:Exp ) => inferOrd(inferExp(E1), E2)
    rule inferExp( E1:Exp >  E2:Exp ) => inferOrd(inferExp(E1), E2)
    rule inferExp( E1:Exp <= E2:Exp ) => inferOrd(inferExp(E1), E2)
    rule inferExp( E1:Exp <  E2:Exp ) => inferOrd(inferExp(E1), E2)
    
    syntax InferRes ::= inferOrd(InferRes, Exp) [function, total]
    rule inferOrd(T:Type, Other:Exp) => boolean requires isNumeric(T)
                                                            andBool checkExp(T, Other)
    rule inferOrd(#typeError, _) => #typeError

```

### Logical operations

```k
    rule inferExp( E1:Exp && E2:Exp ) => boolean requires checkExp(boolean, E1)
                                                            andBool checkExp(boolean, E2)
    rule inferExp( E1:Exp || E2:Exp ) => boolean requires checkExp(boolean, E1)
                                                            andBool checkExp(boolean, E2)
    rule inferExp( ! E:Exp) => boolean requires checkExp(boolean, E)
```

### Helper functions

```k 
    syntax InferRes ::= mustBeNumeric(InferRes) [function, total]
    rule mustBeNumeric(T:Type) => T requires isNumeric(T)
    rule mustBeNumeric(#typeError) => #typeError

    syntax Bool ::= isNumeric(InferRes) [function, total]
    rule isNumeric(int)    => true
    rule isNumeric(double) => true
    rule isNumeric(_) => false      [owise]

    syntax Bool ::= isEquality(InferRes) [function, total]
    rule isEquality(int)     => true
    rule isEquality(double)  => true
    rule isEquality(boolean) => true
    rule isEquality(void)    => false
    rule isEquality(#typeError) => false
    
endmodule
```
