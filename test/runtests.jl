using TreeShielding
using Test
using Unzip

@testset "TreeShielding.jl" begin
    include("Trees.jl")
    include("SupportingPoints.jl")
    include("ActionConversion.jl")
    include("Bounds.jl")
end
