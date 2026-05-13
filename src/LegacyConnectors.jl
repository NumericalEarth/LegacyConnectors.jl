"""
    LegacyConnectors

Readers and adapters that let Breeze.jl ingest initial conditions from
legacy atmospheric modeling formats (CM1, WRF, ERF, …).

The public API for v0.1 is:

  - [`Sounding`](@ref): a neutral container for a vertical profile
    (z, θ, qv, u, v) plus surface state.
  - [`read_sounding`](@ref): parse a file in a known format.
  - [`set!`](@ref): apply a `Sounding` to a Breeze model.
  - [`reference_state`](@ref): build a Breeze `ReferenceState` from a
    `Sounding`.

Three example soundings are bundled in `data/soundings/` and discoverable
via [`example_sounding`](@ref).
"""
module LegacyConnectors

export Sounding, read_sounding, example_sounding

include("soundings.jl")
include("formats/input_sounding.jl")
include("breeze_interop.jl")

end # module
