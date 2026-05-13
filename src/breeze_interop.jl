# Breeze.jl interop for `Sounding` values.
#
# The functions in this file are deliberately thin — they translate a
# format-neutral `Sounding` into the shapes Breeze expects, and otherwise
# defer to Breeze's existing utilities (`ReferenceState`, `interpolate!`,
# `set!`). See Breeze.jl discussion #672 for the motivating proposal.

import Breeze

"""
    LegacyConnectors.reference_state(sounding::Sounding; grid)

Build a Breeze `ReferenceState` (hydrostatic base state in pressure,
density, and Exner function) by interpolating the sounding's θ, qv onto
`grid` and integrating hydrostatically from `sounding.surface_pressure`.

!!! note
    This function is a v0.1 scaffold that delegates to Breeze's existing
    `ReferenceState` constructor once the per-grid θ/qv profiles are
    assembled. Tighter integration (e.g. iterative refinement following
    the approach suggested by E. Quon in NumericalEarth/Breeze.jl#672)
    is tracked as future work.
"""
function reference_state end

"""
    LegacyConnectors.set!(model, sounding::Sounding; perturbation=nothing)

Initialize a Breeze model's prognostic fields (θ, qv, u, v) from
`sounding`, interpolating each profile onto the model grid. If
`perturbation` is given, it is applied additively after interpolation
(see Breeze's perturbation utilities, e.g. warm bubbles or random
temperature noise).

!!! note
    The v0.1 implementation is a scaffold; consult the docs for the
    current status of Breeze coupling.
"""
function set! end
