# Javalette


```k
requires "core/javalette-syntax.md"
requires "core/javalette-env.md"
requires "core/javalette-configuration.md"
requires "core/javalette-execution.md"
requires "core/javalette-types.md"
requires "core/javalette-returncheck.md"
requires "extensions/arrays.md"

// TODO return checker. see TODO.md

module JAVALETTE
    imports JAVALETTE-SYNTAX
    imports JAVALETTE-CONFIGURATION
    imports JAVALETTE-ENV
    imports JAVALETTE-TYPES
    imports JAVALETTE-RETURNCHECK
    imports JAVALETTE-EXECUTION

    imports JAVALETTE-ARRAYS

    syntax KItem ::= "set_code"

    configuration
        <jl>
            <common/>
            <status-code exit=""> 1 </status-code>
            <typecheck/>
            <exec/>
        </jl>
    rule 
        <k> Prg:Program => . ... </k>
        <funs> _ => makeFuns(.Map, Prg) </funs>
        <progress> . =>
            Typecheck(Prg) ~>
            Retcheck(Prg) ~>
            Execute( ) ~> 
            set_code
        </progress>
        
    rule 
        <progress> #executedone( I:Int ) ~> set_code => . ... </progress>
        <status-code> _ => I </status-code> 

    
```

The names of the functions must be unique. There is no overloading.
There must be a `int main()` function. 

Functions can be mutually recursive and declaration order does not matter. (`<funs>` is a `Map`)

```k
    syntax Map ::= makeFuns(Map, Program) [function]
    rule makeFuns(Acc , FD:FunDef Rest:Program) => makeFuns(addFD(Acc, FD), Rest)
    rule makeFuns(Acc , .Program) => Acc 
    
    syntax Map ::= addFD(Map, FunDef) [function]
    rule addFD(FUNS, T I (Ps) Body) => FUNS[I <- (T I ( Ps ) Body) ]
        requires notBool(I in_keys(FUNS))
         
    
```

```k


```



```k
endmodule

```