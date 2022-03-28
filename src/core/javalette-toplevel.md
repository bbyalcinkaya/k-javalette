

The names of the functions must be unique. There is no overloading.
There must be a `int main()` function. 

Functions can be mutually recursive and declaration order does not matter. (`<funs>` is a `Map`)



```k



module JAVALETTE-TOPLEVEL
    imports JAVALETTE-CONFIGURATION
    imports JAVALETTE-SYNTAX

    imports BOOL
    
    syntax KItem ::= "#processTopDefs"
                   | processTopDef(TopDef)
                   | "#processingTopDefs" "(" Program ")"
    
    rule <progress> #processTopDefs => #processingTopDefs(Prg) ... </progress>
         <program> Prg </program>
         
                   
    rule <progress> #processingTopDefs(.Program) => . ... </progress>                                           [structural]
    rule <progress> #processingTopDefs(TD Rest) => processTopDef(TD) ~> #processingTopDefs(Rest) ... </progress>    [structural]
    
    rule 
        <progress> processTopDef(T I (Ps) Body) => . ... </progress>
        <funs> FUNS => FUNS[I <- (T I (Ps) Body)] </funs>
        requires notBool(I in_keys(FUNS))

endmodule


```
