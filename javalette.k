requires "javalette-syntax.k"
requires "javalette-env.k"
requires "javalette-configuration.k"

module JAVALETTE
    imports JAVALETTE-SYNTAX
    imports JAVALETTE-ENV
    imports JAVALETTE-CONFIGURATION
    
    imports DOMAINS 
    imports FLOAT

    syntax KResult ::= Int
                     | Float 
                     | Bool  


    /// Scan Function Definitions
    // consume all top level definitions
    rule 
        <k> 
            T:Type I:Id ( Ps:Params ) Body:Block Prg:Program
                => 
            Prg ~> checkFun(I) ... 
        </k>
        <funs> FUNS => FUNS[I <- (T I ( Ps ) Body) ] </funs> requires notBool(I in_keys(FUNS))
    rule <k> .Program => . ... </k>

    
        

    syntax KItem ::= checkFun (Id)
        rule 
            <k> checkFun(F:Id) => checkBlock(Body) ... </k>
            <funs> ... F |->  (T _ ( Ps ) Body) ... </funs>
            <typecheck>
                <tenv> _ => envMake(Ps) </tenv>
                <retType> _ => T </retType>
            </typecheck>

    syntax Map ::= mkEnv(Params)         [function]
    syntax Map ::= mkEnvAcc(Params , Map) [function]
    rule mkEnv( Ps:Params ) => mkEnvAcc(Ps , .Map)
    rule mkEnvAcc( .Params , Acc ) => Acc 
    rule mkEnvAcc( (T:Type V:Id , Ps:Params) , Acc:Map ) => mkEnvAcc(Ps, (V |-> T) Acc) requires notBool (V in_keys(Acc))

    
             
    syntax KItem ::= checkBlock( Block ) 
    rule <k> checkBlock( { Ss:Stmts } ) => pushTBlock ~> checkStmts(Ss) ~> popTBlock ... </k>
    
    syntax KItem ::= checkStmts( Stmts )
    rule <k> checkStmts( .Stmts ) => . ... </k>
    rule <k> checkStmts( S:Stmt Ss:Stmts ) => checkStmt(S) ~> checkStmts(Ss) ... </k>

    syntax KItem ::= checkStmt(Stmt)
    rule <k> checkStmt( ; ) => . ... </k>
    rule <k> checkStmt( B:Block ) => checkBlock(B) ... </k>
    // variable declaration
    rule 
        checkStmt(T:Type V:DeclItem , V2 , Vs:DeclItems ; ) 
                =>  
        checkStmt(T V;) ~> checkStmt( T V2 , Vs ; ) [structural]
        
    rule 
        <k> checkStmt( T:Type V:Id ; ) => . ... </k>
        <tenv> ENV => envInsert(V, T, ENV) </tenv>
        requires notBool(envTopContains(ENV, V))
    rule 
        <k> checkStmt( T:Type V:Id = E:Exp ; ) => . ... </k>
        <tenv> ENV => envInsert(V, T, ENV) </tenv>
        requires notBool(envTopContains(ENV, V))
                 andBool checkExp(T, E)
    
    // Assignment
    rule 
        <k> checkStmt( V:Id = E:Exp ; ) => . ... </k>
        <tenv> ENV </tenv>
        requires envContains(ENV, V) andBool
                 checkExp( envLookup(ENV, V) , E)
    
    rule 
        <k> checkStmt( return ; ) => . ... </k>
        <retType> void </retType>

    rule 
        <k> checkStmt( return E:Exp ; ) => . ... </k>
        <retType> T </retType>
        requires checkExp(T, E)

    rule 
        <k> checkStmt( if( E:Exp ) ST:Stmt else SF:Stmt  ) 
                => 
            checkStmt(ST) ~> checkStmt(SF) ... 
        </k>
        requires checkExp(boolean, E)
        
    rule 
        <k> checkStmt( while( E:Exp ) ST:Stmt ) 
                => 
            checkStmt(ST) ... 
        </k>
        requires checkExp(boolean, E)
    
    rule <k> checkStmt(E:Exp ;) => . ... </k> requires checkExp(void, E)

    syntax Type ::= inferExp(Exp) [function]
        rule [[inferExp(V:Id) => envLookup(ENV,V)]]
            <tenv> ENV </tenv> 

        rule inferExp(_:Int)           => int 
        rule inferExp(true)            => boolean 
        rule inferExp(false)           => boolean 
        rule inferExp(_:Float)        => double

        rule inferExp(printInt(E:Exp))       => void requires int ==K inferExp(E)
        rule inferExp(printDouble(E:Exp))    => void requires double ==K inferExp(E)
        rule inferExp(printString(_:String)) => void
        rule inferExp(readInt())             => int

        rule [[ inferExp(Fun:Id  ( As:Args ) )  => T ]]
            <funs> ... Fun |-> (T:Type _ ( Ps:Params ) _ ) ... </funs> requires checkArgs(As, Ps)
        
        // debug TODO
        // rule [[ inferExp(Fun:Id  ( As:Args ) )  => T ]]
        //     <funs> ... Fun |-> (T:Type _ ( Ps:Params ) _ ) ... </funs> [owise]

        // TODO refactor this.      XXXXXXXX -----------> XXXXXXX ???
        rule inferExp( - E:Exp) => inferExp(E) requires isNumeric(inferExp(E))
        // rule inferExp( - E:Exp) => int    requires checkExp(int,    E)
        // rule inferExp( - E:Exp) => double requires checkExp(double, E)

        rule inferExp( ! E:Exp) => boolean requires checkExp(boolean, E)

        rule inferExp( E1:Exp + E2:Exp ) => inferArith(inferExp(E1), E2)
        rule inferExp( E1:Exp - E2:Exp ) => inferArith(inferExp(E1), E2)
        rule inferExp( E1:Exp / E2:Exp ) => inferArith(inferExp(E1), E2)
        rule inferExp( E1:Exp * E2:Exp ) => inferArith(inferExp(E1), E2)
        rule inferExp( E1:Exp % E2:Exp ) => int requires checkExp(int, E1) andBool checkExp(int, E2)
        
        syntax Type ::= inferArith(Type, Exp) [function, functional]
            rule inferArith(T:Type, Other:Exp) => T requires checkExp(T, Other)
                                                             andBool isNumeric(T)

        rule inferExp( E1:Exp == E2:Exp ) => inferComparison(inferExp(E1), E2)
        rule inferExp( E1:Exp != E2:Exp ) => inferComparison(inferExp(E1), E2)
        rule inferExp( E1:Exp >= E2:Exp ) => inferComparison(inferExp(E1), E2)
        rule inferExp( E1:Exp >  E2:Exp ) => inferComparison(inferExp(E1), E2)
        rule inferExp( E1:Exp <= E2:Exp ) => inferComparison(inferExp(E1), E2)
        rule inferExp( E1:Exp <  E2:Exp ) => inferComparison(inferExp(E1), E2)
        
        syntax Type ::= inferComparison(Type, Exp) [function, functional]
            rule inferComparison(T:Type, Other:Exp) => boolean requires checkExp(T, Other)
                                                                        andBool isNumeric(T)

        rule inferExp( E1:Exp && E2:Exp ) => boolean requires checkExp(boolean, E1)
                                                              andBool checkExp(boolean, E2)
        rule inferExp( E1:Exp || E2:Exp ) => boolean requires checkExp(boolean, E1)
                                                              andBool checkExp(boolean, E2)


    syntax Bool ::= checkExp(Type, Exp) [function, functional]
        // TODO : double literals without decimal point?
        rule checkExp( double, _:Int ) => true
        rule checkExp( T:Type, E:Exp ) => T ==K inferExp(E)
        rule checkExp( _, _) => false [owise]

    syntax Bool ::= isNumeric(Type) [function, functional]
        rule isNumeric(int)    => true 
        rule isNumeric(double) => true 
        rule isNumeric(_)      => false [owise]

    syntax Bool ::= checkArgs(Args, Params) [function, functional]
        rule checkArgs(.Args, .Params)       => true 
        rule checkArgs((A, As), ((T _), Ps)) => checkArgs(As, Ps) requires checkExp(T, A) 
        // OTHERWISE : type mismatch or invalid number of args
        rule checkArgs(_, _)                 => false [owise] 
    

endmodule

