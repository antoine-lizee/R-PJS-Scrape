# cleanZombies.R
# Script to automatically kill any zombie process


# Clean previous zombie processes -----------------------------------------

res <- system('ps -axf | grep "\\_ /[h]ome/alizee/local_software/phantomjs/bin/phantomjs"', intern = T)
ids <- sub(pattern = " *([[:digit:]]*) .*", "\\1", res)
cat("\n##########\nCleaning", length(ids), "zombie process...\n########\n\n")
system(paste("kill", paste(ids, collapse = " ")))