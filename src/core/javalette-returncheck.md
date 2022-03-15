
```k
module JAVALETTE-RETURNCHECK
    imports JAVALETTE-SYNTAX
    imports JAVALETTE-CONFIGURATION

    imports LIST
    imports BOOL
    imports K-EQUAL
    

    syntax KItem ::= Retcheck(Program)

    rule <progress> Retcheck(Prg) => . ... </progress> requires retcheckProgram(Prg)
    
    syntax Bool ::= retcheckProgram(Program) [function, functional]
    rule retcheckProgram(.Program) => true
    rule retcheckProgram(F:TopDef Rest) => retcheckTopDef(F) andBool retcheckProgram(Rest)
    
    syntax Bool ::= retcheckTopDef(TopDef) [function, functional]
    rule retcheckTopDef(FD:FunDef) => retcheckFunDef(FD)

    syntax Bool ::= retcheckFunDef(FunDef) [function, functional]
    rule retcheckFunDef(T _ (_) { Body }) => (T ==K void) orBool retcheckStmts(Body)

    syntax Bool ::= retcheckStmts(Stmts) [function, functional]
    rule retcheckStmts(.Stmts) => false
    rule retcheckStmts(S Ss) => retcheckStmt(S) orBool retcheckStmts(Ss) 

    syntax Bool ::= retcheckStmt(Stmt) [function, functional]
    rule retcheckStmt(return _;) => true
    rule retcheckStmt(return;)   => true
    
    rule retcheckStmt(if(_)     T else F) => retcheckStmt(T) andBool retcheckStmt(F)
    
    rule retcheckStmt({ Ss })        => retcheckStmts(Ss)

    rule retcheckStmt(_) => false [owise]
    
    

endmodule
```