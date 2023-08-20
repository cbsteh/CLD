using CLD
using CSV, DataFrames


df = CSV.read("data/example3.csv", DataFrame)
cld_df = cld_letters(df, axb=:trt)
sort(cld_df, :LETTERS)
