
```k
requires "javalette-syntax.md"

module JAVALETTE-CONFIGURATION 
    imports JAVALETTE-SYNTAX
    imports MAP
    imports LIST
    imports K-IO

    configuration
        <k> $PGM:Program ~> typecheck ~> returncheck ~> execute_main </k>
        <funs>  .Map  </funs>
        <exec>
            <env> .List </env>
            <stack> .List </stack>
            <store> .Map </store>
        </exec>
        <typecheck>
            <retType> void </retType>
            <tenv> .List </tenv>
        </typecheck>
        <status-code exit=""> 1 </status-code>
        <flag-run multiplicity="?" > $RUN:Int </flag-run>

        //<input  stream="stdin" > .List </input>
        <output stream="stdout"> .List </output>

        
    
    syntax KItem ::= "typecheck"
    syntax KItem ::= "returncheck"
    syntax KItem ::= "execute_main"

endmodule
```