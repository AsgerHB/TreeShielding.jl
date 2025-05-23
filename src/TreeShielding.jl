module TreeShielding

using Plots
using Unzip
using Printf
using Random
using StaticArrays
using Serialization
using AbstractTrees

export Bounds, get_dim, bounded, magnitude, middle
include("Bounds.jl")

export Tree, Node,  Leaf,  get_leaf,  get_value,  draw,  replace_subtree!,  split!,  get_bounds, shield, clear_reachable!, well_formed, no_orphans_in_cache
include("Trees.jl")

export robust_serialize, robust_deserialize
include("RobustSerialization.jl")

export ShieldingModel, 
    ReachabilityCaching, no_caching, one_way, dependency_graph, 
    Pruning, no_pruning, naïve, caap_reduction, 
    GrowMethod, caap_split, plus, minus, smart_minus, binary_search, binary_search_minus_fallback

include("ShieldingModel.jl")

export SupportingPoints, get_spacing_sizes
include("SuppotingPoints.jl")

export actions_to_int, int_to_actions
include("ActionConversion.jl")

export grow!, compute_safety
include("Grow.jl")

export update!, ValueUpdate
include("Update.jl")

export tree_from_bounds, even_split!, gridify!, set_safety!
include("TreeBuilding.jl")

export prune!
include("Prune.jl")

export synthesize!
include("Synthesize.jl")

export draw, draw_support_points!, scatter_outcomes!, scatter_supporting_points!, scatter_allowed_actions!, add_actions_to_legend, show_reachable!, show_incoming!
include("Plotting.jl")

module Environments

module RandomWalk
using Plots
export environment, rwmechanics, Pace, fast, slow, simulate, is_safe, draw_next_step!, draw_walk!, take_walk, evaluate
include("environments/RandomWalk.jl")
end#module RW

module BouncingBall
using Plots
using StatsBase
using Distributions
using Measures
export environment, bbmechanics, Action, hit, nohit, simulate_point, is_safe, simulate_sequence, evaluate, check_safety, animate_trace, random_policy
include("environments/BouncingBall.jl")
end#module BB

end#module Environments

end#module