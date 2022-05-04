
```k
requires "../src/javalette.md"


module RANDOMIZE-SYNTAX
    imports JAVALETTE-SYNTAX
endmodule

module RANDOMIZE
    imports JAVALETTE
    imports RANDOMIZE-UTIL

    configuration
        <randomize>
            <jl/>
            <rand-seed> $SEED:Int </rand-seed>
            <rand-initialized> false:Bool </rand-initialized>
        </randomize>
    



    rule 
        <progress> . </progress>
        <rand-seed> Seed => constInt(Seed, srandInt(Seed)) </rand-seed>
        <rand-initialized> false => true </rand-initialized>
        [priority(49)]
    
    syntax Int ::= constInt(Int, K) [function]
    rule constInt(I, _) => I
        
    syntax Int ::= catch(IOInt) [function]
    rule catch(I:Int) => I

    rule <k> readInt() => #logInt(jlRandomInt()) ... </k> [priority(49)]
    rule <k> readDouble() => #logFloat(jlRandomDouble()) ... </k> [priority(49)]
    

    syntax KItem ::= #logInt(Int)
    rule <k> #logInt(I) => writeln(Int2String(I), #stderr) ~> I ... </k>
    
    syntax KItem ::= #logFloat(Float)
    rule <k> #logFloat(I) => writeln(formatDouble(I), #stderr) ~> I ... </k>
     
endmodule

module RANDOMIZE-UTIL
    imports INT
    imports FLOAT

    syntax Int ::= jlRandomInt() [function]
    rule jlRandomInt() => randInt(1000000) -Int 500000

    syntax Float ::= jlRandomDouble() [function]
    rule jlRandomDouble() => Int2Float(jlRandomInt(), 53, 11) /Float 10.0

endmodule
```