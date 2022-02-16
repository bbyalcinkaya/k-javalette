requires "javalette-syntax.k"

module JAVALETTE-CONFIGURATION 
    imports JAVALETTE-SYNTAX
    imports DOMAINS

    configuration
        <k> $PGM:Program ~> execute_main </k>
        <funs>  .Map  </funs>
        <exec>
            <mem> .Map </mem>
            <stack> .List </stack>
            // <input  stream="stdin" > .List </input>
            // <output stream="stdout"> .List </output>
        </exec>
        <typecheck>
            <retType> void </retType>
            <tenv> .List </tenv>
        </typecheck>
        <status-code exit=""> 1 </status-code>
        <flag-run multiplicity="?" > $RUN:Int </flag-run>

    syntax KItem ::= "execute_main"
        rule 
            <k> execute_main ~> _ => . </k>
            <flag-run> 0 </flag-run>
            <status-code> _ => 0 </status-code>
        rule 
            <k> execute_main ~> _ => main(.Args) </k> [owise]

    syntax KItem ::= "pushTBlock"
    syntax KItem ::= "popTBlock"
    
    rule <k> pushTBlock => . ... </k>
         <tenv> ENV => ListItem(.Map) ENV </tenv>
    rule <k> popTBlock => . ... </k>
         <tenv> ListItem(_) ENV => ENV </tenv>
    rule <k> popTBlock => . ... </k>
         <tenv> .List </tenv>

endmodule