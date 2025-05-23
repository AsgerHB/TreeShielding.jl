using Test
using Unzip
using TreeShielding
using TreeShielding.Environments.RandomWalk
using AbstractTrees

RW = TreeShielding.Environments.RandomWalk

@testset "TreeShielding.jl" begin
    include("Trees.jl")
    include("SupportingPoints.jl")
    include("ActionConversion.jl")
    include("Bounds.jl")
    include("Update.jl")
    include("GrowBinarySearch.jl")
end
