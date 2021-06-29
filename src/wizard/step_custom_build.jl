function step_custom_build!(state::WizardState)
    println("custom_build")
    state.is_done = true
end