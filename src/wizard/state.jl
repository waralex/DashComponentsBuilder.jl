Base.@kwdef mutable struct WizardState
    build_state::BuildState = init_buildstate()
    next_step ::Function = step_type_choose!
    builder ::Union{DockerBuilder, Nothing} = nothing
    recipe ::Union{Recipe, Nothing} = nothing
    is_done ::Bool = false
end