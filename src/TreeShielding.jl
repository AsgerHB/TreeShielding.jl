module TreeShielding

using Plots
using AbstractTrees

export Bounds,  get_dim, bounded, magnitude
include("Bounds.jl")

export Tree, Node,  Leaf,   get_leaf,  get_value,  draw,  replace_subtree!,  split!,  get_bounds
include("Trees.jl")

export SupportingPoints, get_spacing_sizes
include("SuppotingPoints.jl")

export actions_to_int, int_to_actions
include("ActionConversion.jl")

export compute_safety, safety_bounds, get_dividing_bounds, get_threshold, try_splitting!, grow! 
include("Grow.jl")

export update!
include("Update.jl")

export tree_from_bounds, even_split!, gridify!, set_safety!
include("TreeBuilding.jl")

export prune!
include("Prune.jl")

export synthesize!
include("Synthesize.jl")


module RW
using Plots
export rwmechanics, Pace, simulate, draw_next_step!, draw_walk!, take_walk, evaluate
include("RWExample.jl")
end#module

end#module