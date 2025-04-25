#!/usr/bin/env julia
#title      : get_mol_files
#description: Get MOL files for KEGG COMPOUNDS
#author     : Carlos Vigil-Vásquez
#date       : 20250406
#version    : 20250406a
#notes      : Requires instantiation of project before using (`julia --project=. -e "using Pkg; Pkg.instantiate()`)
#copyright  : Copyright (C) 2025 Carlos Vigil-Vásquez  (carlos.vigil.v@gmail.com)
#license    : Permission to copy and modify is granted under the MIT license

using Pkg
if basename(pwd()) != "kegg-small"
    error("Not in correct directory")
end
Pkg.activate(".")

VERSION = "20250406a"

println(basename(@__FILE__()) * " - v$VERSION")
t0 = time()

using ArgParse
using JSON
using KEGGAPI
using ProgressMeter

# Helpers {{{1
function KEGGAPI.kegg_get(query::Vector{String}, option::String, retries::Int)
    i = 0
    while i < retries
        try
            return KEGGAPI.kegg_get(query, option)
        catch e
            if occursin("404", string(e))
                error(e)
            elseif occursin("403", string(e))
                i += 1
                sleep(10)
            end
        end
    end
    return
end

function safe_mkdir(path)
    if !isdir(path)
        @info "Creating `$path` directory"
        mkdir(path)
    else
        @info "Found output directory `$(path)`, skipping creation"
    end
    return true
end
# }}}

function main(args)
    # Argument parsing
    settings = ArgParseSettings()

    add_arg_group!(settings, "I/O option:")
    @add_arg_table! settings begin
        "-i"
        help = "List of KEGG COMPOUND codes to download"
        arg_type = String
        action = :store_arg
        required = true
        "-d", "--delimiter"
        help = "List delimiter (default: `\n`)"
        arg_type = String
        default = "\n"
        action = :store_arg
        "-o"
        help = "Output directory (default: `./data/molfiles`)"
        arg_type = String
        action = :store_arg
        required = false
        default = "./data/molfiles/"
    end
    args = parse_args(args, settings)

    # Create output directory
    @assert safe_mkdir(args["o"])

    # Get MOL file for compounds and convert to InCHI
    # NOTE: DO NOT PARALLELIZE THIS STEP, IT WILL ERROR OUT AND LOCK YOU OUT OF USING THE KEGG API
    allcpd = open(args["i"], "r") do f
        return String.(split(String(read(f)), args["delimiter"], keepempty = false))
    end
    @info "Requesting MOL files for $(length(allcpd)) compounds..."
    return @showprogress for batch in collect(Iterators.partition(allcpd, 10))
        try
            sleep(0.4)
            result = KEGGAPI.kegg_get(String.(batch), "mol", 5)
            batch_mol = split(result[2][1], "\$\$\$\$\n", keepempty = false)
            map(zip(batch, batch_mol)) do (cpd, mol)
                try
                    open(args["o"] * cpd * ".mol", "w+") do f
                        write(f, string(mol))
                    end
                catch e
                    # NOTE: Polymers (and some molecules) fail to convert due to them having an atom
                    # of type "R" (repetition).
                    @warn "Failed to save '$cpd': $e"
                end
            end
        catch e
            @warn e
        end
    end
end

main(ARGS)
