# Heat Load Analysis
# Author: Roberto Garay Martinez

# This R script performs the analysis of the heat load patterns of a building

# The sample data provided is a 1-year data for a multi-rise building connected to the District Heating Network in Tartu (Estonia).
# The data consists of hourly values of heat load, ambient temperature, and solar radiation over a horizontal plane.
# The data sources are: GREN EESTI (heat load) and the UNIVERSITY OF TARTU (weather data).



# Initiation -----------------------------------------------------------------
{
  # Get the working directory
  WD <- getwd()
  
  # Load libraries and functions
  setwd(paste(WD,"/scripts",sep=""))
  source("01_initiation.r", echo = TRUE) 
  setwd(WD)
}

# Load data files ------------------------------------------------------------
{
  setwd(paste(WD,"/scripts",sep=""))
  source("02_load_data.r", echo = TRUE) 
  setwd(WD)
}

# Initial Changepoint model and outlier detection ----------------------------
{
  setwd(paste(WD,"/scripts",sep=""))
  source("03_Initial_Changepoint_Outliers.r", echo = TRUE) 
  setwd(WD)
}

# Inspection of the changepoint model ----------------------------------------
{
  setwd(paste(WD,"/scripts",sep=""))
  source("04_Inspection_Changepoint_Outliers.r", echo = TRUE) 
  setwd(WD)
}

# Repair of dataset ----------------------------------------------------------
{
  setwd(paste(WD,"/scripts",sep=""))
  source("05_Fill_data.r", echo = TRUE)
  setwd(WD)
}

# Inspection of repair -------------------------------------------------------
{
  setwd(paste(WD,"/scripts",sep=""))
  source("06_Inspection_Fill_Data.r", echo = TRUE)
  setwd(WD)
}

# Final changepoint model ----------------------------------------------------
{
  setwd(paste(WD,"/scripts",sep=""))
  source("07_Final_Changepoint_Model.r", echo = TRUE)
  setwd(WD)
}

# Clusterization -------------------------------------------------------------
{
  setwd(paste(WD,"/scripts",sep=""))
  source("08_Clusterization.r", echo = TRUE)
  setwd(WD)
}

# CART -----------------------------------------------------------------------
{
  setwd(paste(WD,"/scripts",sep=""))
  source("09_CART.r", echo = TRUE)
  setwd(WD)
}

# Changepoint model for clusters ---------------------------------------------
{
  setwd(paste(WD,"/scripts",sep=""))
  source("10_Changepoint_Clusters.r", echo = TRUE)
  setwd(WD)
}

# Statistics & Comparison
{
  setwd(paste(WD,"/scripts",sep=""))
  source("11_Statistics_Graphics.r", echo = TRUE)
  setwd(WD)  

}

# End of script

# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
# Break point for environment saving and loading -----------------------------
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
# setwd(paste(WD,"/environments",sep=""))
# save.image(file = "working_environment.RData")
# setwd(WD)
# 
# WD <- getwd()
# setwd(paste(WD,"/environments",sep=""))
# load(file = "working_environment.RData")
# setwd(WD)
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------