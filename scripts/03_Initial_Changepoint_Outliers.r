# Create a data frame with the parameters of changepoint models for each hour of the week
Changepoint_Pars_summ_TOW <- data.frame(
  DATE_hour_week = sort(unique(Dat$DATE_hour_week)),
  slope_Temp = rep(NA, length(unique(Dat$DATE_hour_week))),
  slope_Irrad = rep(NA, length(unique(Dat$DATE_hour_week))),
  intercept = rep(NA, length(unique(Dat$DATE_hour_week))),
  minimum = rep(NA, length(unique(Dat$DATE_hour_week)))
)

# Update data frame with final format
Dat$Power_fitted <- rep(NA, nrow(Dat))
Dat$Power_residuals <- rep(NA, nrow(Dat))
Dat$IS_Outlier <- rep(NA, nrow(Dat))

# Empty dataframe for output
Dat.output <- Dat[0,]

# Subset by hour of the week
for (i in Changepoint_Pars_summ_TOW$DATE_hour_week) {
  Dat.subs.hw <- Dat[Dat$DATE_hour_week == i,]
  
  # Get the optimal changepoint function parameters for each subset
  opt <- RG_Detect_Outlier_Model_Based_Ch_3P(Dat.subs.hw, 1.96, 50, 100)
  
  Dat.subs.hw <- opt[[1]]
  Dat.output <- rbind(Dat.output, Dat.subs.hw)
  
  Changepoint_Parameters_i <- opt[[2]]
  Changepoint_Pars_summ_TOW[Changepoint_Pars_summ_TOW$DATE_hour_week == i, 2:5] <- Changepoint_Parameters_i
}

# Reorder output dataframe by date
Dat <- Dat.output[order(Dat.output$DATE),]

rm(Dat.output, opt, Changepoint_Parameters_i, Dat.subs.hw, i)

# rename output
Changepoint_Pars_summ_TOW1<-Changepoint_Pars_summ_TOW
rm(Changepoint_Pars_summ_TOW)

# Write to file
setwd(paste(WD, "output", sep="/"))
write.csv(Changepoint_Pars_summ_TOW1,"03_Changepoint_Pars_summ_TOW1.csv")
setwd(WD)
