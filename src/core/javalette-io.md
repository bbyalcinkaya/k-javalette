
```k

module JAVALETTE-IO

    imports K-IO
    imports INT
    imports FLOAT
    imports STRING
    imports BOOL
    

    syntax String ::= getStdinString( )              [function]
                    | getStdinStringS( IOString )    [function, private]
                    | getStdinStringH( IOString )    [function, private]
    
    rule getStdinString( ) => getStdinStringS( #read( #stdin , 1 ) )     [structural]
    
    rule getStdinStringS(C:String) => getStdinStringS(#read( #stdin , 1 ) ) 
        requires findChar(C, " \t\n", 0) =/=Int -1
    rule getStdinStringS(C:String) => getStdinStringH(C) 
        requires findChar(C, " \t\n", 0) ==Int -1
    

    syntax K ::= writeln(String)    [function]
    syntax K ::= writeln(String, Int)    [function]
    rule writeln(S) => #write(#stdout, S +String "\n")
    rule writeln(S, FD) => #write(FD, S +String "\n")
    
    rule getStdinStringH(C:String) => C +String getStdinStringH( #read( #stdin , 1 ) )
        requires findChar(C, " \t\n", 0) ==Int -1
    rule getStdinStringH(C:String) => ""
        requires findChar(C, " \t\n", 0) =/=Int -1
    rule getStdinStringH(#EOF) => ""
    

    syntax Int ::= getStdinInt( ) [function]
    rule getStdinInt( ) => String2Int(getStdinString( ) )

    syntax Float ::= getStdinFloat( ) [function]
    rule getStdinFloat( ) => String2Float(getStdinString( ) )

    

    syntax String ::= formatDouble(Float) [function,total]
    syntax Int ::= fDoubleL(Float) [function,total,private]
                 | fDoubleR(Float) [function,total,private]
                 | fDoubleT(Int) [function,total,private]
    rule formatDouble(D) => Int2String(fDoubleL(D)) +String "." +String Int2String(absInt(fDoubleR(D)))
    rule fDoubleL(D) => Float2Int(floorFloat(D *Float 10.0)) /Int 10
    rule fDoubleR(D) => fDoubleT(Float2Int(floorFloat(D *Float 10.0)) %Int 10)
    
    rule fDoubleT(0) => 0
    rule fDoubleT(I) => fDoubleT(I /Int 10) requires (I %Int 10) ==Int 0
                                            andBool I =/=Int 0
    rule fDoubleT(I) => I requires (I %Int 10) =/=Int 0



endmodule


```
