
```k
module JAVALETTE-RETURNCHECK [private]
    imports JAVALETTE-CONFIGURATION
    imports JAVALETTE-SYNTAX

    imports LIST
    imports BOOL

    rule <k> returncheck => retcheckFuns(values(FUNS)) ... </k>
         <funs> FUNS </funs> [structural]

    syntax KItem ::= retcheckFuns(List)
    rule <k> retcheckFuns(.List) => . ... </k>
    rule <k> 
        retcheckFuns(ListItem(F:TopDef) Rest) => 
        retcheckFun(F) ~> retcheckFuns(Rest) ... 
    </k> 
//    requires retcheckFun(F)
    
    syntax KItem ::= retcheckFun(TopDef)
    rule <k> retcheckFun(void _ (_) { _ })   => . ... </k>
    rule <k> retcheckFun(T    _ (_) { Body }) => . ... </k>
        requires (T =/=K void) andBool retcheckStmts(Body)

    syntax Bool ::= retcheckStmts(Stmts) [function, functional]
    rule retcheckStmts(.Stmts) => false
    rule retcheckStmts(S Ss) => retcheckStmt(S) orBool retcheckStmts(Ss) 

    syntax Bool ::= retcheckStmt(Stmt) [function, functional]
    rule retcheckStmt(return _;) => true
    rule retcheckStmt(return;)   => true
    
    rule retcheckStmt(if(true)  T else _) => retcheckStmt(T)
    rule retcheckStmt(if(false) _ else F) => retcheckStmt(F)
    rule retcheckStmt(if(E)     T else F) => retcheckStmt(T) andBool retcheckStmt(F)
        requires (true:Exp =/=K E) andBool (false:Exp =/=K E)
    
    rule retcheckStmt(while(true) _) => true

    rule retcheckStmt({ Ss })        => retcheckStmts(Ss)

    rule retcheckStmt(_) => false [owise]
    
    

endmodule
```