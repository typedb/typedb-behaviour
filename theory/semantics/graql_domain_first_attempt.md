# Graql Semantics

Basic operations:

$Define: WriteConstraints \rightarrow KG \rightarrow KG$

$Undefine: WriteConstraints \rightarrow KG \rightarrow KG$

$Insert: Answer \rightarrow WriteConstraints \rightarrow KG \rightarrow ?? $

$Delete: Answer \rightarrow WriteConstraints \rightarrow KG \rightarrow KG$

$Match: ReadConstraints \rightarrow KG \rightarrow Answer$

We need to define the domains $Answer$ and $Constraints$.

$Answer = \Pi_{n=0}^{n=\infty} (Var, (T \cup I))$

$WriteConstraints = \wp (WriteConstraint)$ \
$WriteConstraint = KG \rightarrow Bool$ 

$ReadConstraints = \wp (ReadConstraint)$ \
$ReadConstraint = Answer \rightarrow KG \rightarrow Bool$
