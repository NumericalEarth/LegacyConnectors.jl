"""
    SoundingProfile <: AbstractVector{Float64}

A single vertical profile from a sounding — `(z, values)` plus the
surface value at `z = 0`. Subtypes `AbstractVector{Float64}` over the
*above-surface* portion, so indexing, iteration, broadcasting, and
plotting work exactly as they would for a plain `Vector{Float64}`.
The surface value lives outside the array (access via
`p.surface_value`) so it isn't accidentally swept into reductions.

A `SoundingProfile` also dispatches `set!(::Field, ::SoundingProfile)`
— that's how you fill a Breeze `Field` from a sounding column.

# Fields

- `z              :: Vector{Float64}`  — above-surface heights (m AGL), sorted ascending
- `values         :: Vector{Float64}`  — values at those heights (same length as `z`)
- `surface_value  :: Float64`          — the value at `z = 0`
- `name           :: Symbol`           — `:θ`, `:qv`, `:u`, or `:v`; used in errors and `show`
"""
struct SoundingProfile <: AbstractVector{Float64}
    z             :: Vector{Float64}
    values        :: Vector{Float64}
    surface_value :: Float64
    name          :: Symbol

    function SoundingProfile(z::Vector{Float64}, values::Vector{Float64},
                             surface_value::Real, name::Symbol)
        length(z) == length(values) || throw(ArgumentError(
            "SoundingProfile: z has length $(length(z)), values has length $(length(values))"))
        return new(z, values, Float64(surface_value), name)
    end
end

Base.size(p::SoundingProfile) = size(p.values)
Base.@propagate_inbounds Base.getindex(p::SoundingProfile, i::Int) = p.values[i]
Base.IndexStyle(::Type{SoundingProfile}) = IndexLinear()

function Base.show(io::IO, ::MIME"text/plain", p::SoundingProfile)
    print(io, "SoundingProfile(:", p.name, ", ", length(p), " levels, ",
          "surface=", round(p.surface_value; sigdigits = 5), ")")
end

"""
    Sounding

A vertical profile of an idealized atmosphere parsed from a legacy-model
sounding file. All quantities are in SI units after parsing.

# Fields

- `surface_pressure :: Float64` — Pa
- `θ, qv, u, v` — [`SoundingProfile`](@ref)s in K, kg/kg, m/s, m/s
- `format :: Symbol` — e.g. `:input_sounding`
- `source :: String` — original file path, used in error messages

`qv` may contain `NaN` at levels where the source file did not provide
a moisture value (e.g. mesospheric levels of a GFS point profile).

# Convenience accessors (via `Base.getproperty`)

- `s.surface_θ`, `s.surface_qv` → the surface values of the
  corresponding `SoundingProfile`s
- `s.z` → the shared above-surface height vector
  (`=== s.θ.z === s.qv.z === ...`)

`length(s)` returns the number of above-surface levels.
"""
struct Sounding
    surface_pressure :: Float64
    θ  :: SoundingProfile
    qv :: SoundingProfile
    u  :: SoundingProfile
    v  :: SoundingProfile
    format :: Symbol
    source :: String

    function Sounding(surface_pressure::Real,
                      θ::SoundingProfile, qv::SoundingProfile,
                      u::SoundingProfile, v::SoundingProfile,
                      format::Symbol, source::AbstractString)
        # All four profiles must share the same z vector (by value at least).
        for p in (qv, u, v)
            p.z == θ.z || throw(ArgumentError(
                "Sounding: profile :$(p.name) has a different z vector than :θ"))
        end
        length(θ) > 0 || throw(ArgumentError("sounding has no above-surface levels"))
        issorted(θ.z) || throw(ArgumentError(
            "sounding heights are not monotonically increasing"))
        return new(Float64(surface_pressure), θ, qv, u, v, format, String(source))
    end
end

Base.length(s::Sounding) = length(getfield(s, :θ))

function Base.getproperty(s::Sounding, name::Symbol)
    name === :surface_θ  && return getfield(s, :θ).surface_value
    name === :surface_qv && return getfield(s, :qv).surface_value
    name === :z          && return getfield(s, :θ).z
    return getfield(s, name)
end

Base.propertynames(::Sounding) = (:surface_pressure, :surface_θ, :surface_qv,
                                  :z, :θ, :qv, :u, :v, :format, :source)

function Base.show(io::IO, s::Sounding)
    print(io, "Sounding(", s.format, ", ", length(s), " levels, ",
          "p_sfc=", round(s.surface_pressure / 100; digits = 2), " mb, ",
          "θ_sfc=", round(s.surface_θ; digits = 2), " K, ",
          "qv_sfc=", round(s.surface_qv * 1000; digits = 2), " g/kg)")
end

"""
    Sounding(path::AbstractString; format::Symbol = :input_sounding) -> Sounding
    Sounding(name::Symbol)                                            -> Sounding

Construct a `Sounding` from a file path, or from the name of one of
the bundled examples (see [`example_sounding`](@ref) for the list).

`format` selects the on-disk format. Currently supported:

  - `:input_sounding` — the CM1/WRF/ERF text format (default).

```julia
s = Sounding("/path/to/input_sounding")     # from disk
s = Sounding(:weisman_klemp_1982)            # bundled example
```
"""
function Sounding(path::AbstractString; format::Symbol = :input_sounding)
    if format === :input_sounding
        return _read_input_sounding(path)
    else
        throw(ArgumentError(
            "Unknown sounding format $(repr(format)). Supported: :input_sounding."))
    end
end

Sounding(name::Symbol) = Sounding(example_sounding(name))

"""
    example_sounding(name::Symbol) -> String

Return the absolute path to one of the bundled example soundings:

  - `:weisman_klemp_1982` — analytic supercell sounding from
    Weisman & Klemp (1982); generated by `data/soundings/generate_weisman_klemp_1982.jl`.
  - `:kabq_radiosonde`    — observed KABQ (Albuquerque) radiosonde,
    2025-07-15 00Z; elevated surface, 95 levels.
  - `:abudhabi_gfs`       — GFS point forecast at Abu Dhabi,
    2025-07-15 12Z; 32 levels with `NaN` moisture aloft.
"""
function example_sounding(name::Symbol)
    file = if name === :weisman_klemp_1982
        "weisman_klemp_1982.txt"
    elseif name === :kabq_radiosonde
        "input_sounding_kabq_radiosonde_2025-07-15_00z.txt"
    elseif name === :abudhabi_gfs
        "input_sounding_abudhabi_gfs_2025-07-15_12z.txt"
    else
        throw(ArgumentError(
            "Unknown example sounding $(repr(name)). Available: " *
            ":weisman_klemp_1982, :kabq_radiosonde, :abudhabi_gfs."))
    end
    return joinpath(pkgdir(LegacyConnectors), "data", "soundings", file)
end
