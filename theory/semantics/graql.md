# Denotational Semantics of Graql Operations

We use [[ `expr` ]]  instead of the actual joined double brackets to represent denotations

So, we need to take each Graql expression `E` and define the denotation [[`E`]] in our mathematical domain. We use the domain theoretic definitions.

## Graql Syntax


We assume queries are in a normalised form - some statements are made explicit (eg. no `match $x isa person, has name`, instead use `match $x isa person, has $n; $n isa name;`) :
```
Var = any valid variable name (irrelevant)
Type = any valid type name (irrelevant)
TypeOrVar = Type | Var
Role = ???
Datatype = string | bool | long | double | date
Value = any valid attribute value
Id = Regex for valid IDs (V... | E...)
Regex = all valid Java regexes

Q = Define | Undefine | Insert | Match Get | Match Insert | Match Delete

Define = define DefineProperty
Undefine = undefine DefineProperty

DefineProperty = Type TypeProperties; | Type TypeProperties; DefineProperty
TypeProperties = abstract | Sub | has Type | key Type | plays Type | Relates
Sub = sub Type | sub Type, when { Match }, then { Insert } | sub Type, datatype Datatype
Relates = relates Type | relates Type as Type

Insert = insert InsertStatements;

InsertStatements = Var InsertProperties; | Var InsertProperties; InsertStatements
InsertProperties = Isa | has Var
Isa = isa Type | isa Var | Value isa Type | (RolePlayers) isa Type
RolePlayers = Role : Var | Role : Var, RolePlayers

Match = match MatchStatements
MatchStatements = MatchConjunction | MatchDisjunction or MatchStatements
MatchConjunction = Var MatchProperties; | Var MatchProperties; MatchConjunction | TODO NEGATION
MatchProperties = MatchTypeProperty | MatchDataProperty
MatchTypeProperty = abstract | MatchSub | has TYPE | key TYPE | plays TypeOrVar | MatchRelates
MatchSub = sub TypeOrVar | sub [ TODO CAN WE DO RULE MATCH? ] | sub Type, datatype
MatchRelates = relates TypeOrVar | relates TypeOrVar as TypeOrVar
MatchDataProperty = has Type Var | has Type | Value | (MatchRolePlayers) | isa TypeOrVar | id Id
MatchRolePlayers = TypeOrVar : Var | TypeOrVar : Var, MatchRolePlayers

Get = Var | Var, Get

```

## Denotational Semantics

In combination with the domains defined for $KG$, we also define the following domains:

$Answer = \Pi_{n=0}^{n=\infty} (Var, (Type \cup I))$  \
In other words, an answer is any length list of pairs, where each pair is a Variable mapped to a type or instance.

$Var$ = countably infinite set of all valid variable strings preceded by $

$Id$ = set of all possible IDs

The following syntactic elements have the direct mapping into semantic domains:

[[`Var`]] - $Var$  -- ie. `Var` is mapped to domain $Var$ \
[[`Type`]] - $Lab$ \
[[`TypeOrVar`]] - $Var \cup Lab$ \
[[`Datatype`]] - $Datatype$ \
[[`Regex`]] - $Regex$ \
[[`Id`]] - $Id$ \
[[`Value`]] - $Values$

A Graql query takes the following form: `Q -> A`, with `Q` being the query and `->` being the evaluation to an [LIST OF??] answer `A`.


[[`Q -> `]] = $Eval$[[`Q`]] \
$Eval$[[`define DefineProperty`]] = $Define(Write$[[`DefineProperty`]], $KG)$  \
$Eval$[[`undefine DefineProperty`]] = $Undefine(Write$[[`DefineProperty`]], $KG)$ \
$Eval$[[`insert InsertStatements`]] = $Insert(WriteIns$[[`InsertStatements`]], $KG, ()))$ \
$Eval$[[`match MatchStatements`]] = $Match(Read$[[`MatchStatements`]], $KG)$  \
$Eval$[[`match MatchStatements; insert InsertStatements`]] = 
$Insert(Write$[\[`insert InsertStatements`]], $KG, Match(Read$[\[`MatchStatements`]], $KG))$ \
$Eval$[[`match MatchStatements; delete Vars`]] = 
$Delete($[\[`Vars`]], $KG, Match(Read$[\[`MatchStatements`]], $KG))$


