"""
    LegacyConnectors

Readers and adapters that let Breeze.jl ingest initial conditions from
legacy atmospheric modeling formats (CM1, WRF, ERF, …).

The public API for v0.1:

  - [`Sounding`](@ref): a vertical profile container constructible
    directly from a path — `Sounding("/path/to/file")` — or from the
    name of one of the bundled examples — `Sounding(:weisman_klemp_1982)`.
  - [`SoundingProfile`](@ref): a single column (θ, qv, u, or v) plus
    its surface value; subtypes `AbstractVector{Float64}` and dispatches
    `set!(::Field, ::SoundingProfile)` for Breeze interop.
  - [`reference_state`](@ref): build a Breeze `ReferenceState` from a
    `Sounding`.

Three example soundings are bundled in `data/soundings/` and discoverable
via [`example_sounding`](@ref).
"""
module LegacyConnectors

export Sounding, SoundingProfile, example_sounding

include("soundings.jl")
include("formats/input_sounding.jl")
include("breeze_interop.jl")

end # module
