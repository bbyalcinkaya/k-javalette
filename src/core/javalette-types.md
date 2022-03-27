
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

    syntax KItem ::= Typecheck(Program)
                   | "#typechecking"
    rule 
        <progress> Typecheck(Prg) => #typechecking ... </progress>
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
    syntax Bool ::= validDataType(Type) [function,functional]
    rule validDataType(int) => true
    rule validDataType(double) => true
    rule validDataType(boolean) => true
    rule validDataType(void) => false
```


## Functions

Initialize the environment (`tenv`) with parameters and check the function body.
```k
    rule 
        <tcode> T _ ( Ps ) { Ss } => twithBlock(checkStmts(Ss)) ... </tcode>
        <tenv> _ => paramMap(Ps) </tenv>
        <tenv-block> _ => .Set </tenv-block>
        <retType> _ => T </retType>
        requires validParams(Ps)
    
    syntax Bool ::= validParams( Params ) [function,functional]
                  | validParamsH( Params, Map ) [function,functional]
    rule validParams(Ps) => validParamsH(Ps, .Map)
    rule validParamsH(.Params, _) => true 
    rule validParamsH((T V, Ps), M) => 
        validDataType(T) andBool 
        notBool(V in_keys(M)) andBool
        validParamsH(Ps, M[V <- T])
    
    syntax Map ::= paramMap(Params) [function, functional]
                 | paramMapH(Params, Map) [function, functional]
    rule paramMap(Ps) => paramMapH(Ps, .Map) 
    rule paramMapH( .Params , Acc ) => Acc 
    rule paramMapH( (T:Type V:Id , Ps:Params) , Acc:Map ) 
            => paramMapH(Ps, Acc[V <- T]) 

```

## Statements
```k
    syntax KItem ::= checkStmt(Stmt)

    rule <tcode> checkStmt( ; ) => . ... </tcode>
```
### Block

A block (`{...}`) introduces a new scope to the environment.
```k             
    rule <tcode> checkStmt( { Ss } ) => twithBlock(checkStmts(Ss)) ... </tcode>
    
    syntax KItem ::= checkStmts( Stmts )
    rule <tcode> checkStmts( .Stmts ) => . ... </tcode>
    rule <tcode> checkStmts( S:Stmt Ss:Stmts ) => checkStmt(S) ~> checkStmts(Ss) ... </tcode>
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
        <tcode> checkStmt( T:Type V:Id ; ) => . ... </tcode>
        <tenv> ENV => ENV[V <- T] </tenv>
        <tenv-block> BLK => SetItem(V) BLK </tenv-block>
        requires notBool(V in BLK)
                andBool validDataType(T)
```
When an initial value is provided, type of the expression must match the variable's type.
```k
    rule 
        <tcode> checkStmt( T:Type V:Id = E:Exp ; ) => checkStmt( T:Type V:Id; ) ... </tcode>
        requires checkExp(T, E)
    
    rule <tcode>
        checkStmt(T:Type V:DeclItem , V2 , Vs:DeclItems ; ) 
                =>  
        checkStmt(T V;) ~> checkStmt( T V2 , Vs ; ) ... 
    </tcode>
```

### Assignment

```k
    rule 
        <tcode> checkStmt( V = E ; ) => . ... </tcode>
        requires checkExp( inferExp(V) , E) 
                andBool isLValue( V )
    
    // Do not use [owise] rules
    syntax Bool ::= isLValue(Exp) [function,functional]
    rule isLValue(_:Id) => true         // variable
    rule isLValue(_:Bool) => false
    rule isLValue(_:Int) => false
    rule isLValue(_:Float) => false
    rule isLValue(readInt()) => false
    rule isLValue(readDouble()) => false
    rule isLValue(printInt(_)) => false
    rule isLValue(printString(_)) => false
    rule isLValue(printDouble(_)) => false
    rule isLValue(_:Id (_)) => false
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

### Return

The expression's type must match the return type. Empty return is only allowed in `void` functions.

```k
    rule 
        <tcode> checkStmt( return ; ) => . ... </tcode>
        <retType> void </retType>

    rule 
        <tcode> checkStmt( return E:Exp ; ) => . ... </tcode>
        <retType> T </retType>
        requires checkExp(T, E)
```

