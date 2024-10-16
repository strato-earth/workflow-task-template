main <- function() {
  tryCatch({
    # Get the runtime environment variable (or default to 'unknown')
    runtimeEnv <- Sys.getenv("RUNTIME_ENV", "unknown")
    msg <- paste("Hello from", runtimeEnv, "!")
    cat(msg, "\n")
    
    # Get command-line arguments
    args <- commandArgs(trailingOnly = TRUE)
    
    # Print command-line arguments if any were passed
    if (length(args) > 0) {
      cat("Received the following arguments:\n")
      for (i in seq_along(args)) {
        cat(paste("Argument", i, ":", args[i]), "\n")
      }
    } else {
      cat("No arguments were passed.\n")
    }
    
    return(0)
    
  }, error = function(e) {
    cat("Error processing environment variables:", e$message, "\n")
    return(1)
  })
}

# Call the main function
main()
