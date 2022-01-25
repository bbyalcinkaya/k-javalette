requires "javalette-syntax.k"

module JAVALETTE
    imports JAVALETTE-SYNTAX 
    imports INT
    imports BOOL
    imports MAP 
    imports LIST 
    imports STRING 

    configuration
        <k> $PGM:Program ~> execute_main </k>
        <mem> .Map </mem>
        <funs>  .Map  </funs>
        <stack> .List </stack>
        <input  stream="stdin" > .List </input>
        <output stream="stdout"> .List </output>

    syntax KItem ::= "execute_main"
    rule <k> execute_main => main(.Args) </k>

    syntax KItem ::= stackFrame(rest: K, memory: Map)

    /// Scan Function Definitions
    // consume all top level definitions
    rule <k> Td:TopDef Program => Td ~> Program ... </k>
    rule <k> .Program => . ... </k>
    // store functions in 'funs'
    rule <k> T:Type I:Id ( Ps:Params ) Body:Block => . ... </k>
         <funs> FUNS => FUNS[I <- (T I ( Ps ) Body) ] </funs> requires notBool(I in_keys(FUNS))



    ///-----------------------------------------------
    /// Expression Evaluation
    
    // Unary
    rule <k> - I => 0 -Int I ... </k>
    rule <k> ! 0 => 1 ... </k>
    rule <k> ! _ => 1 ... </k> [owise]
    
    // Binary Arithmetic
    rule <k> I1 + I2 => I1 +Int I2 ... </k>
    rule <k> I1 - I2 => I1 -Int I2 ... </k>
    rule <k> I1 * I2 => I1 *Int I2 ... </k>
    rule <k> I1 / I2 => I1 /Int I2 ... </k>
    rule <k> I1 % I2 => I1 %Int I2 ... </k>

    // Comparison
    syntax Int ::= boolToInt(Bool) [function]
    rule boolToInt(true) => 1
    rule boolToInt(false) => 0

    rule <k> I1 >  I2 => boolToInt(I1 >Int  I2) ... </k>
    rule <k> I1 >= I2 => boolToInt(I1 >=Int I2) ... </k>
    rule <k> I1 <  I2 => boolToInt(I1 <Int  I2) ... </k>
    rule <k> I1 <= I2 => boolToInt(I1 <=Int I2) ... </k>
    rule <k> I1 == I2 => boolToInt(I1 ==Int I2) ... </k>
    rule <k> I1 != I2 => boolToInt(I1 =/=Int I2) ... </k>

    // Logic
    rule <k> 0 && _ => 0 ... </k>
    rule <k> _ && E => E ... </k> [owise]
    
    rule <k> 0 || E => E ... </k> 
    rule <k> 1 || _ => 1 ... </k> [owise]

    // Variable lookup
    rule <k> I:Id => MEM[I] ... </k>
         <mem> MEM </mem>               requires I in_keys(MEM)

    // Function call
    
    rule <k> FUN:Id ( As ) ~> Rest => mkArgVars(Ps, As) BODY return 0;</k> // TODO change return after adding other types
         <mem> MEM => .Map </mem>
         <funs> ... FUN |-> (_TYPE FUN ( Ps ) BODY) ... </funs>
         <stack> .List => ListItem(stackFrame(Rest, MEM)) ... </stack>

    syntax Stmt ::= mkArgVars(Params, Args)  [function]
    rule mkArgVars((T:Type X:Id, Ps:Params), (V:Exp, Vs:Args)) => T X=V; mkArgVars(Ps,Vs)
    rule mkArgVars(.Params,.Args) => ;
    
    // Input/Output
    rule <k> readInt() => I ... </k>
         <input> ListItem(I:Int) => .List ... </input>
    
    rule <k> printInt(I:Int) => 0 ... </k>
         <output> ... .List => ListItem(I) ListItem("\n") </output>
    
    
    
    ///------------------------------------------------------
    /// Statements
    rule <k> _:Int ; => . ... </k>
    rule <k> S1:Stmt S2:Stmt => S1 ~> S2 ... </k>
    rule <k> { Ss } => Ss ... </k> // TODO ctx
    rule <k> {    } => .  ... </k> // TODO ctx
    
    rule <k> ; => . ... </k> // TODO

    // rule <k> _:Type .DeclItems ; => . ...</k>
    // rule <k> T:Type DI1, DI2, Rest ; => T DI1 ; T DI2, Rest ; ...</k>
    rule <k> _:Type Var = E:Int ; => . ... </k> // TODO
          <mem> MEM => MEM [ Var <- E ] </mem> when notBool(Var in_keys(MEM))
    // rule <k> _:Type Var ; => . ... </k> // TODO
    //       <mem> MEM => MEM [ Var <- 0 ] </mem> when notBool(Var in_keys(MEM))
    
     // Assignment
     rule <k> Var = X:Int ; => . ... </k>
          <mem> MEM => MEM [ Var <- X  ] </mem> when Var in_keys(MEM)

     rule <k> I ++ ; => I = I + 1 ; ... </k>
     rule <k> I -- ; => I = I - 1 ; ... </k>

    // Control flow
    // If Else
    rule <k> if (0)  _THEN else  ELSE => ELSE ... </k>
    rule <k> if (_)   THEN else _ELSE => THEN ... </k> [owise]
    // If
    rule <k> if ( E ) S:Block => if (E) S else { } ... </k>

    // While
    rule <k> while ( E ) S:Block => if (E) { S while(E) S } ... </k>

    // Return
    // early return
    rule <k> return V:Int ; ~> _ => V ~> Rest </k>
        <stack> ListItem(stackFrame(Rest, MEM)) => .List ... </stack>
        <mem> _ => MEM </mem>
        
        

endmodule

