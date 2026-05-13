using Documenter
using LegacyConnectors
using Literate

# ---- Literate processing ---------------------------------------------------
#
# Each example in `examples/` is a runnable Julia script with
# Literate-formatted comments. We process them with the Documenter
# flavor and `execute=true` so the generated Markdown contains the
# rendered figures and printed return values, exactly as if the user
# ran the script themselves.

const REPO_ROOT     = joinpath(@__DIR__, "..")
const EXAMPLES_DIR  = joinpath(REPO_ROOT, "examples")
const LITERATED_DIR = joinpath(@__DIR__, "src", "literated")

isdir(LITERATED_DIR) && rm(LITERATED_DIR; recursive = true)
mkpath(LITERATED_DIR)

examples = [
    "weisman_klemp_supercell.jl" => "Weisman & Klemp supercell",
    "kabq_radiosonde.jl"         => "KABQ radiosonde",
    "abudhabi_gfs.jl"            => "Abu Dhabi GFS profile",
    "breeze_field.jl"            => "Sounding → Breeze Field",
]

example_pages = Pair{String,String}[]
for (script, title) in examples
    src = joinpath(EXAMPLES_DIR, script)
    Literate.markdown(src, LITERATED_DIR;
                      flavor   = Literate.DocumenterFlavor(),
                      execute  = true,
                      credit   = false)
    md = "literated/" * replace(script, ".jl" => ".md")
    push!(example_pages, title => md)
end

# ---- Documenter ------------------------------------------------------------

DocMeta.setdocmeta!(LegacyConnectors, :DocTestSetup, :(using LegacyConnectors); recursive=true)

makedocs(
    sitename = "LegacyConnectors.jl",
    modules  = [LegacyConnectors],
    authors  = "NumericalEarth organization and contributors",
    format   = Documenter.HTML(;
        canonical = "https://numericalearth.github.io/LegacyConnectors.jl",
        edit_link = "main",
        assets    = String[],
    ),
    pages = [
        "Home"            => "index.md",
        "Sounding format" => "format.md",
        "Examples"        => example_pages,
        "API reference"   => "api.md",
    ],
    warnonly = [:missing_docs],
)

deploydocs(
    repo          = "github.com/NumericalEarth/LegacyConnectors.jl.git",
    devbranch     = "main",
    push_preview  = true,
)
