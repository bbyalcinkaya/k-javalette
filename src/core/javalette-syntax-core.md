
```k
module JAVALETTE-SYNTAX-CORE
    imports ID-SYNTAX
    imports UNSIGNED-INT-SYNTAX
    imports STRING-SYNTAX
    imports BOOL-SYNTAX
    
    syntax Id ::= "main" [token]
    
    syntax Program ::= List{TopDef, ""}
    syntax TopDef ::= FunDef
    syntax FunDef ::= Type Id "(" Params ")" Block

    syntax Params ::= List{Param, ","}
    syntax Param ::= Type Id 

    /// STATEMENTS

    // Empty statement
    syntax Stmt ::= ";"
    
    // Block statement
    syntax Stmt ::= Block
    syntax Block ::= "{" Stmts "}"
    syntax Stmts ::= List{Stmt, ""}

    // Variable declaration
    syntax Stmt ::= Type DeclItems ";"
    syntax DeclItems ::= List{DeclItem, ","}
    syntax DeclItem ::= Id 
                      | Id "=" Exp
    
    
    // Assignment
    syntax Stmt ::= Exp "=" Exp ";" [strict(2)]
                  | Exp "++" ";" [macro] 
                  | Exp "--" ";" [macro] 
    rule I ++ ; => I = I + 1 ; 
    rule I -- ; => I = I - 1 ;
                  
    // Return
    syntax Stmt ::= "return" ";"
                  | "return" Exp ";" [strict]

    // Control flow
    syntax Stmt ::= "if" "(" Exp ")" Stmt "else" Stmt    [strict(1)]
                  | "if" "(" Exp ")" Stmt                [macro]
                  | "while" "(" Exp ")" Stmt            
    rule if (E) S => if (E) S else { .Stmts }
    
    
    // Expression statement
    syntax Stmt ::= Exp ";" [strict]
    
    /// TYPES
    syntax Type ::= "int"
                  | "double"
                  | "boolean"
                  | "void"
                  
    syntax Float [hook(FLOAT.Float)]
    syntax Float ::= r"[0-9]+\\.[0-9]+([eE][\\+-]?[0-9]+)?" [token] //, prec(2)]
    

    syntax Exp ::= "(" Exp ")"                  [bracket]
                 | Bool                         [literal]
                 | Int                          [literal]
                 | Float                        [literal]
                 | Id 
                 
                 | "readInt" "(" ")"            [funcall]
                 | "readDouble" "(" ")"         [funcall]
                 | "printInt" "(" Exp ")"       [strict, funcall]
                 | "printString" "(" String ")" [funcall]
                 | "printDouble" "(" Exp ")"    [strict, funcall]
                 | Id "(" Args ")"              [funcall]
                 
                 | "-" Exp              [strict, unary]     
                 | "!" Exp              [strict, unary]
                 
                 | Exp "*" Exp           [left, seqstrict, binaryMult]
                 | Exp "/" Exp           [left, seqstrict, binaryMult]
                 | Exp "%" Exp           [left, seqstrict, binaryMult]
        
                 | Exp "+" Exp           [left, seqstrict, binaryAdd]
                 | Exp "-" Exp           [left, seqstrict, binaryAdd]
                
                 | Exp "==" Exp          [left, seqstrict, binaryComp]
                 | Exp "!=" Exp          [left, seqstrict, binaryComp]
                 | Exp ">=" Exp          [left, seqstrict, binaryComp]
                 | Exp ">"  Exp          [left, seqstrict, binaryComp]
                 | Exp "<=" Exp          [left, seqstrict, binaryComp]
                 | Exp "<"  Exp          [left, seqstrict, binaryComp]
                
                 > Exp "&&" Exp          [right, strict(1)]
                 > Exp "||" Exp          [right, strict(1)]

    syntax Args ::= List{Exp, ","}       [strict]

    syntax priorities literal > funcall > unary > binaryMult > binaryAdd > binaryComp

endmodule 
```
