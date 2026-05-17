# Parser for the CM1/WRF/ERF "input_sounding" text format.
#
# Format (whitespace-separated, "#" or ";" prefixed comments allowed):
#
#   Line 1: p_sfc(mb)   θ_sfc(K)   qᵛ_sfc(g/kg)
#   Line N: z(m)        θ(K)       qᵛ(g/kg)     u(m/s)   v(m/s)
#
# All quantities are converted to SI on read (mb → Pa, g/kg → kg/kg).
# `NaN` tokens in qᵛ are preserved to support profiles whose source data
# does not extend moisture into the mesosphere.
#
# The parser builds a column `RectilinearGrid` whose cell centers sit
# exactly at the file's z-levels (with the surface at z = 0 as the
# bottom-most cell center), then allocates four `Field{Nothing, Nothing,
# Center}` profile fields populated with the parsed values. See the
# `Sounding` docstring for the layout.

using Breeze: RectilinearGrid, Field, CPU
using Breeze: Face, Flat, Bounded

function _read_input_sounding(path::AbstractString)
    isfile(path) || throw(ArgumentError("sounding file not found: $path"))

    p_sfc = θ_sfc = qᵛ_sfc = NaN
    z_above = Float64[]
    θ_above = Float64[]
    q_above = Float64[]
    u_above = Float64[]
    v_above = Float64[]

    surface_seen = false
    open(path, "r") do io
        for (lineno, raw) in enumerate(eachline(io))
            line = _strip_comment(raw)
            isempty(line) && continue
            tokens = split(line)
            if !surface_seen
                length(tokens) == 3 || throw(ArgumentError(
                    "$path line $lineno: surface line must have 3 columns " *
                    "(p[mb] θ[K] qᵛ[g/kg]); got $(length(tokens))"))
                p_mb, θk, qᵛ_gkg = _parse_floats(tokens, path, lineno)
                p_sfc  = p_mb * 100.0
                θ_sfc  = θk
                qᵛ_sfc = qᵛ_gkg * 1.0e-3
                surface_seen = true
            else
                length(tokens) == 5 || throw(ArgumentError(
                    "$path line $lineno: level line must have 5 columns " *
                    "(z[m] θ[K] qᵛ[g/kg] u[m/s] v[m/s]); got $(length(tokens))"))
                zm, θk, qᵛ_gkg, um, vm = _parse_floats(tokens, path, lineno)
                push!(z_above, zm)
                push!(θ_above, θk)
                push!(q_above, qᵛ_gkg * 1.0e-3)
                push!(u_above, um)
                push!(v_above, vm)
            end
        end
    end

    surface_seen || throw(ArgumentError("$path: file contains no surface line"))
    length(z_above) > 0 || throw(ArgumentError("$path: file has no above-surface levels"))
    issorted(z_above) || throw(ArgumentError(
        "$path: above-surface z column is not monotonically non-decreasing"))

    # Build a column grid whose z-faces are exactly the sounding levels:
    # face[1] = 0 (the surface), face[k+1] = z_above[k].  The grid has
    # `length(z_above)` cells and the profile `Field{Nothing, Nothing, Face}`
    # has `length(z_above) + 1` values — one per face.
    z_faces = vcat(0.0, z_above)
    grid = _column_grid(z_faces)

    θ_field  = _column_field(grid, vcat(θ_sfc,  θ_above))
    qᵛ_field = _column_field(grid, vcat(qᵛ_sfc, q_above))
    # input_sounding has no separate surface u, v line; CM1 uses the
    # lowest-level wind as the surface value.
    u_field  = _column_field(grid, vcat(u_above[1], u_above))
    v_field  = _column_field(grid, vcat(v_above[1], v_above))

    return Sounding(p_sfc,
                    θ_field, qᵛ_field, u_field, v_field,
                    :input_sounding, abspath(path))
end

"""
    _column_grid(z_faces) -> RectilinearGrid

Build a column `RectilinearGrid` whose z-faces are exactly `z_faces`.
`Face`-located fields on this grid carry one value per face — which is
how we represent a sounding column: the file's z levels (with `0.0`
prepended for the surface) become the face positions, and the values
parsed off each line land at the matching face.
"""
function _column_grid(z_faces::Vector{Float64})
    N_cells = length(z_faces) - 1
    return RectilinearGrid(CPU(); size = N_cells, z = z_faces,
                           topology = (Flat, Flat, Bounded))
end

function _column_field(grid, values::Vector{Float64})
    f = Field{Nothing, Nothing, Face}(grid)
    @inbounds for k in eachindex(values)
        f[1, 1, k] = values[k]
    end
    return f
end

function _strip_comment(line::AbstractString)
    for marker in ('#', ';')
        idx = findfirst(==(marker), line)
        idx === nothing || (line = SubString(line, 1, idx - 1))
    end
    return strip(line)
end

function _parse_floats(tokens, path, lineno)
    return ntuple(length(tokens)) do i
        tok = tokens[i]
        v = tryparse(Float64, tok)
        v === nothing && throw(ArgumentError(
            "$path line $lineno column $i: cannot parse $(repr(tok)) as Float64"))
        v
    end
end
