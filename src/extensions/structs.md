

```k
requires "../core/javalette-syntax-core.md"

module JAVALETTE-STRUCTS-SYNTAX
    imports JAVALETTE-SYNTAX-CORE

    syntax TopDef ::= StructDef
                    | TypeDef

    syntax StructDef ::= "struct" Id "{" FieldDefs "}" ";"
    syntax FieldDefs ::= List{FieldDef, ""}
    syntax FieldDef ::= Type Id ";"    
    
    syntax TypeDef ::= "typedef" "struct" Id "*" Id ";"

    syntax Type ::= Id

    syntax Exp ::= Exp "->" Id   [strict(1), funcall]
                 | "new" Type    [funcall]
                 | "(" Id ")" "null"        [literal]
                  
endmodule


module JAVALETTE-STRUCTS

    imports JAVALETTE-STRUCTS-SYNTAX
    imports JAVALETTE-RETURNCHECK
    imports JAVALETTE-TYPES
    imports JAVALETTE-TOPLEVEL
    imports JAVALETTE-EXECUTION
    imports SET

    configuration
        <structs>
            <structMaps> .Map </structMaps>
            <typedefs> .Map </typedefs>
        </structs>

    syntax Type ::= "#ptr" "(" Id ")"
```

## Handling Toplevel declarations
```k
    rule
        <k> processTopDef(typedef struct SName * TName ;) =>  
            . ...
        </k>
        <typedefs> TDefs => TDefs (TName |-> SName) </typedefs>
        requires notBool(TName in_keys(TDefs))

    rule
        <k> processTopDef(struct SName { Fields };) => . ... </k>
        <structMaps> 
            Structs => Structs (SName |-> structMap(Fields))
        </structMaps>
        requires notBool(SName in_keys(Structs))
                andBool uniqueFields(Fields)
    
    

    syntax Bool ::= uniqueFields(FieldDefs) [function,functional]
                  | uniqueFieldsH(Set, FieldDefs) [function,functional]
    rule uniqueFields(FDs) => uniqueFieldsH(.Set, FDs)
    rule uniqueFieldsH(_, .FieldDefs) => true
    rule uniqueFieldsH(S, (_ I;) Rest) => notBool(I in S) 
                                          andBool uniqueFieldsH(SetItem(I) S, Rest)

    syntax Map ::= structMap(FieldDefs) [function,functional]
                 | structMapH(Map,Int,FieldDefs) [function,functional]
    rule structMap(FDs) => structMapH(.Map,0,FDs)
    rule structMapH(M,_,.FieldDefs) => M
    rule structMapH(M,I,(T F;) Rest) => structMapH(M (F |-> fpair(T,I)), I +Int 1, Rest)
    
    syntax FPair ::= fpair(Type, Int)
    
    syntax Int ::= findOffset(Id, Id) [function]
    rule [[findOffset(SName, F) => #let fpair(_,I) = SM[F] 
                                    #in I ]]
        <structMaps> ... SName |-> SM:Map ... </structMaps>

    
```
## Type checking
```k
    syntax KItem ::= "#unknownTypeName" "(" Id ")"
```
Check if the struct in `typedef` exists. 
```k
    rule
        <tcode> typedef struct SName * _ ; => . ... </tcode>
        <structMaps> Structs </structMaps>
        requires SName in_keys(Structs)
```

Struct fields must have valid types. If the type is an identifier, there must be a corresponding `typedef`. Fields cannot be void.

```k
    rule
        <tcode> struct _SName { Fields }; => . ... </tcode>
        requires validFields(Fields)

    syntax Bool ::= validFields(FieldDefs) [function,functional]
    rule validFields(.FieldDefs) => true
    rule validFields((T _;) FDs) => validDataType(T) andBool validFields(FDs)

    
    rule [[ validDataType(T:Id) => T in_keys(TD) ]]
        <typedefs> TD </typedefs>

    rule [[ validDataType(#ptr(T)) => T in_keys(TD) ]]
        <structMaps> TD </structMaps>

        
```

