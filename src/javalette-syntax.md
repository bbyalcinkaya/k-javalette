
```k
module JAVALETTE-SYNTAX
    imports ID-SYNTAX
    imports UNSIGNED-INT-SYNTAX
    imports STRING-SYNTAX
    imports BOOL-SYNTAX
    
    syntax Id ::= "main" [token]
    syntax Program ::= List{TopDef, ""}
    syntax TopDef ::= Type Id "(" Params ")" Block

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
                      | Id "=" Exp // [strict(2)]
    
    
    // Assignment
    syntax Stmt ::= Id "=" Exp ";"  [strict(2)]
                  | Id "++" ";" [macro] 
                  | Id "--" ";" [macro] 
    rule I:Id ++ ; => I = I + 1 ; 
    rule I:Id -- ; => I = I - 1 ;
                  
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
    syntax Float ::= r"[0-9]+\\.[0-9]+([eE][\\+-]?[0-9]+)?" [token]//, prec(2)]
  
    syntax Exp ::= Id 
                 | Bool
                 | Int                          
                 | Float
                 > "(" Exp ")"                  [bracket]
                 > "readInt" "(" ")"
                 | "readDouble" "(" ")"
                 | "printInt" "(" Exp ")"       [strict]
                 | "printString" "(" String ")"
                 | "printDouble" "(" Exp ")"    [strict]
                 | Id "(" Args ")" 
                 > "-" Exp              [strict]     
                 | "!" Exp              [strict]
                 
                 > Exp "*" Exp           [left, seqstrict]
                 | Exp "/" Exp           [left, seqstrict]
                 | Exp "%" Exp           [left, seqstrict]
        
                 > Exp "+" Exp           [left, seqstrict]
                 | Exp "-" Exp           [left, seqstrict]
                
                 > Exp "==" Exp          [left, seqstrict]
                 | Exp "!=" Exp          [left, seqstrict]
                 | Exp ">=" Exp          [left, seqstrict]
                 | Exp ">"  Exp          [left, seqstrict]
                 | Exp "<=" Exp          [left, seqstrict]
                 | Exp "<"  Exp          [left, seqstrict]
                
                 > Exp "&&" Exp          [left, strict(1)]
                 > Exp "||" Exp          [left, strict(1)]

    syntax Args ::= List{Exp, ","}       [strict]

    syntax KResult ::= Value
    
    syntax Value ::= Int
                   | Float 
                   | Bool  
                   | "nothing"

endmodule 
```