$Define: set(Constraint) \rightarrow KG \rightarrow KG$  \
$Define = \lambda C. \lambda G. G'$ is the minimal extension of $G$ and $C(G')$ and $valid(G')$

$Undefine: set(Constraint) \rightarrow KG \rightarrow KG$ \
$Undefine = \lambda C. \lambda G. G'$ is the minimum reduction of $G$ and $\neg C(G')$ and $valid(G')$

$Delete: set(Constraint) \rightarrow KG \rightarrow KG$ \
$Delete = \lambda C. \lambda G. G'$ is the minimum reduction of $G$ and $\neg C(G')$ and $valid(G')$

$Match: set(ReadConstraint) \rightarrow KG \rightarrow Answer$ \
$Match = \lambda C. \lambda KG. A \in Answer$ such that $C(KG, A)$

$Insert: set(Constraint) \rightarrow KG \rightarrow Answer \rightarrow TODO???$

$Delete: Vars \rightarrow KG \rightarrow Answer \rightarrow KG$


$Write$: `DefineProperty` -> Set of $Constraint$ 

$WriteIns$: `InsertProperty` -> Set of $Constraint$

$Read$: `MatchStatements` -> Set of $ReadConstraint$

$Constraint : KG \rightarrow B$ -- checks a constraint on a KG and returns true or false

$ReadConstraint: KG \rightarrow Answer \rightarrow B$


## Denotations of Defining and Undefining Types

Both `define ` and `undefine` are handled identically in terms of retrieving constraints, except that the $Define$ and $Undefine$ functions check different negated or non-negated constraints.

We define the sematics of each write query `DefineProperty` by writing the propositional constraints represented -- in other words, we need to define $Write$[[`DefineProperty`]]

Syntax:

`DefineProperty = Type TypeProperties; | Type TypeProperties; DefineProperty`

Semantic Functions:

$Write$[[`Type TypeProperties`]] = $\{ DefineConstraint$([[`Type`]], $TProp$[[`TypeProperties`]]) $\}$

$Write$[[`Type TypeProperties; DefineProperty`]] = $Write$[[`Type TypeProperties`]] $\cup Write$[[`DefineProperty`]]

$DefineConstraint: Label \rightarrow (Label \rightarrow Constraint) \rightarrow Constraint$ \
$DefineConstraint(label, constraint) = constraint(label)$ 

$TProp$[[`abstract`]] = $\lambda L. \lambda K. let \; t = label^{-1}(L) \; in \; t \in abstract$

$TProp$[[`sub Type`]] = $(\lambda P. \lambda L. \lambda K. t = label^{-1}(L) \wedge t_p = label^{-1}(P) \wedge (t, t_p) \in sub)$[[`Type`]]

$TProp$[[`sub rule, when { P } then { Q }`]] = __--> TODO__

$TProp$[[`sub attribute, datatype d`]] = $(\lambda D. \lambda L. \lambda K. t = label^{-1}(L) \wedge (t, t_{attribute}) \in sub \wedge datatype(t) = D)$[[`datatype d`]]

$TProp$[[`has Type`]] = $(\lambda A. \lambda L. \lambda K. t = label^{-1}(L) \wedge t_a = label^{-1}(A) \wedge (t, t_a) \in has \wedge (t, t_a) \not\in key)$[[`Type`]]

$TProp$[[`key Type`]] = $(\lambda K. \lambda L. \lambda K. t = label^{-1}(L) \wedge t_k = label^{-1}(K) \wedge (t, t_k) \in key)$[[`Type`]]

$TProp$[[`regex REGEX`]] = $(\lambda r. \lambda L. \lambda K. t = label^{-1}(L) \wedge regex(t) = r)$[[`REGEX`]]

$TProp$[[`plays Role`]] = $(\lambda R. \lambda L. \lambda K. t = label^{-1}(L) \wedge t_r = label^{-1}(R) \wedge (t, t_r) \in plays)$[[`Role`]]

$TProp$[[`relates Role`]] = $\lambda R. \lambda L. \lambda K. t = lambda^{-1}(L) \wedge t_r = label^{-1}(R) \wedge (t, t_r) \in relates)$[[`Role`]]

$TProp$[[`relates Role as Role2`]] = $\lambda R. \lambda R_2. \lambda L. \lambda K.$ ------  TODO


## Denotations of Inserting and Deleting Data Instances

General expression - insert _var_ _operation_ _target_

* var isa L         ====> creates an instance of L
  * $t$ such that $\lambda(t) = L$
  * add unique, new instance $c$ to $I$
  * $(c, t) \in isa$
