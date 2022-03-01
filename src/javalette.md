# Javalette


```k
requires "javalette-syntax.md"
requires "javalette-env.md"
requires "javalette-configuration.md"
requires "javalette-execution.md"
requires "javalette-types.md"
requires "javalette-returncheck.md"

// TODO return checker. see TODO.md

module JAVALETTE
    imports JAVALETTE-SYNTAX
    imports JAVALETTE-CONFIGURATION
    imports JAVALETTE-ENV
    imports JAVALETTE-TYPES
    imports JAVALETTE-RETURNCHECK
    imports JAVALETTE-EXECUTION


```

The names of the functions must be unique. There is no overloading.
There must be a `int main()` function. 

Functions can be mutually recursive and declaration order does not matter. (`<funs>` is a `Map`)

```k
    rule 
        <k> 
            T:Type I:Id ( Ps:Params ) Body:Block Prg:Program
                => 
            Prg ... 
        </k>
        <funs> FUNS => FUNS[I <- (T I ( Ps ) Body) ] </funs> 
        requires notBool(I in_keys(FUNS))
        
    rule <k> .Program => . ... </k>
         <funs> ... (main |-> int main ( .Params ) _) ... </funs>

endmodule
```
