
```k
module JAVALETTE-SYNTAX
    imports ID-SYNTAX
    imports UNSIGNED-INT-SYNTAX
    imports STRING-SYNTAX
    imports BOOL-SYNTAX
    
    syntax Id ::= "main" [token]
                | "length" [token]
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
                      | Id "=" Exp // [strict(2)]
    
    
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
    
    syntax Stmt ::= "for" "(" Type Id ":" Exp ")" Stmt

    // Expression statement
    syntax Stmt ::= Exp ";" [strict]
    
    /// TYPES
    syntax Type ::= "int"
                  | "double"
                  | "boolean"
                  | "void"
    syntax Type ::= Type "[" "]"
                  
    syntax Float [hook(FLOAT.Float)]
    syntax Float ::= r"[0-9]+\\.[0-9]+([eE][\\+-]?[0-9]+)?" [token]//, prec(2)]
    
    // array index and size
    syntax Box ::= "[" Exp "]"
    syntax Boxes ::= List{Box, ""}

    syntax Exp ::= "(" Exp ")"                  [bracket]
                 | Bool
                 | Int                          
                 | Float
                 > "new" Type Boxes
                 > "readInt" "(" ")"
                 | "readDouble" "(" ")"
                 | "printInt" "(" Exp ")"       [strict]
                 | "printString" "(" String ")"
                 | "printDouble" "(" Exp ")"    [strict]
                 | Id "(" Args ")" 
                 > Exp "[" Exp "]"              [seqstrict]
                 | Exp "." Id                   [strict(1)]
                 | Id 
                 > "-" Exp              [strict]     
                 | "!" Exp              [strict]
                 
                 > //left:
                   Exp "*" Exp           [left, seqstrict]
                 | Exp "/" Exp           [left, seqstrict]
                 | Exp "%" Exp           [left, seqstrict]
        
                 > //left:
                   Exp "+" Exp           [left, seqstrict]
                 | Exp "-" Exp           [left, seqstrict]
                
                 > //left:
                   Exp "==" Exp          [left, seqstrict]
                 | Exp "!=" Exp          [left, seqstrict]
                 | Exp ">=" Exp          [left, seqstrict]
                 | Exp ">"  Exp          [left, seqstrict]
                 | Exp "<=" Exp          [left, seqstrict]
                 | Exp "<"  Exp          [left, seqstrict]
                
                 > Exp "&&" Exp          [right, strict(1)]
                 > Exp "||" Exp          [right, strict(1)]

    syntax Args ::= List{Exp, ","}       [strict]


endmodule 
```