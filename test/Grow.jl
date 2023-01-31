@testset "Grow.jl" begin
    @testset "get_splitting_point" begin
        points_safe = [
            ((1, 1), true),
            ((2, 1), false),
            ((3, 1), false),

            ((1, 2), true),
            ((2, 2), false),
            ((3, 2), true),
            
            ((1, 3), true),
            ((2, 3), true),
            ((3, 3), true),
        ]

        margin = 0.5

        @test 0.5 == get_splitting_point(points_safe, 1, margin)
        @test 2.5 == get_splitting_point(points_safe, 2, margin)
    end
end