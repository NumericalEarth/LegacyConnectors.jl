"""
    LegacyConnectors

Readers and adapters that let Breeze.jl ingest initial conditions from
legacy atmospheric modeling formats (CM1, WRF, ERF, …).

The public API:

  - [`Sounding`](@ref): a concretely-typed container whose four profile
    fields are `Field{Nothing, Nothing, Center}` on a column grid.
    Constructible from a path (`Sounding("/path/to/file")`) or a bundled
    example name (`Sounding(:weisman_klemp_1982)`).
  - `Oceananigans.Fields.interpolate!(target, sounding.potential_temperature)` —
    the verb for filling a 3-D model `Field` from a column profile.
    Handled natively by Oceananigans ≥ 0.107.5.
  - [`reference_state`](@ref): build a `Breeze.ReferenceState` from a
    `Sounding`.

Three example soundings are bundled in `data/soundings/` and discoverable
via [`example_sounding`](@ref).
"""
module LegacyConnectors

export Sounding, example_sounding

include("soundings.jl")
include("formats/input_sounding.jl")
include("breeze_interop.jl")

end # module
