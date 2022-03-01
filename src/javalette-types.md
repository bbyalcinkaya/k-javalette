
```k

module JAVALETTE-TYPES [private]
    imports JAVALETTE-CONFIGURATION
    imports JAVALETTE-SYNTAX
    imports JAVALETTE-ENV

    imports LIST
    imports K-EQUAL

    rule <k> typecheck => checkFuns(keys_list(FUNS)) ... </k>
         <funs> FUNS </funs> [structural]

```

## Functions

```k

    
    syntax KItem ::= checkFuns(List)
    rule <k> checkFuns(.List) => . ... </k>                                             [structural]
    rule <k> checkFuns(ListItem(I:Id) Rest) => checkFun(I) ~> checkFuns(Rest) ... </k>  [structural]

```
Initialize the environment (`tenv`) with parameters and check the function body.
```k
    syntax KItem ::= checkFun (Id)
    rule 
        <k> checkFun(F:Id) => checkBlock(Body) ... </k>
        <funs> ... F |->  (T _ ( Ps ) Body) ... </funs>
        <typecheck>
            <tenv> _ => envMake(Ps) </tenv>
            <retType> _ => T </retType>
        </typecheck>
        requires noVoidParams(Ps)
    
    syntax Bool ::= noVoidParams( Params ) [function,functional]
    rule noVoidParams(.Params) => true
    rule noVoidParams(T _, Ps) => (T =/=K void) andBool noVoidParams(Ps)
    
```

## Statements
```k
    syntax KItem ::= checkStmt(Stmt)

    rule <k> checkStmt( ; ) => . ... </k>
```
### Block

A block (`{...}`) introduce a new scope to the environment.
```k             
    rule <k> checkStmt( B:Block ) => checkBlock(B) ... </k>
    syntax KItem ::= checkBlock( Block ) 
    rule <k> checkBlock( { Ss:Stmts } ) => pushTBlock ~> checkStmts(Ss) ~> popTBlock ... </k>
    
    syntax KItem ::= checkStmts( Stmts )
    rule <k> checkStmts( .Stmts ) => . ... </k>
    rule <k> checkStmts( S:Stmt Ss:Stmts ) => checkStmt(S) ~> checkStmts(Ss) ... </k>
```
### Variable declaration

A variable can only be declared once in a block (`envTopContains`).
A variable declared in an outer scope may be redeclared in a block;
the new declaration then shadows the previous declaration for the rest of the block.

Variables can be declared without initial values. If an initial value is given, its type must match the variable type.

```k
    rule 
        <k> checkStmt( T:Type V:Id ; ) => . ... </k>
        <tenv> ENV => envInsert(V, T, ENV) </tenv>
        requires notBool(envTopContains(ENV, V))
                andBool ( T =/=K void )
        
    rule 
        <k> checkStmt( T:Type V:Id = E:Exp ; ) => . ... </k>
        <tenv> ENV => envInsert(V, T, ENV) </tenv>
        requires notBool(envTopContains(ENV, V))
                 andBool checkExp(T, E)
    rule 
        checkStmt(T:Type V:DeclItem , V2 , Vs:DeclItems ; ) 
                =>  
        checkStmt(T V;) ~> checkStmt( T V2 , Vs ; )         [structural]
```

### Assignment

```k
    rule 
        <k> checkStmt( V:Id = E:Exp ; ) => . ... </k>
        <tenv> ENV </tenv>
        requires envContains(ENV, V) andBool
                 checkExp( typeLookup(ENV, V) , E)
```

### Return

The expression's type must match the return type. Empty return is only allowed in `void` functions.

```k
    rule 
        <k> checkStmt( return ; ) => . ... </k>
        <retType> void </retType>

    rule 
        <k> checkStmt( return E:Exp ; ) => . ... </k>
        <retType> T </retType>
        requires checkExp(T, E)
```

### Control flow

Conditions must be `boolean` expressions.

```k
    rule 
        <k> checkStmt( if( E:Exp ) ST:Stmt else SF:Stmt  ) 
                => 
            pushTBlock ~> checkStmt(ST) ~> popTBlock ~>
            pushTBlock ~> checkStmt(SF) ~> popTBlock ... 
        </k>
        requires checkExp(boolean, E)
        
    rule 
        <k> checkStmt( while( E:Exp ) ST:Stmt ) 
                => 
            pushTBlock ~> checkStmt(ST) ~> popTBlock ... 
        </k>
        requires checkExp(boolean, E)
```

### Expression statement

The expression must be a `void` expression.

```k
    rule <k> checkStmt(E:Exp ;) => . ... </k> requires checkExp(void, E)
```
## Expressions

Inferred type must match the expected type.
```k
    syntax Bool ::= checkExp(Type, Exp) [function, functional]
    rule checkExp( T:Type, E:Exp ) => T ==K inferExp(E)
    
    syntax InferRes ::= Type | "TypeError"
    syntax InferRes ::= inferExp(Exp) [function, functional]
    
    rule inferExp(_) => TypeError [owise]
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
    rule inferExp(printInt(E:Exp))       => void requires int ==K inferExp(E)
    rule inferExp(printDouble(E:Exp))    => void requires double ==K inferExp(E)
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
    rule inferArith(TypeError, _) => TypeError
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
    rule inferEq(TypeError, _) => TypeError

    rule inferExp( E1:Exp >= E2:Exp ) => inferOrd(inferExp(E1), E2)
    rule inferExp( E1:Exp >  E2:Exp ) => inferOrd(inferExp(E1), E2)
    rule inferExp( E1:Exp <= E2:Exp ) => inferOrd(inferExp(E1), E2)
    rule inferExp( E1:Exp <  E2:Exp ) => inferOrd(inferExp(E1), E2)
    
    syntax InferRes ::= inferOrd(InferRes, Exp) [function, functional]
    rule inferOrd(T:Type, Other:Exp) => boolean requires isNumeric(T)
                                                            andBool checkExp(T, Other)
    rule inferOrd(TypeError, _) => TypeError

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
    rule mustBeNumeric(TypeError) => TypeError

    syntax Bool ::= isNumeric(InferRes) [function, functional]
    rule isNumeric(int)    => true
    rule isNumeric(double) => true
    rule isNumeric(_) => false      [owise]

    syntax Bool ::= isEquality(InferRes) [function, functional]
    rule isEquality(int)     => true
    rule isEquality(double)  => true
    rule isEquality(boolean) => true
    rule isEquality(_)       => false [owise]
    

    syntax KItem ::= "pushTBlock"
    syntax KItem ::= "popTBlock"
    
    rule <k> pushTBlock => . ... </k>
         <tenv> ENV => ListItem(.Map) ENV </tenv>
    rule <k> popTBlock => . ... </k>
         <tenv> ListItem(_) ENV => ENV </tenv>
    rule <k> popTBlock => . ... </k>
         <tenv> .List </tenv>

endmodule
```