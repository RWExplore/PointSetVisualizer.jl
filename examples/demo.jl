using Random, BenchmarkTools

using Revise
import PointSetVisualizer as VZ

const T = Float64
rng = Random.Xoshiro(0)

num_states = 3
state_labels = ["healthy state"; "cancer state"; "infected state"]
state_colors = ["red"; "green"; "orange"]
state_markers = [:circle; :rect; :diamond]

D = 5
row_labels = collect("feature coordinate $(d)" for d in 1:D)

function generate_col_IDs(rng::AbstractRNG, ::Type{T}, num_states::Integer, N::Integer) where {T <: AbstractFloat}
    state_list = collect(rand(rng, 1:num_states) for _ in 1:N)

    col_IDs = collect(
        findall(xx -> xx == k, state_list) for k in 1:num_states
    )
    while any(isempty(x) for x in col_IDs) # generate again such that we have at least one point for each state.

        state_list = collect(rand(rng, 1:num_states) for _ in 1:N)
        col_IDs = collect(
            findall(xx -> xx == k, state_list) for k in 1:num_states
        )
    end

    return state_list, col_IDs
end
num_pts = 1000
state_list, col_IDs = generate_col_IDs(rng, T, num_states, num_pts)
data_set = collect(randn(rng, T, D, length(x)) .+ (10 * randn(rng, T)) for x in col_IDs)

title_strings = ["Plot 1"; "Plot 2"]

fig = VZ.create_dashboard(
    state_labels,
    state_colors,
    row_labels,
    col_IDs,
    data_set,
    title_strings;
    state_markers = state_markers,
)

display(fig)

nothing
