@testset "Bounds.jl" begin
    @testset "in" begin
        @test (1, 100) ∈ Bounds((0, 0), (10, 1000))
        @test (1, 1001) ∉ Bounds((0, 0), (10, 1000))
        @test (11, 100) ∉ Bounds((0, 0), (10, 1000))
        @test (0, 100)  ∈ Bounds((0, 0), (10, 1000))
        @test (1, 1000) ∉ Bounds((0, 0), (10, 1000))
    end

    @testset "Equality" begin
        @test Bounds((10, 20), (100, 200)) == Bounds((10, 20), (100, 200))
        @test Bounds((10, 20), (100, 200)) != Bounds((10, 20), (1000, 2000))
        @test Bounds((10 - 1E-15, 20.), (100., 200.)) != Bounds((10, 20), (100, 200))
        @test Bounds((10 - 1E-15, 20.), (100., 200.)) ≈ Bounds((10, 20), (100, 200))
        @test Bounds((10 - 1E-1,  20.), (100., 200.)) ≉ Bounds((10, 20), (100, 200))
    end

    @testset "intersect" begin
        @test Bounds((0, 0), (10, 10)) == Bounds((-10, -10), (10, 10)) ∩ Bounds((0, 0), (100, 100))
    end

    @testset "bounded" begin
        @test !bounded(Bounds((-Inf,), (3.,)))
        @test !bounded(Bounds((Inf,), (3.,)))
        @test bounded(Bounds((-3,), (3,)))
        @test bounded(Bounds((-3, 5, 1, 0), (3, 100, 2, 10)))
        @test !bounded(Bounds((-3., 5., 1., 0.), (3., 100., Inf, 10.)))
    end

    @testset "magnitude" begin
        @test [5, 20] == magnitude(Bounds((0, 0), (5, 20)))
        @test [5, 20] == magnitude(Bounds((-5, -20), (0, 0)))
        @test [5, 20, 10] == magnitude(Bounds((-5, -20, 0), (0, 0, 10)))

        @test 5 == magnitude(Bounds((0, 0), (5, 20)), 1)
        @test 5 == magnitude(Bounds((-5, -20), (0, 0)), 1)
        @test 5 == magnitude(Bounds((-5, -20, 0), (0, 0, 10)), 1)


        @test 20 == magnitude(Bounds((0, 0), (5, 20)), 2)
        @test 20 == magnitude(Bounds((-5, -20), (0, 0)), 2)
        @test 20 == magnitude(Bounds((-5, -20, 0), (0, 0, 10)), 2)

        @test 10 == magnitude(Bounds((-5, -20, 0), (0, 0, 10)), 3)
    end
end