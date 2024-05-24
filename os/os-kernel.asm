kernel_begin:
    # Initialize kernel data structures
    # Set up interrupt vector table
    # Enable interrupts

    # Enter main loop (scheduler)
    j main_loop



main_loop:
    # Check for ready processes
    # Save current process state (if any)
    # Load next process state
    # Switch to next process
    
    j main_loop


