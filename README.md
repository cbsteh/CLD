
# Compact Letter Display (CLD) in Julia

## Overview
Compact letter display is used to report results of pairwise comparisons among treatment means in comparative experiments, so that means with the same letter are not significantly different from one another according to some level of statistical significance (typically 5%).

The CLD in Julia is based on the insert-and-absorb algorithm by Piepho (2004). This code also includes the additional step of the sweeping algorithm to ensure there are no redundant letters.

## Usage
Clone the repo by

```
https://github.com/cbsteh/CLD.git
```

The most important Julia source file is the `piepho.jl`, which contains the CLD algorithm. An example data file `example3.csv` is included as test.

## Example
In Piepho (2004) paper, there is Example 3 which comprised 8 treatments: T1 to T8, with five significant pairwise comparisons: T1 vs T7, T1 vs T7, T2 vs T4, T2 vs T5, and T3 vs T5. So, prepare the following `CSV` file, named `example3.csv`:

```
col1,col2,sig
T1,T2,FALSE
T1,T3,FALSE
T1,T4,FALSE
T1,T5,FALSE
T1,T6,FALSE
T1,T7,TRUE
T1,T8,TRUE
T2,T3,FALSE
T2,T4,TRUE
T2,T5,TRUE
T2,T6,FALSE
T2,T7,FALSE
T2,T8,FALSE
T3,T4,FALSE
T3,T5,TRUE
T3,T6,FALSE
T3,T7,FALSE
T3,T8,FALSE
T4,T5,FALSE
T4,T6,FALSE
T4,T7,FALSE
T4,T8,FALSE
T5,T6,FALSE
T5,T7,FALSE
T5,T8,FALSE
T6,T7,FALSE
T6,T8,FALSE
T7,T8,FALSE
```
where `col1` and `col2` represent the two columns for every pairwise comparison, and `sig` is either `TRUE` (for significant) or `FALSE` (for non-siginficant). The boolean for `sig` is case-insensitive, e.g., `true` and `false` are valid values, too.

Then, call read the `CSV` file as a `DataFrame`:

```
using CLD
using CSV, DataFrame


df = read("data/example3.csv", DataFrame)
```

Finally, pass the `df` DataFrame into `cld_letters` function:

```
cld_df = cld_letters(df, axb=:trt)

8×2 DataFrame
 Row │ trt     LETTERS
     │ String  String
─────┼─────────────────
   1 │ T1      abc
   2 │ T2      cd
   3 │ T3      ad
   4 │ T4      ae
   5 │ T5      be
   6 │ T6      ade
   7 │ T7      def
   8 │ T8      def
```

You can sort `cld_df` based on `LETTERS` column to arrange the treatments based on the letters as:

```
sort(cld_df, :LETTERS)

8×2 DataFrame
 Row │ trt     LETTERS
     │ String  String
─────┼─────────────────
   1 │ T1      abc
   2 │ T3      ad
   3 │ T6      ade
   4 │ T4      ae
   5 │ T5      be
   6 │ T2      cd
   7 │ T7      def
   8 │ T8      def
```

## API

```
cld_letters(df::AbstractDataFrame; col1::Symbol, col2::Symbol, sig::Symbol, axb::Symbol)
```

where:

`col1` and `col2` are the names of the left and right parts of the pair (defaults: `:col1` and `col2`)

`sig` is the name of the significant column (default: `:sig`)

`axb` is the name of the treatment column for the CLD `DataFrame` (default: `:AxB`).

## References
[Piepho, H.-P. (2004). An Algorithm for a Letter-Based Representation of All-Pairwise Comparisons. Journal of Computational and Graphical Statistics, 13(2), 456–466. doi:10.1198/1061860043515](https://doi.org/10.1198/1061860043515)

[Adapted from Python code](https://github.com/lfyorke/cld)

[Original R code](https://rdrr.io/cran/multcomp/src/R/cld.R)
