# Set-based definitions of Knowledge Graph

a Knowledge Graph ($KG$) is defined in two portions:

1. Schema
2. Data

Both of these can defined using sets and validated using FOL assertions, as follows.

## Set-based definitions of Schema

Let \
$Lab$ be the set of countably infinite unique labeling strings with notable elements $entity, relation, attribute, thing$. \
$Reg$ is the set of all valid regexes allowed by Java's regex system. \
$Datatype = \{bool, long, string, double, date\}$ is the set of datatypes allowed by Graql.

### Contents of a Graql Schema

A Graql Schema $S$ is composed of sets $Type, sub, has, key, plays, relates, abstract$ and functions $label, datatype, regex$:

* $Type$, a set of elements representing types, at least containing elements $t_{thing}$, $t_{entity}$, $t_{relation}$, $t_{attribute}$

* $sub \subseteq Type \times Type$ is a mapping for each element in $Type$ to a parent element in $Type$, creating a type hierarchy tree, at least containing pairs $(t_{entity}, t_{thing})$, $(t_{relation}, t_{thing})$, $(t_{attribute}, t_{thing})$.

  * Denote the transitive closure of $sub$ as $sub^* = \{ (x,z) \mid (x,y) \in sub \wedge (y,z) \in sub \}$

* Label convenience sets $Type_{Entity}$, $Type_{Relation}$, $Type_{Attribute}$ using $sub^*$:

  * $Type_{Entity} = \{x \mid (x, t_{entity}) \in sub^*(x) \}$
  * $Type_{Relation} = \{x \mid (x, t_{relation}) \in sub^*(x) \}$
  * $Type_{Attribute} = \{x \mid (x, t_{attribute}) \in sub^*(x) \}$

[ TODO do we want to include Roles using SUB or otherwise? ]