* ISA special cases
  * var (role1: x, ...) isa R  ====> creates a relation instance with role player x1 for role1, etc.
    * $t_r$ such that $\lambda(t_r) = R$
    * let $c_x$ be the concept represented by $x$
    * add unique, new instance $c$ to $I$
    * $(c, t_r) \in isa$
    * $(c_x, c, role1) \in rel$
  * var "value" isa A  ====> creates an attribute with value "value"
    * $t_a$ such that $\lambda(t_a) = A$
    * add unique, new instance $c$ to $I$ if doesn't exist a $val(c) = \; ''value''$
    * $val(c) = \; ''value''$
* var has var2      ====> creates an ownership from instance represented by var to one represented by var2, if it is a key type for this concept type, adds it to key subset of has
  * let $c \in I$ be represented by $var$ and $a \in I$ be represented by $var2$
  * $(c, a) \in has_D \wedge$ \ $( (c, t_c) \in isa \wedge (a, t_a) \in isa \wedge (t_c, t_a) \in key \implies (c,a) \in key_D)$


[ TODO do we need this?? ] \
General expression - match _var_ _operation_ _target_; \
insert _var_ _operation_ _target_
match var isa relation; insert var (role: x2); ====> extends a relation with new role player

Delete:

General expression - match _var_ _operation_ _target_; delete _var_, _var_,...; NOTE all subject to data restriction: no connected edges

* var isa L; delete var;    ====> delete concepts that are type L
  * $\neg \exists (c, t_c) \in isa \wedge \lambda(t_c) = L$
* var id ID; delete var;    ====> ()
  * $\neg \exists Id(c) = ID$
* var VAL; delete var;      ====> delete attributes with value VAL
  * $\neg \exists Val(c) = VAL$
* var has var2 via var3; delete var3;   ====> delete attribute ownership
  * $\neg \exists (c, a) \in has_D$ 
* var (role: x1, ...); delete;  ====> TODO don't have a way to delete a role player from a relation!!
  * $\neg r, c, rol. (c, r, rol) \in rel$ -- deletes relation


## Denotations of Reading Types and Data

Syntax excerpt:
```
MatchStatements = MatchConjunction | MatchDisjunction or MatchStatements
MatchConjunction = Var MatchProperties; | Var MatchProperties; MatchConjunction | TODO NEGATION
MatchProperties = MatchTypeProperty | MatchDataProperty
MatchTypeProperty = abstract | MatchSub | has TYPE | key TYPE | plays TypeOrVar | MatchRelates
MatchSub = sub TypeOrVar | sub [ TODO CAN WE DO RULE MATCH? ] | sub Type, datatype
MatchRelates = relates TypeOrVar | relates TypeOrVar as TypeOrVar
MatchDataProperty = has Type Var | has Type | Value | (MatchRolePlayers) | isa TypeOrVar | id Id
MatchRolePlayers = TypeOrVar : Var | TypeOrVar : Var, MatchRolePlayers
```

Semantic Functions:

$Match: set(ReadConstraint) \rightarrow KG \rightarrow Answer$ \
$Match = \lambda C. \lambda KG. A \in Answer$ such that $C(A, KG)$ 

$Read$: `MatchStatements` -> Set of $ReadConstraint$ 

$ReadConstraint: Answer \rightarrow KG \rightarrow B$

$Read$[[`MatchConjunction`]] = $ReadConjunction$[[`MatchConjunction`]]

$Read$[[`MatchDisjunction or MatchStatements`]] = __--> TODO__

$ReadConjunction$[[`Var MatchProperties`]] = $\{ VarConstraint$([[`Var`]], $MProp$[[`MatchProperties`]]) $\}$

$VarConstraint: Var \rightarrow (Var \rightarrow ReadConstraint) \rightarrow ReadConstraint$ \
$VarConstraint(var, readconstraint) = readconstraint(var)$

$ReadConjunction$[[`Var MatchProperties; MatchConjunction`]] = $ReadConjunction$[[`Var MatchProperties`]] $\cup Read$[[`MatchConjunction`]]

$MProp$[[`MatchTypeProperty`]] = $MTypeProp$[[`MatchTypeProperty`]] \
$MProp$[[`MatchDataProperty`]] = $MDataProp$[[`MatchDataProperty`]]


### Querying for Types

A type is abstract when $t$ is in the set $abstract$:

* $MTypeProp$[[`abstract`]] = $\lambda V. \lambda A. \lambda K. (V, t) \in A \wedge t \in abstract$

