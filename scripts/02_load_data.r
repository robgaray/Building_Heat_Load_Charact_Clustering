files.data <- list.files(paste(WD, "/data", sep=""))
Dat <- files.data[1]

# Read the data into a dataset
Dat <- read.csv(paste(WD, "/data/", Dat, sep=""), sep=";")
rm(files.data)

# Formatting of data frame
attach(Dat)
Dat$date <- paste(Year, Month, Day_Month, Hour_Day)
Dat$date <- as.POSIXct(Dat$date, tz = "GMT", format="%Y %m %d %H")
detach(Dat)

STRING_date <- "date"
VEC_vars <- c("Holiday", "Temperature", "Solar.Irradiation", "Power")

Dat <- RG_Date_Marks(Dat, STRING_date, VEC_vars)
rm(STRING_date, VEC_vars)