
```k
module JAVALETTE-RETURNCHECK
    imports JAVALETTE-SYNTAX
    imports JAVALETTE-CONFIGURATION

    imports LIST
    imports BOOL
    imports K-EQUAL
    

    syntax KItem ::= "#returncheck"

    rule <progress> #returncheck => . ... </progress>
         <program> Prg </program>
         requires retcheckProgram(Prg)
    
    syntax Bool ::= retcheckProgram(Program) [function, total]
    rule retcheckProgram(.Program) => true
    rule retcheckProgram(F:TopDef Rest) => retcheckTopDef(F) andBool retcheckProgram(Rest)
    
    syntax Bool ::= retcheckTopDef(TopDef) [function, total]
    rule retcheckTopDef(FD:FunDef) => retcheckFunDef(FD)

    syntax Bool ::= retcheckFunDef(FunDef) [function, total]
    rule retcheckFunDef(T _ (_) { Body }) => (T ==K void) orBool retcheckStmts(Body)

    syntax Bool ::= retcheckStmts(Stmts) [function, total]
    rule retcheckStmts(.Stmts) => false
    rule retcheckStmts(S Ss) => retcheckStmt(S) orBool retcheckStmts(Ss) 

    syntax Bool ::= retcheckStmt(Stmt) [function, total]
    rule retcheckStmt(return _;) => true
    rule retcheckStmt(return;)   => true
    
    rule retcheckStmt(if(_)     T else F) => retcheckStmt(T) andBool retcheckStmt(F)
    
    rule retcheckStmt({ Ss })        => retcheckStmts(Ss)

    rule retcheckStmt(;) => false
    rule retcheckStmt(_:Type _:DeclItems ;) => false
    rule retcheckStmt(_ = _ ;) => false
    rule retcheckStmt(_ ;) => false
    rule retcheckStmt(while(_)_) => false
    
    // To suppress the non-exhaustive match warning
    rule retcheckStmt(_ ++;) => false
    rule retcheckStmt(_ --;) => false
    

endmodule
```