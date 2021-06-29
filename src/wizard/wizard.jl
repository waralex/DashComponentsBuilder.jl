function run_wizard()
    wizard = WizardState()
    while !wizard.is_done
        wizard.next_step(wizard)
    end

    printstyled("Thanks!\n", bold = true)
end