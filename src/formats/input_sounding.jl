# Parser for the CM1/WRF/ERF "input_sounding" text format.
#
# Format (whitespace-separated, "#" or ";" prefixed comments allowed):
#
#   Line 1: p_sfc(mb)   θ_sfc(K)   qv_sfc(g/kg)
#   Line N: z(m)        θ(K)       qv(g/kg)     u(m/s)   v(m/s)
#
# All quantities are converted to SI on read (mb → Pa, g/kg → kg/kg).
# `NaN` tokens are preserved in qv to support profiles whose source data
# does not extend moisture into the mesosphere.

function _read_input_sounding(path::AbstractString)
    isfile(path) || throw(ArgumentError("sounding file not found: $path"))

    p_sfc = θ_sfc = qv_sfc = NaN
    z  = Float64[]
    θ  = Float64[]
    qv = Float64[]
    u  = Float64[]
    v  = Float64[]

    surface_seen = false
    open(path, "r") do io
        for (lineno, raw) in enumerate(eachline(io))
            line = _strip_comment(raw)
            isempty(line) && continue
            tokens = split(line)
            if !surface_seen
                length(tokens) == 3 || throw(ArgumentError(
                    "$path line $lineno: surface line must have 3 columns " *
                    "(p[mb] θ[K] qv[g/kg]); got $(length(tokens))"))
                p_mb, θk, qv_gkg = _parse_floats(tokens, path, lineno)
                p_sfc  = p_mb * 100.0           # mb → Pa
                θ_sfc  = θk
                qv_sfc = qv_gkg * 1.0e-3        # g/kg → kg/kg
                surface_seen = true
            else
                length(tokens) == 5 || throw(ArgumentError(
                    "$path line $lineno: level line must have 5 columns " *
                    "(z[m] θ[K] qv[g/kg] u[m/s] v[m/s]); got $(length(tokens))"))
                zm, θk, qv_gkg, um, vm = _parse_floats(tokens, path, lineno)
                push!(z,  zm)
                push!(θ,  θk)
                push!(qv, qv_gkg * 1.0e-3)
                push!(u,  um)
                push!(v,  vm)
            end
        end
    end

    surface_seen || throw(ArgumentError("$path: file contains no surface line"))

    return Sounding(p_sfc, θ_sfc, qv_sfc, z, θ, qv, u, v,
                    :input_sounding, abspath(path))
end

function _strip_comment(line::AbstractString)
    # Trim "#"- or ";"-prefixed comments and surrounding whitespace.
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