Check function types:
```k
    rule
        <tcode> (T _ ( _ ) _):FunDef => #unknownTypeName(T) </tcode>
        requires notBool(T ==K void orBool validDataType(T))
        [priority(1)]
``` 
### Expressions
```k

    rule [[ equalType(T1:Id, T2) => equalType(#ptr(S), T2)]]
        <typedefs> ... T1 |-> S ... </typedefs>                 [priority(1)]
    rule [[ equalType(T1, T2:Id) => equalType(T1, #ptr(S))]]
        <typedefs> ... T2 |-> S ... </typedefs>                 [priority(2)]
```

```k

    rule inferExp(E -> F) => inferField(inferExp(E), F)

    syntax InferRes ::= inferField(InferRes, Id) [function,functional]
    
    rule [[ inferField(TName:Id, F) => inferField(#ptr(SName), F) ]]
        <typedefs> ... TName |-> SName ... </typedefs> 

    rule [[ inferField(#ptr(SName), F) => #let fpair(T,_) = SM[F]
                                          #in T 
        ]]
        <structMaps> ... SName |-> SM ... </structMaps>
        requires F in_keys(SM)


    rule inferField(_,_) => #typeError                   [owise]

    rule [[ inferExp(new SName) => #ptr(SName) ]]
        <structMaps> ... SName |-> _ ... </structMaps>

    
```
```k
    rule [[ inferExp((TName) null) => TName ]]
        <typedefs> ... TName |-> _ ... </typedefs>

    rule isEquality(_:Id) => true
```

## Execution

```k
    syntax Value ::= struct(Id, Int)
                   | "#nullptr"

    rule defaultValue(#ptr(_)) => #nullptr
    rule defaultValue(_:Id) => #nullptr

    rule <k> (_:Id) null => #nullptr ... </k>

    rule 
        <k> new SName:Id => initFields(I, values(SM)) ~> struct(SName, I) ... </k>
        <structMaps> ... SName |-> SM ... </structMaps>
        <next-loc> I => I +Int size(SM) </next-loc>

    syntax KItem ::= initFields(Int, List)
    rule <k> initFields(_, .List) => . ... </k>
    rule 
        <k> initFields(I, ListItem(fpair(T,X)) FDs) => initFields(I, FDs) ... </k>
        <store> ST => ST[I +Int X <- defaultValue(T)] </store>
```
### Field Access
```k
    rule
        <k> struct(SName, Loc) -> F => ST[Loc +Int findOffset(SName, F)] ...</k>
        <store> ST </store>
```

### Comparison operators

```k
    
    rule <k> struct(S1,L1) == struct(S2,L2) => S1 ==K S2 andBool L1 ==Int L2 ... </k>
    rule <k> struct(_,_)   == #nullptr => false ... </k>
    rule <k> #nullptr      == struct(_,_) => false ... </k>
    rule <k> #nullptr      == #nullptr => true ... </k>
    
    rule <k> struct(S1,L1) != struct(S2,L2) => notBool(S1 ==K S2 andBool L1 ==Int L2) ... </k>
    rule <k> struct(_,_)   != #nullptr => true ... </k>
    rule <k> #nullptr      != struct(_,_) => true ... </k>
    rule <k> #nullptr      != #nullptr => false ... </k>
    

```

### Assignment
```k

    rule <k> locate(E -> F) => locateField(E, F) ... </k>
    
    syntax KItem ::= locateField(Exp, Id) [strict(1)]
    rule 
        <k> 
            locateField(struct(SName, Loc), F) => findOffset(SName, F) +Int Loc
            ... 
        
        </k>


```



## Return checking

```k
    
    rule retcheckTopDef(_:StructDef) => true
    rule retcheckTopDef(_:TypeDef) => true
    

```

```k
    rule isLValue(_:Exp -> _:Id ) => true


endmodule

```