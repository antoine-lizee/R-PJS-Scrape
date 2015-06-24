## Logging method for R scripts
# This uses calling handlers for warnings, and exiting handlers for the finally.
#
# Copyright Antoine Lizee 02/2015 antoine.lizee@gmail.com


# Utilities ---------------------------------------------------------------

# Taken from testthat @ Hadleym cf BIOPROD code
create_traceback <- function(callstack) {
  if (length(callstack) == 0) return()
  max_lines <- getOption("deparse.max.lines", Inf)
  
  # Convert to text
  calls <- lapply(callstack, deparse, width = getOption("width"))
  if (is.finite(max_lines)) {
    calls <- lapply(calls, function(x) x[seq_len(min(length(x), max_lines))])
  }
  calls <- vapply(calls, paste0, collapse = "\n", FUN.VALUE = character(1))
  
  # Extract srcrefs
  srcrefs <- lapply(callstack, attr, "srcref")
  has_ref <- !vapply(srcrefs, is.null, logical(1))
  files <- vapply(srcrefs[has_ref], function(x) attr(x, "srcfile")$filename,
                  FUN.VALUE = character(1))
  lines <- vapply(srcrefs[has_ref], function(x) as.vector(x)[1],
                  FUN.VALUE = integer(1))
  
  calls[has_ref] <- paste0(calls[has_ref], " at ", files, ":", lines)
  
  # Number and indent
  calls <- paste0(seq_along(calls), ": ", calls)
  calls <- gsub("\n", "\n ", calls)
  calls
}

# Setup error log ---------------------------------------------------------

executWithErrorSignaling <- function(expr) {
  tryCatch({ # needed for the finally exiting handler
    cat("# KAYAK scraping script run as", system("whoami", intern = T), "on", format(t0 <- Sys.time()) ,"...\n")
    withCallingHandlers(expr, 
                        error = function(e) {
                          cat("### ERROR:\n", gettext(e), paste(create_traceback(e), collapse = "\n"), "\n####\n") # "\n", as.character(traceback(e)), ## PROBLEM : this stack trace printed at error evaluation.
                        }, 
                        warning = function(w) {
                          cat("### WARNING:\n", w$message, "\n####\n")
                        })},
    error = function(e) {invisible(e)},
    finally = {
      cat("## Completed script in ", format(Sys.time() - t0),", exiting now. Thank you!\n\n*******************\n\n\n", sep = "")
    })                   
}


# Test --------------------------------------------------------------------

if (test.B <- F) {
  print(
    executWithErrorSignaling({
      print(2+2)
      warning("YO")
      print(5+5)
      stop("DAMN!")
      4+4
    })
  )
}
