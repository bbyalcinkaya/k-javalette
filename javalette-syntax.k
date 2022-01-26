module JAVALETTE-SYNTAX 
    imports ID 
    imports INT

    syntax Id ::= "main" [token]
    syntax Program ::= List{TopDef, ""}
    syntax TopDef ::= Type Id "(" Params ")" Block

    syntax Params ::= List{Param, ","}
    syntax Param ::= Type Id 

    syntax Stmt ::= Block
                  | Stmt Stmt [right]
                  | ";"
                  | Exp ";" [strict]  // TODO expression stmt
                  // variable declaration
                  // | Type DeclItems ";"    
                  | Type Id "=" Exp ";" [strict(3)]
                    
                  // assignment
                  | Id "=" Exp ";"                      [strict(2)]
                  
                  
                  | Id "++" ";"
                  | Id "--" ";"
                  
                  | "return" Exp ";"  [strict]
                  // | "return" ; // TODO empty return for void funcs  
                
                // control flow
                  | "if" "(" Exp ")" Block               [strict(1)]
                  | "if" "(" Exp ")" Block "else" Block   [strict(1)]
                  | "while" "(" Exp ")" Block            

    
    syntax Block ::= "{" Stmt "}" 
                   | "{" "}"

    // syntax DeclItems ::= List{DeclItem, ","}
    // syntax DeclItem ::= Id 
    //                   | Id "=" Exp 

    syntax KResult ::= Int 
    // syntax Value ::= KResult 
    // syntax Values ::= List{Value, ","}
    syntax Exp ::= Int | Id 
                // TODO
                // | Double 
                // | "true" | "false"
                // | String
                 | "(" Exp ")"            [bracket]
                 > "readInt" "(" ")"
                 | "printInt" "(" Exp ")" [strict]
                 | Id "(" Args ")"        
                 > "-" Exp              
                 | "!" Exp  
                 
                 > Exp "*" Exp          [left, strict]
                 | Exp "/" Exp          [left, strict]
                 | Exp "%" Exp          [left, strict]
        
                 > Exp "+" Exp          [left, strict]
                 | Exp "-" Exp          [left, strict]
                
                 > Exp "==" Exp          [left, strict]
                 | Exp "!=" Exp          [left, strict]
                 | Exp ">=" Exp          [left, strict]
                 | Exp ">"  Exp          [left, strict]
                 | Exp "<=" Exp          [left, strict]
                 | Exp "<"  Exp          [left, strict]
                
                 > Exp "&&" Exp         [left, strict(1)]
                 > Exp "||" Exp         [left, strict(1)]

    syntax Args ::= List{Exp, ","}      [strict]

    syntax Type ::= "int"
                // TODO other types
                //   | "double"
                //   | "boolean"
                //   | "void"

endmodule 