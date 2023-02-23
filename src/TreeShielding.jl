module TreeShielding

using Plots
using Unzip
using Printf
using Serialization
using AbstractTrees

export Bounds,  get_dim, bounded, magnitude
include("Bounds.jl")

export Tree, Node,  Leaf,   get_leaf,  get_value,  draw,  replace_subtree!,  split!,  get_bounds
include("Trees.jl")

export robust_serialize, robust_deserialize
include("RobustSerialization.jl")

export SupportingPoints, get_spacing_sizes
include("SuppotingPoints.jl")

export actions_to_int, int_to_actions
include("ActionConversion.jl")

export ShieldingModel
include("ShieldingModel.jl")

export Direction, safe_below_threshold, safe_above_threshold, get_split, compute_safety, get_dividing_bounds, get_threshold, try_splitting!, grow! 
include("Grow.jl")

export update!, ValueUpdate
include("Update.jl")

export tree_from_bounds, even_split!, gridify!, set_safety!
include("TreeBuilding.jl")

export prune!
include("Prune.jl")

export synthesize!
include("Synthesize.jl")

export draw, draw_support_points!, scatter_outcomes!, scatter_supporting_points!, scatter_allowed_actions!
include("Plotting.jl")


module RW
using Plots
export rwmechanics, Pace, simulate, draw_next_step!, draw_walk!, take_walk, evaluate
include("RWExample.jl")
end#module

module BB
using Plots
using StatsBase
export bbmechanics, Action, hit, nohit, simulate_point, simulate_sequence, evaluate, check_safety, animate_trace, random_policy
include("BBExample.jl")
end#module

end#module