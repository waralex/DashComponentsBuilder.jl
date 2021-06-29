function step_type_choose!(state::WizardState)
    msg = "\t\t\t# Choose source type\n\n"
    printstyled(msg, bold=true)

    menu = RadioMenu(["PyPi package", "GitHub repository"], pagesize=3)
    choice = request("Choose components package source:", menu)
    if choice == 1
        state.next_step = step_obtain_pypi!
    else
        state.next_step = step_obtain_source!
    end
end
