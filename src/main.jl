# SPDX-License-Identifier: AGPL-3.0-only
# Copyright © 2025 Roy Chih Chung Wang <roy.c.c.wang@proton.me>

"""
    create_dashboard(
        state_labels::AbstractVector{<:AbstractString},
        state_colors::AbstractVector,
        row_labels::AbstractVector{<:AbstractString},
        col_IDs::AbstractVector{<:AbstractVector{<:Integer}},
        data_set::AbstractVector{<:AbstractMatrix{<:Real}},
        titles::AbstractVector{<:AbstractString};
        state_markers::Vector{Symbol} = collect(:circle for _ in 1:length(state_colors)),
        fig_size = (1920, 1080), # in pixels.
        background_rgb = (0.98, 0.98, 0.98),
    )

Returns a GLMakie figure, of type `Makie.Figure`.

Let `K` be the number of states (i.e., classes), where each point in the point set is associated with exactly one state (i.e., class). Let `D` be the dimension of each point, which could be a feature coordinate in data science applications.

inputs:

`data_set` contains the point set to be visualized. It is a length `K` array of matrices. `data_set[k]` is a matrix that contains all the points that are associated with state `k`. `data_set[k][d,n]` is the `d`-th coordinate of the `n`-th point in the points associated with state `k`.

`col_IDs` correspond to an integer ID for each column of the matrices in `data_set`. It is a length `K` array of arrays. This must be true for the inputs to be valid: `size(data_set[k], 2) == length(col_IDs[k])`.

`state_labels` is a length `K` array that contain the state description. Appears in the legend of the scatter plots.

`state_colors` is a length `K` array that specifies the GLMakie colors to be used for the points associated with each state.

`row_labels` is a length `D` array that contain the point dimension/coordinate descriptions. This could be the feature descriptions for a data science application.

`titles` is a length 2 array of string. It specifies the plot titles.

Optional inputs:

`state_markers` is a length `K` array that specifies the GLMakie markers to be used for the points associated with each state.

`fig_size` is (width, height) of the figure in pixels.

`background_rgb` is the (red, green, blue) value for the background color. Each value is between `0` (black) and `1` (white).

"""
function create_dashboard(
        state_labels::AbstractVector{<:AbstractString},
        state_colors::AbstractVector,
        row_labels::AbstractVector{<:AbstractString},
        col_IDs::AbstractVector{<:AbstractVector{<:Integer}},
        data_set::AbstractVector{<:AbstractMatrix{<:Real}},
        titles::AbstractVector{<:AbstractString};
        state_markers::Vector{Symbol} = collect(:circle for _ in 1:length(state_colors)),
        fig_size = (1920, 1080), # in pixels.
        background_rgb = (0.98, 0.98, 0.98),
    )

    num_plots = 2
    length(titles) == num_plots || error("The title string should have two entries.")

    length(state_labels) == length(state_colors) || error("Length mismatch.")
    length(col_IDs) == length(data_set) || error("Length mismatch.")

    length(row_labels) > 1 || error("row_labels must be at least 2. This package is for visualizing points that have dimension of at least 2.")

    for k in eachindex(data_set)
        length(row_labels) == size(data_set[k], 1) || error("Size mismatch.")
        length(col_IDs[k]) == size(data_set[k], 2) || error("Size mismatch.")
    end

    # # Setup figure
    r_val, g_val, b_val = background_rgb
    fig = Figure(
        backgroundcolor = RGBf(r_val, g_val, b_val),
        size = fig_size
    )

    # ## Plots
    g_plots = fig[1, :] = GridLayout()
    ax_plots = collect(
        Axis(
                g_plots[1, n],
                xlabel = row_labels[1],
                ylabel = row_labels[2],
                title = titles[n],
            )
            for n in 1:num_plots
    )

    # ### Menu: row_labels

    manu_labels = row_labels
    values = 1:length(manu_labels)
    labels = collect("$(m): $(manu_labels[m])" for m in eachindex(manu_labels))

    g_menu = fig[2, :] = GridLayout()
    menus = collect(
        Menu(
                g_menu[1, m],
                options = zip(labels, values),
                default = labels[min(m, length(labels))]
            )
            for m in 1:(2 * num_plots) # (x1, x1) per plot.
    )

    ax_observables = collect(Observable(1) for m in 1:(2 * num_plots)) # (x1, x1) per plot.

    # ## Callbacks

    # Render plot.
    # mutables = [ax_pr, ax_xics]
    function refresh_plot!(
            mutables,
            ax_observables,
            state_labels::AbstractVector{<:AbstractString},
            state_colors::AbstractVector,
            state_markers::AbstractVector{<:Symbol},
            row_labels::AbstractVector{<:AbstractString},
            col_IDs::AbstractVector{<:AbstractVector{<:Integer}},
            data_set::AbstractVector{<:AbstractMatrix{<:Real}},
            titles::AbstractVector{<:AbstractString},
        )

        # parse.
        ax_plots = mutables
        x1_observables = collect(ax_observables[m] for m in 1:2:length(ax_observables))
        x2_observables = collect(ax_observables[m] for m in 2:2:length(ax_observables))

        for i in eachindex(ax_plots, x1_observables, x2_observables, titles)

            empty!(ax_plots[i]) # reset plot.
            # g_texts[i].text[] = "default text $(i)"

            r1 = to_value(x1_observables[i])
            r2 = to_value(x2_observables[i])

            x_label = row_labels[r1]
            y_label = row_labels[r2]

            ax_plots[i].title[] = titles[i]

            for k in eachindex(data_set, state_colors, state_labels, col_IDs, state_markers)

                ax_plots[i].xlabel[] = x_label
                ax_plots[i].ylabel[] = y_label

                scatter!(
                    ax_plots[i],
                    view(data_set[k], r1, :),
                    view(data_set[k], r2, :),
                    col_IDs[k],
                    color = state_colors[k],
                    label = state_labels[k],
                    marker = state_markers[k]
                )
            end
            axislegend(ax_plots[i], position = :rb)
            DataInspector()
        end

        return nothing
    end

    # menus
    for m in eachindex(menus)
        on(menus[m].selection) do s
            ax_observables[m][] = s

            refresh_plot!(
                ax_plots,
                ax_observables,
                state_labels,
                state_colors,
                state_markers,
                row_labels,
                col_IDs,
                data_set,
                titles,
            )
        end
        notify(menus[m].selection)
    end

    return fig
end


nothing
