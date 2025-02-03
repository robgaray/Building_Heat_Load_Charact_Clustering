# Load libraries
#
# NOTE. By default, this script works on the main library directory. And only requires to install a few libraries.
# NOTE. Alternatively, it is possible to set a custom directory for the libraries.
# NOTE. This alternative leads to a substantially longer execution time.

{
  ruta_librerias<- paste(WD, "/librerias", sep="")
  
  # Use this if the installation of local libraries is problematic
  # i.e. in an HPC environment
  # .libPaths(c(ruta_librerias, .libPaths()))
  
  required_libraries <- c("lubridate", "GA", "rlang",
                          "lifecycle", "Metrics", "extrafont",
                          "ggplot2", "dplyr", "zoo",
                          "tidyr", "tidyverse", "cluster",
                          "factoextra", "NbClust", "utils",
                          "rpart", "rpart.plot", "caret")
  
  for (library in required_libraries) {
    # Use this if the installation of local libraries is problematic
    # i.e. in an HPC environment
    # if (!require(library,
    #              character.only = TRUE,
    #              lib.loc = ruta_librerias)) {
    #   install.packages(library,
    #                    dependencies = TRUE,
    #                    repos='http://cran.us.r-project.org',
    #                    lib=ruta_librerias)
    #   }       
    #   library(library,
    #           character.only = TRUE,
    #           lib=ruta_librerias)
    
    if (!require(library,
                 character.only = TRUE)) {
      install.packages(library,
                       dependencies = TRUE,
                       repos='http://cran.us.r-project.org')
    }
    library(library,
            character.only = TRUE)
  }
  rm(library, required_libraries, ruta_librerias)
}

# Set seed
set.seed(123)

# Load functions
files.source <- list.files(paste(WD, "/functions", sep=""))
for (i in seq_along(files.source)) {
  source(paste(WD, "/functions/", files.source[i], sep=""))  
}
rm(files.source, i)  