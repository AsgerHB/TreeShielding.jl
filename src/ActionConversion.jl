"""
    actions_to_int(actions)

Convert a set of actions to a single integer, using bit-encoding. Actions will be cast to `Int`, so use a type that allows this. For example ints or enums..

**Warning:** Duplicates will lead to undefined behaviour. 
"""
function actions_to_int(actions)
	init = 0
	sum(2^(Int(action)) for action in actions; init)
end

# https://discourse.julialang.org/t/convert-integer-to-bits-array/26663/7
function get_bit_vector(u)
	result = BitVector(undef, sizeof(u)*8)
	result.chunks[1] = u%UInt64 # Seems to assume a 64-bit int. Sensible enough.
	result
end

"""
    int_to_actions(action_type, int::Number)

Convert an integer created using `actions_to_int` back into a set of actions.
"""
function int_to_actions(action_type, int)
	[action_type(i-1) for (i, value) in enumerate(get_bit_vector(int))
		if value]
end
