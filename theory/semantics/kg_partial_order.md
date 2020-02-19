# Defining the Partial Order $\sqsubseteq$ for $KG$

We have a domain $KG$ that is a graph-like structure partitioned into schema and data.

As an example, we want to define an ordering relation between two elements from the domain $KG$. As much simplified example, we can consider a simple graph of vertices and edges.

### Simple Example 

$G1 = (V1, E1)$ \
$V1 = \{1,2,3,4\}$ \
$E1 = \{(1,2), (2,3)\}$ \

$G2 = (V2, E2)$ \
$V2 = \{1,2,3,4\}$ \
$E2 = \{(1,2), (2,3), (3,4)\}$
 
$G3 = (V3, E3)$ \
$V3 = \{1,2,3,4\}$ \
$E3 = \{(4,1), (1,2)\}$

$G4 = (V4, E4)$ \
$V4 = \{1,2\}$ \
$E4 = \{\}$

$G5 = (V5, E5)$ \
$V5 = \{1,2,3\}$ \
$E5 = \{(1,2), (2,3), (1,3)\}$

$G4 \sqsubseteq G1 \sqsubseteq G2$

$G1 \sqsubseteq G3 \wedge G1 \sqsubseteq G3$, so $G1 = G3$

$G4 \sqsubseteq G5$

Otherwise G5 is not comparable to the other graphs

### $KG$ Partial Order

