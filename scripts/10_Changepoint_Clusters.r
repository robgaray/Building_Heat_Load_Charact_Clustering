# Add cluster information to Dat &
# remove incomplete cases (those without cluster information) into Dat_clean
{
  # Add a new column extracting only the date (without time) from the DATE variable
  # To be used as index
  Dat <- Dat %>%
    mutate(Date_full = DATE) %>%
    mutate(DATE = as.Date(DATE))
  
  Dat <- merge(Dat, Dat_day_CART[, c("DATE", "cluster", "cluster_PRED")], by = "DATE", all.x = TRUE)
  
  # Remove the new column extracting only the date (without time) from the DATE variable
  # no longer needed.
  Dat$DATE<-Dat$Date_full
  Dat <- Dat %>%
    select(-Date_full)
  
  # Code cluster+hour information
  Dat$ClusterHour <- as.numeric(Dat$cluster)*100+Dat$DATE_hour_day
  Dat$ClusterHour_PRED <- as.numeric(Dat$cluster_PRED)*100+Dat$DATE_hour_day
  
  # remove observations without cluster
  Dat_clean<-Dat[complete.cases(Dat),] 
}

# Process with clusters as identified
{
  # Create a data frame with the parameters of changepoint models for each cluster
  Changepoint_Pars_summ_CLUST <- data.frame(
    ClusterHour = sort(unique(Dat_clean$ClusterHour)),
    slope_Temp = rep(NA, length(unique(Dat_clean$ClusterHour))),
    slope_Irrad = rep(NA, length(unique(Dat_clean$ClusterHour))),
    intercept = rep(NA, length(unique(Dat_clean$ClusterHour))),
    minimum = rep(NA, length(unique(Dat_clean$ClusterHour)))
  )
  
  # Update data frame with final format
  Dat$Power_fitted <- rep(NA, nrow(Dat))
  Dat$Power_residuals <- rep(NA, nrow(Dat))
  Dat$IS_Outlier <- rep(NA, nrow(Dat))
  
  # Empty dataframe for output
  Dat.output <- Dat[0,]
  
  for (i in Changepoint_Pars_summ_CLUST$Cluster) {
    Dat.subs.clust <- Dat_clean[Dat_clean$ClusterHour == i,] 
    
    # Get the optimal changepoint function parameters for each subset
    opt <- RG_Detect_Outlier_Model_Based_Ch_3P(Dat.subs.clust, 1.96, 50, 100)
    
    Dat.subs.clust <- opt[[1]]
    Dat.output <- rbind(Dat.output, Dat.subs.clust)
    
    Changepoint_Parameters_i <- opt[[2]]
    Changepoint_Pars_summ_CLUST[Changepoint_Pars_summ_CLUST$ClusterHour == i, 2:5] <- Changepoint_Parameters_i
  }  
  
  # Reorder output dataframe by date
  Dat_clean <- Dat.output[order(Dat.output$DATE),]
  Dat_clean$Power_fitted_ClustH<-Dat_clean$Power_fitted
  
  rm(Dat.output, opt, Changepoint_Parameters_i, Dat.subs.clust, i)
}

# Process with clusters as predicted by the CART process
{
  # Create a data frame with the parameters of changepoint models for each cluster
  Changepoint_Pars_summ_CLUST_PRED <- data.frame(
    ClusterHour_PRED = sort(unique(Dat_clean$ClusterHour_PRED)),
    slope_Temp = rep(NA, length(unique(Dat_clean$ClusterHour))),
    slope_Irrad = rep(NA, length(unique(Dat_clean$ClusterHour))),
    intercept = rep(NA, length(unique(Dat_clean$ClusterHour))),
    minimum = rep(NA, length(unique(Dat_clean$ClusterHour)))
  )
  
  # Update data frame with final format
  Dat$Power_fitted <- rep(NA, nrow(Dat))
  Dat$Power_residuals <- rep(NA, nrow(Dat))
  Dat$IS_Outlier <- rep(NA, nrow(Dat))
  
  # Empty dataframe for output
  Dat.output <- Dat[0,]
  
  for (i in Changepoint_Pars_summ_CLUST_PRED$ClusterHour_PRED) {
    Dat.subs.clust <- Dat_clean[Dat_clean$ClusterHour_PRED == i,] 
    
    # Get the optimal changepoint function parameters for each subset
    opt <- RG_Detect_Outlier_Model_Based_Ch_3P(Dat.subs.clust, 1.96, 50, 100)
    
    Dat.subs.clust <- opt[[1]]
    Dat.output <- rbind(Dat.output, Dat.subs.clust)
    
    Changepoint_Parameters_i <- opt[[2]]
    Changepoint_Pars_summ_CLUST_PRED[Changepoint_Pars_summ_CLUST_PRED$ClusterHour_PRED == i, 2:5] <- Changepoint_Parameters_i
  }  
  
  # Reorder output dataframe by date
  Dat_clean <- Dat.output[order(Dat.output$DATE),]
  Dat_clean$Power_fitted_ClustH_PRED<-Dat_clean$Power_fitted
  
  rm(Dat.output, opt, Changepoint_Parameters_i, Dat.subs.clust, i)
}

# Write to file
setwd(paste(WD, "output", sep="/"))
write.csv(Changepoint_Pars_summ_CLUST,"10_Changepoint_Pars_summ_CLUST.csv")
write.csv(Changepoint_Pars_summ_CLUST_PRED,"10_Changepoint_Pars_summ_CLUST_PRED.csv")
setwd(WD)
