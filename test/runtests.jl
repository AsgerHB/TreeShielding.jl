using Test
using Unzip
using TreeShielding
using TreeShielding.RW
using AbstractTrees

@testset "TreeShielding.jl" begin
    include("Trees.jl")
    include("SupportingPoints.jl")
    include("ActionConversion.jl")
    include("Bounds.jl")
    include("Update.jl")
    include("Grow.jl")
end
