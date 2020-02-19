# Graql Theorems

We write theorems about relationships between concepts that should always be true. For example,
when an instance isa type, and the type has a supertype, then the instance is also an instance of the supertype.

In general, we aim to write them as a sort of ```IF [STATEMENTS] THEN IS SATISFIED [CONDITIONS HOLD]```.

The idea is to produce assertions that are invariants over the knowledge graph.

Theorems will be READ assertions over the KG state.

Ultimately, it would be amazing to have the full proofs of these steps being valid: using the theory.semantics, we can translate the `match` queries into a set of constraints, such that the RHS constraints can be deduced from the LHS constraints. This would mean the implication is provably true in the theory.semantics, and the Grakn implementation is wrong if it does not.

## Invariant Theorems

These theorems should hold in ALL instances of knowledge graphs.

### Theorems for schema

* SUB is transitive
  * $A \models$ `match $x sub $y; $y sub $z; get;` $\implies A \models$ `match $x sub $z; get;`

* PLAYS is inherited
  * $A \models$ `match $x sub $y; $y plays $r; get;` $\implies A \models$ `match $x plays $r; get;`

* KEY is inherited
  * $A \models$ `match $x sub $y; $y key $a; get;` $\implies A \models$ `match $x key $a; get;`
    * TODO query schema for key and has with variables

* HAS returns KEYS as well
  * $A \models$ `match $x key $a; get;` $\implies A \models$ `match $x has $a; get;`
    * TODO query schema for key and has with variables

* HAS is inherited
  * $A \models$ `match $x sub $y; $y has $a; get;` $\implies A \models$ `match $x has $a; get;`
    * TODO query schema for key and has with variables

* RELATES is inherited
  * $A \models$ `match $x sub $y; $y relates $r; get;` $\implies A \models$ `match $x relates $r; get;`
    * TODO inheritance for relates

* REGEXes are only on strings
  * $A \models$ `match $a regex ???; get;` $\implies A \models$ `match $a datatype string; get;`
    * TODO query any attrs with a regex?

* Role AS role TODO

### Theorems for data + schema 

* ISA is transitive through the SUB hierarchy
  * $A \models$ `match $x isa $t; $t sub $p; get;` $\implies A \models$ `match $x isa $p; get;`

* KEY is unique
  * $A \models$ `match $t key $ta; $i isa $t; $k isa $ta; $i has $k; $i2 isa $t; $i2 has $k` $\implies A \models$ `match $i == $i2; get;`
    * this isn't so much as a theorem, as an axiom? Still worth testing

* ABSTRACT type has no non-abstract instances
  * $A \models$ `match $t abstract; $x isa $t; get;` $\implies A \models$ `match 

## Scenario Dependent Theorems

These scenarios are part of a larger sequence of steps that define a specific written context. 

A scenario can have `Operation` and `Theorem` steps, interwoven. These will be executed in order.

### Define-centric Theorems

Defining a basic schema and checking existance of implicit attribute ownership type

1. **Operation** - basic schema\
  `define person sub entity; child sub person; person has name; name sub attribute, datatype string;`
2. **Theorem** - schema elements exist \
  `match $x sub thing; get;` \
  satisfies \
  `match {$x type thing;} or {$x type entity;} or {$x type relation;} or {$x type attribute;} or {$x type person;} or {$x type child;} or {$x type name;}; get;`
3. **Operation** - create a person with a name \
  `insert $x isa person, has name "John";`
4. **Theorem** - schema elements include implicit attribute type \
  `match $x sub thing; get;` \
  satisfies \
  `match {$x type thing;} or {$x type entity;} or {$x type relation;} or {$x type attribute;} or {$x type person;} or {$x type child;} or {$x type name;} or {$x type @has-attribute;}; get;`


### Undefine-centric Theorems

Removing a subtype

1. **Operation** - basic schema \
  `define person sub entity; child sub person;`
2. **Theorem** - schema elements exist \
  `match $x sub thing; get;` \
  satisifes \
  `match {$x type thing;} or {$x type entity;} or {$x type person;} or {$x type child;} or {$x type relation;} or {$x type attribute;}; get;`
3. **Operation** - undefine child \
  `undefine child sub person;`
4. **Theorem** - schema elements do not include child \
  `match $x sub thing; get;` \
  satisifies \
  `match {$x type thing;} or {$x type entity;} or {$x type person;} or {$x type relation;} or {$x type attribute;}; get;`




## BDD Tests

```
Given [define/insert/match-delete]
Given ...
When match ... get ...
Then concepts satisfy match ... get ...
```