* $has \subseteq Type \times Type_{Attribute}$, the set of pairs representing allowed attribute ownership
* $key \subseteq has$, the subset of pairs representing allowed keys (also dictates that a type can't have a key and has for same target type)
* $plays \subseteq Type \times Type_{Role}$, the set of pairs representing roles played by types
* $relates \subseteq Type_{Relation} \times Type_{Role}$, the set of pairs representing roles related by relations
* $abstract \subseteq Type$, the set of types that are abstract, always including elements $t_{thing}$, $t_{entity}$, $t_{relation}$, $t_{attribute}$

Functions:

* $label: Type \mapsto Lab$ is a bijection, such that $label(t_{thing}) = thing$, $label(t_{entity}) = entity$, $label(t_{relation}) = relation$, $label(t_{attribute}) = attribute$.
  * Inverse function $label^{-1}$ maps labels back to types
* $datatype: Type_{Attribute} \mapsto Datatype$, total function mapping attributes to data type
* $regex: Type_{Attribute} \mapsto Reg$, a partial function mapping attributes to regex patterns


### Valid Schema

Not all sets, relations, and functions defined above are valid schemas.

A schema $S$ is **valid** if and only if the following conditions hold:


* $sub$ forms a tree rooted with $t_{thing}$
  * $\forall x \in KG.Type. (x,x) \not \in sub^*$ -- require no loops in the transitive closure of $sub$
  * $\forall x,y,z. (x,y) \in sub \wedge (x,z) \in sub \implies x = y$ -- require unique parents
  * $\forall x \exists y. (x,y) \in sub^* \implies y \in \{t_{entity}, t_{relation}, t_{attribute}\}$
 -- each type has a meta type as an
* All attribute types mapped to a regex must have datatype string
  * $\forall x. x \in dom(regex) \implies datatype(x) = string$
* special meta types can never be assigned to have, key, play or relate other types (only subtyped)
  * $\forall x \in \{t_{thing}, t_{entity}, t_{relation}, t_{attribute} \} \neg \exists y. (x,y) \in has \vee (x,y) \in plays \vee (x,y) \in relates$
* All roles played by some type must be related in a relation as well
  * $\forall (x,y) \exists z. (x,y) \in plays \implies (z,y) \in relates$
  * Note that the requirement, that relations must have at least one role related, is implicit in the definition of sets of pairs

## Set-based definition of Data

Let \
$Id$ be the countably infinite set of all unique IDs. \
$Val$ be the set of all attribute values for booleans, longs, strings, doubles and dates.\
ie. $Val = Bool \cup Double \cup String \cup Long \cup Date$ \
$Bool = {true, false}$ \
$Double = R$ - all real numbers \
$String = set \; of \; all \; strings$ \
$Date = set \; of \; all \; dates$

### Contents of Graql Data

An instance of Graql Data $D$ is composed of:

* $I$, a set of data instances (each instance is called a _concept_)

along with relations:

* $isa \subseteq I \times Type$, set of pairs representing the type of each concept
* $rel \subseteq I \times I \times Type_{Role}$, set of triples representing a concept in a relation playing a role
* $has_D \subseteq I \times I$, set of pairs representing concepts having attributes
* $key_D \subseteq has_D$, subset of $has_D$ that are keys, a restricted form of attribute ownership

and functions:

* $id: I \mapsto Id$, a total, surjective (one-to-one mapped) function identifying the ID of each concept
* $val: I \mapsto Val$, a partial function mapping concepts that are attributes to values


### Valid Graql Data

Not all sets, relations, and functions defined above are valid schemas.
We define helper sets over the schema $S$:
 
* $has_{trans} = \{ (t,pa) \mid (t, pt) \in sub^* \wedge (pt, a) \in has \}$
* $key_{trans} = \{ (t,pk) \mid (t, pt) \in sub^* \wedge (pt, k) \in key \}$
  * Note that $key_{trans} \subseteq has_{trans}$
* $plays_{trans} = \{ (t, rol) \mid (t, pt) \in sub^* \wedge (pt, rol) \in plays \}$ \

TODO relates should be listed as transitive, if not overriden with `as` in the future theory.semantics

A data instance $D$ is **valid** with respect to a Graql Schema $S$ if and only if the following conditions hold:

NOTE to self: in general, the instances stored must be flat ie. directly mapped types (no inheritance). However, whether it is valid depends on inheritance

* the $isa$ relation is unique
  * $\forall d \in I \exists t. (d, t) \in isa$
  * $\forall d, x, y. (d, x) \in isa \wedge (d, y) \in isa \implies x = y$
* $has_D$ contains pairs of data and attributes of compatible type
  * $\forall d, a, t_a. (d, a) \in has_d \wedge (a, t_a) \in isa \implies t_a \in Type_{attribute}$ -- can only own instances that have Attribute type
  * $\forall d, t_d, a, t_a. (d, a) \in has_d \wedge (d, t_d) \in isa \wedge (a, t_a) \in isa \implies (t_d, t_a) \in has_{trans}$ -- can only own instances of type allowed by the schema
* $key_D$ is similar to `has_D`, plus unique ownership restrictions
  * $\forall d, a, t_a. (d, a) \in key_D \wedge (a, t_a) \in isa \implies t_a \in Type_{attribute}$ -- can only key instances that have Attribute type
  * $\forall d, d', k, t. (d, k) \in key_D \wedge (d', k) \in key_D \wedge (d, t) \in isa \wedge (d', t) \in isa \implies d = d'$ -- two elements of the same type cannot have the same key
 * $\forall d, k, k', t. (d,k) \in key_d \wedge (d, k') \in key \wedge (k, t) \in isa \wedge (k', t) \in isa \implies k = k'$ -- an element can not have more than one key of the same type (?)
  * $\forall d, t_d, k, t_k. (d, k) \in key_d \wedge (d, t_d) \in isa \wedge (k, t_k) \in isa \implies (t_d, t_k) \in key_{trans}$ -- can only key instances of type allowed by the schema
  * $\forall d, t_d, t_k \exists k. (d, t_d) \in isa \wedge (t_d, t_k) \in key_{trans} \implies (k, t_k) \in isa \wedge (d, k) \in key_D$ -- every instance that is of a type that is associated with a key, must have a key
* Values are unique per attribute type
  * $\forall a, a', t_a, v, v'. (a, t_a) \in isa \wedge (a', t_a) \in isa \wedge val(a) = val(a') \implies a = a'$
* $rel$ Role constraints are satisfied
  * $\forall x, r, rol, t. (x, r, rol) \in rel \wedge (r, t) \in isa \implies t \in Type_{Relation}$ -- $rel$ follows type constraints
  * $\forall x, r, rol, rol'. (x, r, rol) \in rel \wedge (x, r, rol') \in rel \implies rol \neq rol'$ -- same concept plays different roles in a relation
  * $\forall x, r, rol, t_x, t_r. \ (x, r, rol) \in rel \wedge (x, t_x) \in isa \wedge (r, t_r) \in isa \wedge$ \ 
  $\implies  (t_x, rol) \in plays_{trans} \wedge (t_r, rol) \in relates$ -- the roles played/related are valid in the schema (`relates` is explicit, no need to check inheritance/transitivity)


## Graql Assertions

We can view the language `Graql` as operations over a given Knowledge Graph $KG$. Some operations modify the $KG$, producing a new $KG'$. Others are non-modifying and return some kind of answers from the $KG$ that satisfy the constraints entered.