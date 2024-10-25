# Get assembly index of target `t`
function assembly_index(t; return_visited = false) # aka "Main"
    substruct_dic = Dict{String, Int64}()
    A, visited = _assembly_index(t, String[], substruct_dic)
    if return_visited
        return A, visited
    else
        return A
    end
end

# Function calculating the assembly index of a compound `s`
function _assembly_index(s, visited, dictionary) # aka "AssemblyIndex"
    if s in visited
        # no construction cost for previously visited compounds
        return 0, visited
    elseif haskey(dictionary, s)
        return dictionary[s], [visited; s] 
    elseif length(s) <= 3
        # strings of length <= 3 can only be constructed in a set amount of combinations
        return length(s) - 1, [visited; s]
    else
        # not yet visited "complex" compound => split into substructures
        substructure_pairs = getsubstructures(s)

        As = Vector{Int64}(undef, length(substructure_pairs))
        visiteds = Vector{Vector{String}}(undef, length(substructure_pairs))

        for (sp_idx, sp) in enumerate(substructure_pairs)
            A1, visited11 = _assembly_index(sp[1], visited, dictionary)
            A2, visited12 = _assembly_index(sp[2], [visited11; sp[1]], dictionary)
            sum1 = A1 + A2 + 1

            A2, visited22 = _assembly_index(sp[2], visited, dictionary)
            A1, visited21 = _assembly_index(sp[1], [visited22; sp[2]], dictionary)
            sum2 = A1 + A2 + 1
            if sum1 < sum2
                As[sp_idx] = sum1
                visiteds[sp_idx] = [visited12; sp[2]]
            else
                As[sp_idx] = sum2
                visiteds[sp_idx] = [visited21; sp[1]]
            end
        end

        min_idx = argmin(As)
        dictionary[s] = As[min_idx]
        return As[min_idx], visiteds[min_idx]
    end
end

function getsubstructures(s)
    return [[s[1:i], s[i+1:end]] for i in 1:(length(s)-1)]
end

assembly_index("BANANA", return_visited = true)
assembly_index("ABRACADABRA", return_visited = true)
assembly_index("CADABRA", return_visited = true)
# # tests
assembly_index("AAAA") == 2
assembly_index("BANANA") == 4
assembly_index("redrumredrumredrumredrumredrumredrumredrumredrumredrumredrum") # still takes too long

# # timing

@time assembly_index("AAA")
@time assembly_index("BANANA")
@time assembly_index("ABNNNBA")