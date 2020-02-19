
##Queries and their answers

####(TODO) Graph definition

#####Graph homomorphism
For graphs $G$ and $H$ defined over the same vocabulary, agraph homomorphism $G \rightarrow H$ is a mapping between their respective node sets that preserves edges and may decrease (specialise) labels.

#####Query interpretation
For a given knowledge graph $G$, we interpret a query $Q$ made to this graph as a graph. With this interpretation, for each answer $A_i$ to the query $Q$ there exists a homomorphism $\pi_i: Q \rightarrow G$, such that the answer is the image induced by that homomorphism:

$$
A_i = \pi_i Q \subseteq G
$$

such that it is a subgraph of $G$.

#####Query theory.subsumption:

If there is a homomorphism from a graph $G$ to a graph $H$, then $G$ is a generalization of $H$ and $G$ subsumes $H$.

#####Composition of homomorphisms is a homomorphism:
A graph $G$ is a generalization of a $H$ if there is a sequence of graphs $G_0 = H, G_1 , ..., G_n = G$, and, for all $i = 1, ... , n$, $G_i$ is obtained from $G_{i-1}$ by a generalization operation.

#####Key assumption
For two queries $Q$, $Q'$ such that there exists a homomorphism $\pi:Q \rightarrow Q'$ ($Q$ subsumes $Q'$), their respective answer sets $A=\{A_i\}$, $A'=\{A'_i\}$, satisfy the following condition:

$$
A'\subseteq A
$$ 

####Query operators

We now define pairs of query generalisation $\hat{G}$ and specialisation $\hat{S}$ operators such that in each pair the respective operators are inverses of each other:

$$
Q = \hat{G} Q' = \hat{S}^{-1}Q' \\
Q'' = \hat{S} Q' =  \hat{G}^{-1}Q'
$$

and such that the specialisation operators are query homomorphisms.


The following generalisation-specialisation operator pairs are defined:

 * **Generalise type** (inverse: specialise type) -> **NEEDS TYPE CONTEXT**

Increases label (Generalises) of the type of a previously typed variable. 
Includes:
    * **type deletion**: if the generalisation results in a meta type, the type is removed.
    * **role generalisation**: if the role to be generalised is a meta role, we make the role a variable

 * **Generalise attribute value** (inverse: specialise)
Generalises the value definition of a pre-existing attribute.

* **Remove link** (inverse: add link)
Includes:
  * **Remove roleplayer** (inverse: add roleplayer)
  * **Remove substitution** (inverse: add substitution)
  * **Remove attribute** (inverse: add attribute)
Removes an attribute requirement of a pre-attributed variable.
  * **Remove relation** (inverse: add relation)
  Removes a relation between 2 or more thins provided it doesn't make the resultant query disconnected.


####Inclusion of Rules

Addition of a rule can be understood as a generalisation operation for all queries:
- it's an equivalence operation for queries not affected by the rule (answer sets are unaltered)
- it's a generalisation operation for queries affected by the rule
Rule application can be seen as a process of introducing an extra disjunction into a query. If we have a query:

$$
Q(X) := p(X) \land  r(X)
$$
and introduce a rule:
$$
r(X) := body(X)
$$

Then the result of the rule application can be seen as a transformation of the query Q to:

$$
Q'(X) := p(X) \land ( r(X) \lor body(X) ) = Q(X) \lor ( p(X) \land body(X) )
$$

which is clearly a generalisation of the original query.

 