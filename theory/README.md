# Grakn's (Private) Theory Repository

Currently being used for:

* Formal theory.semantics of Graql
* Axiomatic tests for Graql (in the form of "theorems" that should always hold)
* Subsumption specification: formal specialisation/generalisation of queries


## Generating Formatted Files
We use Pandoc (https://pandoc.org/installing.html) to generate PDF files from Markdown + Latex (for math). Will require also installing some Latex renderer, normally pdflatex, in your system for it to work.

Once installed, try for example:

1. `cd theory.semantics`
2. `pandoc -V geometry:margin=1in -o theory.semantics.pdf theory.semantics.md`

Will generate a file called `theory.semantics.pdf`

## Deveopment

Recommend using VSCode with `Markdown Preview Extended` plugin for rendering Latex math in a preview.

#### Style
For inline math we will use `$`. To ensure that pandoc does not error, there may NOT be errors right after the opening `$` or right before the closing `$`.