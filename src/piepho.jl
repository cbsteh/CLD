# Compact Letter Display (CLD) based on the insert-and-absorb (with sweeping) algorithm by:
# Piepho, H.-P. (2004). An Algorithm for a Letter-Based Representation of
#   All-Pairwise Comparisons. Journal of Computational and Graphical Statistics,
#   13(2), 456–466. doi:10.1198/1061860043515
# Adapted from Python: https://github.com/lfyorke/cld
# Original R code: https://rdrr.io/cran/multcomp/src/R/cld.R

const LETTERS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

function get_letters(n::Int)
    sz = length(LETTERS)
    complete = floor(Int, n / sz)
    partial = n % sz
    separ = ""
    letters = String[]

    if complete > 0
        for i ∈ 0:complete-1
            letters = vcat(letters, [separ * ch for ch ∈ LETTERS])
            separ *= "."
        end
    end

    if partial > 0
        letters = vcat(letters, [separ * ch for ch ∈ LETTERS[1:partial]])
    end

    letters
end


function prepare_initial_df(data, col1, col2, axb)
    unique_values = union(data[!, Symbol(col1)], data[!, Symbol(col2)])
    initial_col = ones(Int, length(unique_values))
    DataFrame(Symbol(axb) => unique_values, Symbol("initial_col") => initial_col)
end


function dup_and_merge(df, axb, signif_1, signif_2, cols_to_dup)
    df1 = select(df, axb, cols_to_dup)
    df2 = select(df, axb, cols_to_dup)
    df3 = select(df, axb, Not(cols_to_dup))

    df1[df1[!, axb] .== signif_1, 2:end] .= 1
    df1[df1[!, axb] .== signif_2, 2:end] .= 0
    df2[df2[!, axb] .== signif_1, 2:end] .= 0
    df2[df2[!, axb] .== signif_2, 2:end] .= 1

    nm = names(df1)
    rename!(df1, vcat(nm[1], nm[2:end] .* "_x"))
    rename!(df2, vcat(nm[1], nm[2:end] .* "_y"))
    innerjoin(df1, df2, df3, on=axb)
end


function process_sig_diff(df, signifs, col1, col2, axb)
    data = copy(df)
    for i ∈ 1:size(signifs, 1)
        signif_1 = signifs[i, Symbol(col1)]
        signif_2 = signifs[i, Symbol(col2)]
        test = filter(axb => c -> c .== signif_1 || c .== signif_2, data)
        cols_to_dup = [col for col ∈ propertynames(test)[2:end] if sum(test[!, col]) == 2]
        data = dup_and_merge(data, axb, signif_1, signif_2, cols_to_dup)
        letters = Symbol.(get_letters(length(names(data))-1))
        rename!(data, vcat(axb, letters))
    end
    data
end


function insert(df, col1, col2, sig, axb)
    new_df = prepare_initial_df(df, col1, col2, axb)
    signifs = df[df[!, Symbol(sig)] .== true, :]

    if !any(df[!, Symbol(sig)])
        groups = get_letters(1)
        new_df[!, groups[1]] .= 1
        select!(new_df, Not(:initial_col))
        return new_df
    end

    process_sig_diff(new_df, signifs, col1, col2, axb)
end


function absorb(df)
    cols = names(df)
    data = collect(eachcol(df))
    groups = OrderedDict(zip(cols[2:end], data[2:end]))

    dups = String[]
    ks = collect(keys(groups))
    vs = collect(values(groups))
    lvs = length(vs)

    for i ∈ 1:lvs
        for j ∈ (i+1):lvs
            (vs[i] != vs[j]) && continue
            push!(dups, ks[i])
            break
        end
    end

    dups
end


function init_check_locked(pairs)
    check = Dict{Tuple{Int, Int}, Int}()
    lock_idx = Dict{Tuple{Int, Int}, Tuple{String, Int}}()
    for pair ∈ pairs
        check[pair] = 0
        lock_idx[pair] = ("", 0)
    end
    check, lock_idx
end


function sweep(df)
    cols = names(df)[2:end]
    data = copy(df)
    locked = copy(df)
    locked[!, cols] .= 0

    for col ∈ cols
        col_to_sweep = data[!, col][data[!, col] .== 1]
        tmp = select(data, Not(col))

        index = findall(==(1), data[!, col])

        for i ∈ index
            pairs = [(i, x) for x ∈ index if x != i]

            isempty(pairs) && continue

            check, lock_idx = init_check_locked(pairs)

            for tmp_col ∈ names(tmp)
                for pair ∈ pairs
                    (locked[!, tmp_col][pair[1]] == 1) && break

                    if tmp[!, tmp_col][pair[1]] == 1 && tmp[!, tmp_col][pair[2]] == 1
                        check[pair] = 1
                        lock_idx[pair] = (col, pair[2])
                    elseif check[pair] == 0
                        break
                    end
                end
            end

            un = unique(values(check))
            !(length(un) == 1 && un[1] == 1) && continue

            data[!, col][collect(keys(check))[1][1]] = 0

            for (keys, values) ∈ lock_idx
                column_to_lock = values[1]
                index_to_lock = values[2]
                locked[!, column_to_lock][index_to_lock] = 1
            end
        end
    end

    data
end


function sort_by_col(df)
    df_copy = select(df, 2:size(df, 2))

    nrows, ncols = size(df_copy)
    already_switched_col = Int[]
    counter = 1
    new_col_idx = collect(1:ncols)

    for i ∈ 1:nrows
        is_col_value = [df_copy[i, j] == 1 for j ∈ 1:ncols]

        !any(is_col_value) && continue

        for new_idx ∈ findall(is_col_value)
            (new_idx in already_switched_col) && continue

            new_col_idx[counter] = new_idx
            push!(already_switched_col, new_idx)
            counter += 1
        end
    end

    not_switched_col = setdiff(1:ncols, already_switched_col)
    for new_idx ∈ not_switched_col
        new_col_idx[counter] = new_idx
        counter += 1
    end

    result_df = hcat(df[:, 1], df_copy[:, new_col_idx])
    rename!(result_df, 1 .=> names(df)[1])
end


function raw_table(df, col1, col2, sig, axb)
    new_df = insert(df, col1, col2, sig, axb)
    dups = absorb(new_df)
    !isempty(dups) && select!(new_df, Not(dups))

    df = sweep(new_df)
    dups = absorb(df)
    !isempty(dups) && select!(df, Not(dups))

    sz = size(df, 2)
    letters = string.(get_letters(sz-1))
    rename!(df, 2:sz .=> letters)
end


function cld_letters(df::AbstractDataFrame;
                     col1::Symbol=:col1, col2::Symbol=:col2,
                     sig::Symbol=:sig, axb::Symbol=:AxB)
    cld_df = raw_table(df, col1, col2, sig, axb)

    ord_letters = names(cld_df)
    sorted_cld_df = sort_by_col(cld_df)
    rename!(sorted_cld_df, ord_letters)

    df = DataFrame(tempname=String[], LETTERS=String[])
    rename!(df, :tempname=>axb)

    for i ∈ 1:nrow(sorted_cld_df)
        grp = sorted_cld_df[i, 1]
        letters = ""
        for col ∈ ord_letters[2:end]
            (sorted_cld_df[i, col] != 1) && continue
            letters *= col
        end
        push!(df, (grp, letters))
    end

    df
end
