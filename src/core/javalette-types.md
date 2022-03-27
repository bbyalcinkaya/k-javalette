
```k

module JAVALETTE-TYPES
    imports JAVALETTE-CONFIGURATION
    imports JAVALETTE-SYNTAX
    imports JAVALETTE-ENV

    imports LIST
    imports K-EQUAL

    configuration
        <typecheck>
            <tcode> .K </tcode>
            <retType> void </retType>
            <tenv> .List </tenv>
        </typecheck>

    syntax KItem ::= Typecheck(Program)
                   | "#typechecking"
    rule 
        <progress> Typecheck(Prg) => #typechecking ... </progress>
        <tcode> _ => Prg </tcode>
        <retType> _ => void </retType>
        <tenv> _ => .List </tenv>
        <funs> ... (main |-> int main(.Params) _) ... </funs>
    
    rule 
        <progress> #typechecking => . ... </progress>
        <tcode> . </tcode>
        <retType> _ => void </retType>
        <tenv> _ => .List </tenv>
    

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
        <tcode> T _ ( Ps ) Body => checkBlock(Body) ... </tcode>
        <tenv> _ => envMake(Ps) </tenv>
        <retType> _ => T </retType>
        requires validParamTypes(Ps)
    
    syntax Bool ::= validParamTypes( Params ) [function,functional]
    rule validParamTypes(.Params) => true
    rule validParamTypes(T _, Ps) => 
        validDataType(T) andBool validParamTypes(Ps)
    
```

## Statements
```k
    syntax KItem ::= checkStmt(Stmt)

    rule <tcode> checkStmt( ; ) => . ... </tcode>
```
### Block

A block (`{...}`) introduces a new scope to the environment.
```k             
    rule <tcode> checkStmt( B:Block ) => checkBlock(B) ... </tcode>
    syntax KItem ::= checkBlock( Block ) 
    rule <tcode> checkBlock( { Ss:Stmts } ) => pushTBlock ~> checkStmts(Ss) ~> popTBlock ... </tcode>
    
    syntax KItem ::= checkStmts( Stmts )
    rule <tcode> checkStmts( .Stmts ) => . ... </tcode>
    rule <tcode> checkStmts( S:Stmt Ss:Stmts ) => checkStmt(S) ~> checkStmts(Ss) ... </tcode>
```
### Variable declaration

A variable can only be declared once in a block (`envTopContains`).
A variable declared in an outer scope may be redeclared in a block;
the new declaration then shadows the previous declaration for the rest of the block.

Variables can be declared without initial values. If an initial value is given, its type must match the variable type.

```k
    rule 
        <tcode> checkStmt( T:Type V:Id ; ) => . ... </tcode>
        <tenv> ENV => envInsert(V, T, ENV) </tenv>
        requires notBool(envTopContains(ENV, V))
                andBool validDataType(T)
        
    rule 
        <tcode> checkStmt( T:Type V:Id = E:Exp ; ) => . ... </tcode>
        <tenv> ENV => envInsert(V, T, ENV) </tenv>
        requires notBool(envTopContains(ENV, V))
                 andBool checkExp(T, E)
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
            pushTBlock ~> checkStmt(ST) ~> popTBlock ~>
            pushTBlock ~> checkStmt(SF) ~> popTBlock ... 
        </tcode>
        requires checkExp(boolean, E)
        
    rule 
        <tcode> checkStmt( while( E:Exp ) ST:Stmt ) 
                => 
            pushTBlock ~> checkStmt(ST) ~> popTBlock ... 
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
    rule [[inferExp(V:Id) => typeLookup(ENV,V)]]
        <tenv> ENV </tenv> 
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
    

    syntax KItem ::= "pushTBlock"
    syntax KItem ::= "popTBlock"
    
    rule <tcode> pushTBlock => . ... </tcode>
         <tenv> ENV => ListItem(.Map) ENV </tenv>
    rule <tcode> popTBlock => . ... </tcode>
         <tenv> ListItem(_) ENV => ENV </tenv>
    rule <tcode> popTBlock => . ... </tcode>
         <tenv> .List </tenv>

endmodule
```