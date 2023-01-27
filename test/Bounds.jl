@testset "Bounds.jl" begin
    @testset "in" begin
        @test (1, 100) ∈ Bounds((0, 0), (10, 1000))
        @test (1, 100)  ∈ Bounds(Dict(2 => 0, 1 => 0), Dict(2 => 1000, 1 => 10))
        @test (1, 1001) ∉ Bounds((0, 0), (10, 1000))
        @test (11, 100) ∉ Bounds((0, 0), (10, 1000))
        @test (0, 100)  ∈ Bounds((0, 0), (10, 1000))
        @test (1, 1000) ∉ Bounds((0, 0), (10, 1000))
    end

    @testset "Equality" begin
        @test Bounds((10, 20), (100, 200)) == Bounds((10, 20), (100, 200))
        @test Bounds((10, 20), (100, 200)) != Bounds((10, 20), (1000, 2000))
        @test Bounds((10 - 1E-15, 20), (100, 200)) != Bounds((10, 20), (100, 200))
        @test Bounds((10 - 1E-15, 20), (100, 200)) ≈ Bounds((10, 20), (100, 200))
        @test Bounds((10 - 1E-1,  20), (100, 200)) ≉ Bounds((10, 20), (100, 200))
    end

    @testset "intersect" begin
        @test Bounds((0, 0), (10, 10)) == Bounds((-10, -10), (10, 10)) ∩ Bounds((0, 0), (100, 100))
    end
end