A type is a subtype of another type when $(t, t')$ is in the transitive closure of $sub$:

* $MTypeProp$[[`sub Var`]] = $(\lambda V_2. \lambda V. \lambda A. \lambda K. (V, t) \in A \wedge (V_2, t_2) \in A \wedge (t, t_2) \in sub^*)$ [[`Var`]]  \
* $MTypeProp$[[`sub Type`]] =  $(\lambda L. \lambda V. \lambda A. \lambda K. (V, t) \in A \wedge t_2 = label^{-1}(L) \wedge (t, t_2) \in sub^*)$ [[`Type`]]

A type plays a role when the pair $(t, r)$ is in the $role_{trans}$ set, which includes inherited roles

* $MTypeProp$[[`plays Var`]] = $(\lambda V_2. \lambda V. \lambda A. \lambda K. (V, t) \in A \wedge (V_2, t_2) \in A \wedge (t, t_2) \in plays_{trans})$[[`Var`]] \
* $MTypeProp$[[`plays Role`]] = $(\lambda R. \lambda V. \lambda A. \lambda K. (V, t) \in A \wedge t_r = label^{-1}(R) \wedge (t, t_r) \in plays_{trans})$ [[`Role`]]

A type relates a role when the pair $(t, r)$ is in the $relates$ set directly (no inheritance yet)

* $MTypeProp$[[`relates Var`]] = $(\lambda V_2. \lambda V. \lambda A. \lambda K. (V, t) \in A \wedge (V_2, t_2) \in A \wedge (t, t_2) \in relates)$[[`Var`]] \
* $MTypeProp$[[`relates Role`]] = $(\lambda R. \lambda V. \lambda A. \lambda K. (V, t) \in A \wedge t_r = label^{-1}(R)) \wedge (t, t_r) \in relates)$ [[`Role`]]

A type can own another type when the pair $(t, t_a)$ is in the set $has_{trans}$ -- __--> TODO__ should this return KEY as well?

* $MTypeProp$[[`has Type`]] = $(\lambda L. \lambda V. \lambda A. \lambda K. (V, t) \in A \wedge t_a = label^{-1}(L) \wedge (t, t_a) \in has_{trans})$[[`Type`]]

A type has a type as a key if $(t, t_k)$ is in $key_{trans}$ (WRONG IMPL - returns HAS L as well)

* $MTypeProp$[[`key Type`]] = $(\lambda L. \lambda V. \lambda A. \lambda K. (V, t) \in A \wedge t_a = label^{-1}(L) \wedge (t, t_a) \in key_{trans})$[[`Type`]]


Not working, but needed in the language:

* var has var2      ====> retrieve types that can have attribute types represented by var2
* var key var2        ====> ( same but with key )


### Querying for Data instances

__--> TODO__ do we want to perform validation of the QUERY validity?

We define the following transitive isa set as a shorthand

* $isa_{trans} = \{ (i, t_p) \mid (t, t_p) \in sub^* \wedge (i, t) \in isa \}$ 

A Var own an attribute with some type if the owned attribute is of the required type (or a subtype) and the owning attribute $i$ and attr $a$ are in $has_D$

* $MDataProp$[[`has attrtype Var`]] = $(\lambda V_a. \lambda L. \lambda V. \lambda A. \lambda K. t_a = label^{-1}(L) \wedge (V_a, a) \in A \wedge (a, t_a) \in isa_{trans} \wedge (V, i) \in A \wedge (i, i_a) \in has_D$
==> Questions: do we want to validate V is a type that is allowed to have type of the instance mapped to attribute var?

An instance has a value when the variable mapping it exists such that $val(attr)$ is the intended value

* $MDataProp$[[`"VAL"`]] = $(\lambda D. \lambda V. \lambda A. \lambda K. (V, a) \in A \wedge val(a) = D)$[[`"VAL"`]]

__--> TODO__ roles and relations

* var ([var3/role]: var2)        ====> retrieve all pairs where var represents a concept related to another concept represented by var2, possibly restricted by a role

A Var representing $i$ is another type variable T mapped to $t$ when $(i, t)$ is in $isa_{trans}$

* $MDataProp$[[`isa Var`]] = $(\lambda V_t. \lambda V. \lambda A. \lambda K. (V_t, t) \in A \wedge (V, i) \in A \wedge (i, t) \in isa_{trans})$[[`Var`]]

A Var is represented by an ID $id$ when $id(i) = ID$. __--> TODO__ retrieve types by ID as well

* $MDataProp$[[`id ID`]] = $(\lambda d. \lambda V. \lambda A. \lambda K. (V, i) \in A \wedge id(i) = d)$[[`ID`]]