### Control flow

Conditions must be `boolean` expressions. 

```k
    rule 
        <tcode> checkStmt( if( E:Exp ) ST:Stmt else SF:Stmt  ) 
                => 
            twithBlock(checkStmt(ST)) ~>
            twithBlock(checkStmt(SF)) ... 
        </tcode>
        requires checkExp(boolean, E)
        
    rule 
        <tcode> checkStmt( while( E:Exp ) ST:Stmt ) 
                => 
            twithBlock(checkStmt(ST)) ... 
        </tcode>
        requires checkExp(boolean, E)
```

### Expression statement

The expression must be a `void` expression.

```k
    rule <tcode> checkStmt(E:Exp ;) => . ... </tcode> requires checkExp(void, E)
```
## Expressions

Inferred type must match the expected type.
```k
    syntax Bool ::= equalType(InferRes, InferRes) [function, functional]
    rule equalType(T1:Type, T2:Type)       => true requires T1 ==K T2
    rule equalType(_:Type, #typeError)     => false
    rule equalType(#typeError, _:Type)     => false
    rule equalType(#typeError, #typeError) => false
    
    syntax Bool ::= checkExp(InferRes, Exp) [function, functional]
    rule checkExp( T:Type, E ) => equalType(T, inferExp(E))
    rule checkExp( #typeError, _ ) => false
    
    syntax InferRes ::= Type | "#typeError"
    syntax InferRes ::= inferExp(Exp) [function, functional]
    
    rule inferExp(_) => #typeError [owise]
```

### Literals
```k
    rule inferExp(_:Int)           => int 
    rule inferExp(true)            => boolean 
    rule inferExp(false)           => boolean 
    rule inferExp(_:Float)         => double
```

### Variable
Lookup the variable's name in the environment.
```k
    rule [[inferExp(V:Id) => T ]]
        <tenv> ... V |-> T ... </tenv> 
```

### Builtin I/O

```k
    rule inferExp(printInt(E:Exp))       => void requires checkExp(int, E)
    rule inferExp(printDouble(E:Exp))    => void requires checkExp(double, E)
    rule inferExp(printString(_:String)) => void
    rule inferExp(readInt())             => int
    rule inferExp(readDouble())          => double
```

### Function call

```k
    rule [[ inferExp(Fun:Id  ( As:Args ) )  => T ]]
        <funs> ... Fun |-> (T:Type _ ( Ps:Params ) _ ) ... </funs> requires checkArgs(As, Ps)
    
    syntax Bool ::= checkArgs(Args, Params) [function, functional]
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
    
    syntax InferRes ::= inferArith(InferRes, Exp) [function, functional]
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
    
    syntax InferRes ::= inferEq(InferRes, Exp) [function, functional]
    rule inferEq(T:Type, Other:Exp) => boolean requires isEquality(T)
                                                andBool checkExp(T, Other)
    rule inferEq(#typeError, _) => #typeError

    rule inferExp( E1:Exp >= E2:Exp ) => inferOrd(inferExp(E1), E2)
    rule inferExp( E1:Exp >  E2:Exp ) => inferOrd(inferExp(E1), E2)
    rule inferExp( E1:Exp <= E2:Exp ) => inferOrd(inferExp(E1), E2)
    rule inferExp( E1:Exp <  E2:Exp ) => inferOrd(inferExp(E1), E2)
    
    syntax InferRes ::= inferOrd(InferRes, Exp) [function, functional]
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
    syntax InferRes ::= mustBeNumeric(InferRes) [function, functional]
    rule mustBeNumeric(T:Type) => T requires isNumeric(T)
    rule mustBeNumeric(#typeError) => #typeError

    syntax Bool ::= isNumeric(InferRes) [function, functional]
    rule isNumeric(int)    => true
    rule isNumeric(double) => true
    rule isNumeric(_) => false      [owise]

    syntax Bool ::= isEquality(InferRes) [function, functional]
    rule isEquality(int)     => true
    rule isEquality(double)  => true
    rule isEquality(boolean) => true
    rule isEquality(void)    => false
    rule isEquality(#typeError) => false
    
endmodule
```