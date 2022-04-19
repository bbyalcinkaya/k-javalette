# Javalette


```k
requires "javalette-syntax.md"
requires "core/javalette-configuration.md"
requires "core/javalette-execution.md"
requires "core/javalette-types.md"
requires "core/javalette-returncheck.md"
requires "core/javalette-toplevel.md"
requires "extensions/arrays.md"


module JAVALETTE
    imports JAVALETTE-SYNTAX
    imports JAVALETTE-CONFIGURATION
    imports JAVALETTE-TYPES
    imports JAVALETTE-RETURNCHECK
    imports JAVALETTE-EXECUTION
    imports JAVALETTE-TOPLEVEL

    imports JAVALETTE-ARRAYS
    imports JAVALETTE-STRUCTS

    syntax KItem ::= "#set_code"
                   | "#done"

    configuration
        <jl>
            <common/>
            <status-code exit=""> 1 </status-code>
            <typecheck/>
            <exec/>
            <structs/>
            
        </jl>
    rule 
        <progress> . =>
            #processTopDefs ~>
            #typecheck ~>
            #returncheck ~>
            #execute ~> 
            #set_code
        </progress>
        
    rule 
        <progress> #executedone( I:Int ) ~> #set_code => #done ... </progress>
        <status-code> _ => I </status-code> 

    
```





```k
endmodule

```