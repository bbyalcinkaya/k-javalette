
```k
requires "javalette-syntax-core.md"

module JAVALETTE-CONFIGURATION 
    imports JAVALETTE-SYNTAX-CORE
    imports MAP
    imports LIST
    imports K-IO

    configuration
        <common>
            <k> $PGM:Program </k>
            <progress> .K </progress>
            <funs> .Map </funs>
        </common>


endmodule
```