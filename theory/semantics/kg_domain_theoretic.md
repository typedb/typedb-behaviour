# Domain Theoretic definitions of Knowledge Graph

### Definition of CPOs and Domains

A Continuous Partial Order is composed of: 

* a Set 
* an ordering relation

We must prove 

1. the ordering relation $\sqsubseteq$ is a partial order
2. All chains in the set ordered via $\sqsubseteq$ have least upper bound. 

For the CPO to be a domain, we also need to prove there is a least element.

## Knowledge Graph Domain $KG$

The domain $KG$ is:

$KG = Schema \times Data$

where $Schema$ and $Data$ are also domains to be defined.

We have operations on $KG$:

$init: KG$ -- an empty knowledge graph, $\bot \in KG$

$addType: T \rightarrow KG \rightarrow KG$ \
$existsType: T \rightarrow KG \rightarrow Bool$ \
$addHas: T \rightarrow T \rightarrow KG \rightarrow KG$ \
$addKey: T \rightarrow T \rightarrow KG \rightarrow KG$ \
$addRelates: T \rightarrow T \rightarrow Role \rightarrow KG \rightarrow KG$ \
$addPlays: T \rightarrow Role \rightarrow KG \rightarrow KG$ \
$addRegex: T \rightarrow Regex \rightarrow KG \rightarrow KG$ \
$addAbstract: T \rightarrow KG \rightarrow KG$ \
$addPlays: T \rightarrow Role \rightarrow KG \rightarrow KG$ 

$removeType: T \rightarrow KG \rightarrow KG$ \
$...$

$addInstance: I \rightarrow KG \rightarrow KG$ \
$addIsa: I \rightarrow T \rightarrow KG \rightarrow KG$ \
$addHasData: I \rightarrow I \rightarrow KG \rightarrow KG$ \
$addKeyData: I \rightarrow I \rightarrow KG \rightarrow KG$ \
$addRel: I \rightarrow I \rightarrow Role \rightarrow KG \rightarrow KG$ 

$removeInstance: I \rightarrow KG \rightarrow KG$ \
$...$

Domains that are also used:

$Label =$ set of all strings

$Role =$ set of all strings

$Regex =$ set of all valid Java regexes

## Subdomains

We have above used the domains $Schema$ and $Data$.

### domain: $Schema$

We define the domain(?) $Schema$:

$Schema = Types \times Sub \times Has \times Key \times Plays \times Relates \times Abstract$ \
$addType: Schema \rightarrow Schema$ \
$addHas: Schema \rightarrow Schema$ \
...

Set $T$ is the set of all strings including "thing", "entity", "attribute", "relation"

Domain $Types = \wp (T)$. \
Domain $Sub = \wp (T \times T)$ \
Domain $Has = \wp (T \times T)$ \
Domain $Key = \wp (T \times T)$ \
Domain $Plays = \wp (T \times T)$ \
Domain $Relates = \wp (T \times T)$ \
Domain $Abstract = \wp (T)$ \

To make these into posets, we could for example in $Types$ define the $\sqsubseteq$ to be either $\subseteq$ or $A,B \in Types. A \sqsubseteq B \iff |A| < |B|$. TODO which is useful?

The least element $\bot$ is the tuple of empty tuples.

### domain: $Data$

We define the domain $Data$:

$Data = Instances \times Isa \times Rel \times Has_D \times Key_D \times Val$

Set $I = Naturals$

Set $Values = all possible strings, longs, doubles, dates, and booleans$

Domain $Instances = \wp (I)$.  \
Domain $Isa = \wp (I \times T)$ \
Domain $Rel = \wp (I \times I \times T)$ \
Domain $Has_D = \wp (I \times I)$ \
Domain $Key_D = \wp (I \times I)$ \

Domain $Val = I \rightarrow Values$



To make Posets on these domains, we would have to define $\sqsubseteq$... ?

For $Instances$, we can define the $\sqsubseteq$ to be either $\subseteq$ or $A,B \in Instances. A \sqsubseteq B \iff |A| < |B|$. TODO which is useful?



## Valid KG

A KG is valid iff the Schema and Data is valid

We define the function $valid_{schema} : Schema \rightarrow Bool$

$valid_{schema}(S) = $
```
let types = S[0] in
let sub = S[1] in
let has = S[2] in
let key = S[3] in
let plays = S[4] in
let relates = S[5] in
let abstract = S[6] in
validSub(types, sub) && validMeta && validDatatype && validRoles

# check tree conditions sub relation
validSub(types, sub) =
  let sub* = non self-referring transitive closure of sub in
  for all x in types, (x,x) not in sub*   &&
  for all x,y,z in types, if (x,y) in sub and (x,z) in types then y = z  &&
  for all x in types, (x, "entity) in sub* or (x, "relation") in sub* or (x, "attribute") in sub*;

etc.
```


We define the function $valid_{data} : Data \rightarrow Bool$

$valid_{data}(D) = $
```
let instances = D[0] in
let isa = S[1] in
let rel = S[2] in
let has = S[3] in
let key = S[4] in
validIsa(instances, isa) && 
  validHasData &&
  validKeyData &&
  validUniqueValues &&
  validRelates


# check tree conditions sub relation
validIsa(instances, isa) =
...

etc.
```


### Notes on `Validity`

If we can construct the operations on the domain $Schema$ such that we can always prove that resulting $Schema'$ maintains validity properties (via rule? structural? induction), then we never need to check `valid()` for anything, as we can only create valid schema and data

## Partial Ordering $\sqsubseteq$

We define $KG_1 \sqsubseteq KG_2$ iff there exists a homomorphism from $KG_1$ to $KG_2$.


# KG completion

We can define the $completion: KG 
\rightarrow KG$ as the fixed point of the application of all deductive inference rules in the Schema.

TODO this is not modeled yet.

However, intuitively, we can imagine that the completion of a KG is another KG that is the fixed point of some computation $complete(KG)$.

To prove that this has an answer we need properly defined domains with a least element ($\bot$), a partial ordering between KG's, as above.

TODO: do we have to prove that there is a LUB for the partial function $complete(KG)$?