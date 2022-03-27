

The names of the functions must be unique. There is no overloading.
There must be a `int main()` function. 

Functions can be mutually recursive and declaration order does not matter. (`<funs>` is a `Map`)



```k



module JAVALETTE-TOPLEVEL
    imports JAVALETTE-CONFIGURATION
    imports JAVALETTE-SYNTAX
    imports JAVALETTE-ENV



    syntax KItem ::= Toplevels(Program)
                   | "#processingTopdefs"
    
    rule 
        <progress> Toplevels(Prg) => #processingTopdefs ... </progress>
        <k> . => processTopDefs(Prg) </k>
    rule 
        <progress> #processingTopdefs => . ... </progress>
        <k> . </k>

    syntax KItem ::= processTopDef(TopDef)
                   | processTopDefs(Program)
                   
    rule <k> processTopDefs(.Program) => . ... </k>
    rule <k> processTopDefs(TD Rest) => processTopDef(TD) ~> processTopDefs(Rest) ... </k> 
    
    rule 
        <k> processTopDef(T I (Ps) Body) => . ... </k>
        <funs> FUNS => FUNS[I <- (T I (Ps) Body)] </funs>
        requires notBool(I in_keys(FUNS))


endmodule


```
