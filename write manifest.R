# write manifest using rsconnect for POSIT deployment
# Load rsconnect package
library(rsconnect)

# Write manifest for the current directory
writeManifest(appDir = ".", appFiles = "app.R", appPrimaryDoc = NULL)
renv::snapshot()

