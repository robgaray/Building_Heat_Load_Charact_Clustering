# Prepare a dataset
{
  Dat_statistics <-Dat_clean
  
  # Remove corrected values
  Dat_statistics<-Dat_statistics[Dat_statistics$IS_Missing_Outlier==FALSE,]
  Dat_statistics<-Dat_statistics[Dat_statistics$IS_Repaired==FALSE,]
  
  # Remove not required variables
  Dat_statistics <- Dat_statistics %>%
    select(-Power_fitted, -Power_corrected, -Power_residuals, -Power_original,
           -IS_Outlier, -IS_Missing, -IS_Missing_Outlier, -IS_Repaired,
           -ClusterHour, -ClusterHour_PRED)
}

# Calculate residuals
{
  # Instantaneous
  Dat_statistics$Power_residuals_TOW         <-Dat_statistics$Power_fitted_TOW         -Dat_statistics$Power
  Dat_statistics$Power_residuals_ClustH      <-Dat_statistics$Power_fitted_ClustH      -Dat_statistics$Power
  Dat_statistics$Power_residuals_ClustH_PRED <-Dat_statistics$Power_fitted_ClustH_PRED -Dat_statistics$Power
  
  #3h cumulated
  Dat_statistics$Power_residuals_TOW_3h         <-stats::filter(Dat_statistics$Power_residuals_TOW,         rep(1,3), sides =1)
  Dat_statistics$Power_residuals_ClustH_3h      <-stats::filter(Dat_statistics$Power_residuals_ClustH,      rep(1,3), sides =1)
  Dat_statistics$Power_residuals_ClustH_PRED_3h <-stats::filter(Dat_statistics$Power_residuals_ClustH_PRED, rep(1,3), sides =1)
  
  #6h cumulated
  Dat_statistics$Power_residuals_TOW_6h         <-stats::filter(Dat_statistics$Power_residuals_TOW,         rep(1,6), sides =1)
  Dat_statistics$Power_residuals_ClustH_6h      <-stats::filter(Dat_statistics$Power_residuals_ClustH,      rep(1,6), sides =1)
  Dat_statistics$Power_residuals_ClustH_PRED_6h <-stats::filter(Dat_statistics$Power_residuals_ClustH_PRED, rep(1,6), sides =1)
}

# MAE & RMSE
{
  model_metrics<- data.frame(
    model = c("TOW","ClustH","ClustH_PRED"),
    mae = rep(NA, 3),
    rmse = rep(NA, 3),
    resid_1h = rep(NA, 3),
    resid_3h = rep(NA, 3),
    resid_6h = rep(NA, 3))
  
  model_metrics[model_metrics$model=="TOW",]$mae<-mae(Dat_statistics$Power, Dat_statistics$Power_fitted_TOW)
  model_metrics[model_metrics$model=="TOW",]$rmse<-rmse(Dat_statistics$Power, Dat_statistics$Power_fitted_TOW)
  
  model_metrics[model_metrics$model=="ClustH",]$mae<-mae(Dat_statistics$Power, Dat_statistics$Power_fitted_ClustH)
  model_metrics[model_metrics$model=="ClustH",]$rmse<-rmse(Dat_statistics$Power, Dat_statistics$Power_fitted_ClustH)
  
  model_metrics[model_metrics$model=="ClustH_PRED",]$mae<-mae(Dat_statistics$Power, Dat_statistics$Power_fitted_ClustH_PRED)
  model_metrics[model_metrics$model=="ClustH_PRED",]$rmse<-rmse(Dat_statistics$Power, Dat_statistics$Power_fitted_ClustH_PRED)
  
  model_metrics[model_metrics$model=="TOW",]$resid_1h<-sum(abs(Dat_statistics$Power_residuals_TOW[complete.cases(Dat_statistics$Power_residuals_TOW)]))
  model_metrics[model_metrics$model=="TOW",]$resid_3h<-sum(abs(Dat_statistics$Power_residuals_TOW_3h[complete.cases(Dat_statistics$Power_residuals_TOW_3h)]))
  model_metrics[model_metrics$model=="TOW",]$resid_6h<-sum(abs(Dat_statistics$Power_residuals_TOW_6h[complete.cases(Dat_statistics$Power_residuals_TOW_6h)]))
  
  model_metrics[model_metrics$model=="ClustH",]$resid_1h<-sum(abs(Dat_statistics$Power_residuals_ClustH[complete.cases(Dat_statistics$Power_residuals_ClustH)]))
  model_metrics[model_metrics$model=="ClustH",]$resid_3h<-sum(abs(Dat_statistics$Power_residuals_ClustH_3h[complete.cases(Dat_statistics$Power_residuals_ClustH_3h)]))
  model_metrics[model_metrics$model=="ClustH",]$resid_6h<-sum(abs(Dat_statistics$Power_residuals_ClustH_6h[complete.cases(Dat_statistics$Power_residuals_ClustH_6h)]))
  
  model_metrics[model_metrics$model=="ClustH_PRED",]$resid_1h<-sum(abs(Dat_statistics$Power_residuals_ClustH_PRED[complete.cases(Dat_statistics$Power_residuals_ClustH_PRED)]))
  model_metrics[model_metrics$model=="ClustH_PRED",]$resid_3h<-sum(abs(Dat_statistics$Power_residuals_ClustH_PRED_3h[complete.cases(Dat_statistics$Power_residuals_ClustH_PRED_3h)]))
  model_metrics[model_metrics$model=="ClustH_PRED",]$resid_6h<-sum(abs(Dat_statistics$Power_residuals_ClustH_PRED_6h[complete.cases(Dat_statistics$Power_residuals_ClustH_PRED_6h)]))
  
  print(model_metrics)
  
  setwd(paste(WD, "output", sep="/"))
  write.csv(model_metrics,"11_model_metrics.csv")
  setwd(WD)
}

# Graphics
{
  # Full year. Cumulated daily load
  {
    # Create aggregated dataset
    Dat_statistics_agg <- Dat_statistics %>%
      group_by(DATE_day_year) %>%
      summarise(
        DATE_month_year = first(DATE_month_year),
        DATE_week_year = first(DATE_week_year),
        DATE_day_month = first(DATE_day_month),
        DATE_day_week = first(DATE_day_week),
        DATE_weekday = first(DATE_weekday),
        Holiday = first(Holiday),
        Power = mean(Power, na.rm = TRUE),
        Power_fitted_TOW = mean(Power_fitted_TOW, na.rm = TRUE),
        Power_fitted_ClustH = mean(Power_fitted_ClustH, na.rm = TRUE),
        Power_fitted_ClustH_PRED = mean(Power_fitted_ClustH_PRED, na.rm = TRUE)
      )
    
    #Generate plot
    {
      # data transformation for visualization
      df_long <- Dat_statistics_agg %>%
        pivot_longer(
          cols = c(Power,Power_fitted_TOW, Power_fitted_ClustH, Power_fitted_ClustH_PRED),
          names_to = "Variable",
          values_to = "Value"
        )
      
      # Create plot
      p<-ggplot(df_long, aes(x = DATE_month_year, y = Value, fill = Variable)) +
        geom_bar(stat = "identity", position = "dodge") +
        labs(
          title = "Average monthly heat load",
          x = "Month",
          y = "kWh",
          fill = "Variable"
        ) +
        theme_minimal() +
        theme(axis.text.x = element_text(angle = 45, hjust = 1))
      
      print(p)
      setwd(paste(WD, "output", sep="/"))
      ggsave("11_Statistics_Graphics001.jpg", plot = p, device = "jpeg", width = 6, height = 4, units = "in", dpi = 300)
      setwd(WD)
      rm(p)
      }
  }
  
  # Coldest month. Daily load quantiles
  {
    # Automatic identification of coldest month
    coldest_month <- Dat_statistics %>%
      group_by(DATE_month_year) %>%
      summarise(avg_temperature = mean(Temperature, na.rm = TRUE)) %>%
      arrange(avg_temperature) %>%
      slice(1) %>%
      pull(DATE_month_year)
    
    # Subset of coldest month
    Dat_statistics_coldest <- Dat_statistics %>%
      filter(DATE_month_year == coldest_month)
    
    # dataset transformation
    data_long <- Dat_statistics_coldest %>%
      pivot_longer(cols = c(Power, Power_fitted_TOW, Power_fitted_ClustH, Power_fitted_ClustH_PRED),
                   names_to = "Variable",
                   values_to = "Value")
    
    # statistics for plotting
    summary_stats <- data_long %>%
      group_by(DATE_day_month, Variable) %>%
      summarise(
        mean_value = mean(Value, na.rm = TRUE),       
        p5 = quantile(Value, 0.05, na.rm = TRUE),    
        p95 = quantile(Value, 0.95, na.rm = TRUE),
        .groups = "drop"
      )
    
    # Plots
    p<-ggplot(data_long,
           aes(x = as.factor(DATE_day_month), y = Value, fill = Variable)) +
      geom_boxplot(position = position_dodge(width = 0.8), outlier.shape = NA, alpha = 0.7) + # Boxplot, Does not show atypical values
      geom_point(data = summary_stats, aes(x = as.factor(DATE_day_month), y = mean_value, color = Variable), 
                 shape = 18, size = 3, inherit.aes = FALSE) + # Average value as a dot
      geom_errorbar(data = summary_stats, aes(x = as.factor(DATE_day_month), ymin = p5, ymax = p95, color = Variable),
                    width = 0.4, position = position_dodge(width = 0.8), inherit.aes = FALSE) + # Arrow bars for percentiles 5 to 95
      labs(
        title = "Statistical distribution of Actual and fitted Power values for the coldest month in the year",
        x = "Day of the month",
        y = "Power [kWh]",
        fill = "Variable",
        color = "Variable"
      ) +
      theme_minimal() +
      theme(
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "top"
      )
    
    print(p)
    setwd(paste(WD, "output", sep="/"))
    ggsave("11_Statistics_Graphics002.jpg", plot = p, device = "jpeg", width = 6, height = 4, units = "in", dpi = 300)
    setwd(WD)
    rm(p)
  }
  
  # Cold week. Daily load quantiles
  {
    # Automatic identification of coldest week
    coldest_week <- Dat_statistics %>%
      group_by(DATE_week_year) %>%
      summarise(avg_temperature = mean(Temperature, na.rm = TRUE)) %>%
      arrange(avg_temperature) %>%
      slice(1) %>%
      pull(DATE_week_year)
    
    # Subset of coldest week
    Dat_statistics_coldest <- Dat_statistics %>%
      filter(DATE_week_year == coldest_week)
    
    # dataset transformation
    data_long <- Dat_statistics_coldest %>%
      pivot_longer(cols = c(Power, Power_fitted_TOW, Power_fitted_ClustH, Power_fitted_ClustH_PRED),
                   names_to = "Variable",
                   values_to = "Value")
    
    # statistics for plotting
    summary_stats <- data_long %>%
      group_by(DATE_day_week, Variable) %>%
      summarise(
        mean_value = mean(Value, na.rm = TRUE),       
        p5 = quantile(Value, 0.05, na.rm = TRUE),    
        p95 = quantile(Value, 0.95, na.rm = TRUE),
        .groups = "drop"
      )
    
    # Plots
    p<-ggplot(data_long,
           aes(x = as.factor(DATE_day_week), y = Value, fill = Variable)) +
      geom_boxplot(position = position_dodge(width = 0.8), outlier.shape = NA, alpha = 0.7) + # Boxplot, Does not show atypical values
      geom_point(data = summary_stats, aes(x = as.factor(DATE_day_week), y = mean_value, color = Variable), 
                 shape = 18, size = 3, inherit.aes = FALSE) + # Average value as a dot
      geom_errorbar(data = summary_stats, aes(x = as.factor(DATE_day_week), ymin = p5, ymax = p95, color = Variable),
                    width = 0.4, position = position_dodge(width = 0.8), inherit.aes = FALSE) + # Arrow bars for percentiles 5 to 95
      labs(
        title = "Statistical distribution of Actual and fitted Power values for the coldest week in the year",
        x = "Day of the week",
        y = "Power [kWh]",
        fill = "Variable",
        color = "Variable"
      ) +
      theme_minimal() +
      theme(
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "top"
      )
    
    print(p)
    setwd(paste(WD, "output", sep="/"))
    ggsave("11_Statistics_Graphics003.jpg", plot = p, device = "jpeg", width = 6, height = 4, units = "in", dpi = 300)
    setwd(WD)
    rm(p)
  }
  
  # Cold week. Hourly load
  {
    # Automatic identification of coldest month
    coldest_month <- Dat_statistics %>%
      group_by(DATE_month_year) %>%
      summarise(avg_temperature = mean(Temperature, na.rm = TRUE)) %>%
      arrange(avg_temperature) %>%
      slice(1) %>%
      pull(DATE_month_year)
    
    # Subset of coldest month
    Dat_statistics_coldest <- Dat_statistics %>%
      filter(DATE_month_year == coldest_month)
    
    # dataset transformation
    data_long <- Dat_statistics_coldest %>%
      pivot_longer(cols = c(Power, Power_fitted_TOW, Power_fitted_ClustH, Power_fitted_ClustH_PRED),
                   names_to = "Variable",
                   values_to = "Value")
    
    # statistics for plotting
    summary_stats <- data_long %>%
      group_by(DATE_hour_week, Variable) %>%
      summarise(
        mean_value = mean(Value, na.rm = TRUE),       
        p5 = quantile(Value, 0.05, na.rm = TRUE),    
        p95 = quantile(Value, 0.95, na.rm = TRUE),
        .groups = "drop"
      )
    
    # Plots
    p<-ggplot(data_long,
           aes(x = as.factor(DATE_hour_week), y = Value, fill = Variable)) +
      geom_point(data = summary_stats, aes(x = as.factor(DATE_hour_week), y = mean_value, color = Variable), 
                 shape = 18, size = 2, inherit.aes = FALSE) + # Average value as a dot
      labs(
        title = "Statistical distribution of Actual and fitted Power values for the coldest month in the year",
        x = "Hour of the week",
        y = "Power [kWh]",
        fill = "Variable",
        color = "Variable"
      ) +
      theme_minimal() +
      theme(
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "top"
      )
    
    print(p)
    setwd(paste(WD, "output", sep="/"))
    ggsave("11_Statistics_Graphics004.jpg", plot = p, device = "jpeg", width = 6, height = 4, units = "in", dpi = 300)
    setwd(WD)
    rm(p)
  }
  
  
  # Hottest month. Daily load quantiles
  {
    # Automatic identification of hottest month
    hottest_month <- Dat_statistics %>%
      group_by(DATE_month_year) %>%
      summarise(avg_temperature = mean(Temperature, na.rm = TRUE)) %>%
      arrange(avg_temperature) %>%
      slice(12) %>%
      pull(DATE_month_year)
    
    # Subset of hottest month
    Dat_statistics_hottest <- Dat_statistics %>%
      filter(DATE_month_year == hottest_month)
    
    # dataset transformation
    data_long <- Dat_statistics_hottest %>%
      pivot_longer(cols = c(Power, Power_fitted_TOW, Power_fitted_ClustH, Power_fitted_ClustH_PRED),
                   names_to = "Variable",
                   values_to = "Value")
    
    # statistics for plotting
    summary_stats <- data_long %>%
      group_by(DATE_day_month, Variable) %>%
      summarise(
        mean_value = mean(Value, na.rm = TRUE),       
        p5 = quantile(Value, 0.05, na.rm = TRUE),    
        p95 = quantile(Value, 0.95, na.rm = TRUE),
        .groups = "drop"
      )
    
    # Plots
    p<-ggplot(data_long,
           aes(x = as.factor(DATE_day_month), y = Value, fill = Variable)) +
      geom_boxplot(position = position_dodge(width = 0.8), outlier.shape = NA, alpha = 0.7) + # Boxplot, Does not show atypical values
      geom_point(data = summary_stats, aes(x = as.factor(DATE_day_month), y = mean_value, color = Variable), 
                 shape = 18, size = 3, inherit.aes = FALSE) + # Average value as a dot
      geom_errorbar(data = summary_stats, aes(x = as.factor(DATE_day_month), ymin = p5, ymax = p95, color = Variable),
                    width = 0.4, position = position_dodge(width = 0.8), inherit.aes = FALSE) + # Arrow bars for percentiles 5 to 95
      labs(
        title = "Statistical distribution of actual and fitted Power values for the hottest month in the year",
        x = "Day of the month",
        y = "Power [kWh]",
        fill = "Variable",
        color = "Variable"
      ) +
      theme_minimal() +
      theme(
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "top"
      )
    
    print(p)
    setwd(paste(WD, "output", sep="/"))
    ggsave("11_Statistics_Graphics005.jpg", plot = p, device = "jpeg", width = 6, height = 4, units = "in", dpi = 300)
    setwd(WD)
    rm(p)
  }
  
  # Hottest week. Daily load quantiles
  {
    # Automatic identification of hottest week
    hottest_week <- Dat_statistics %>%
      group_by(DATE_week_year) %>%
      summarise(avg_temperature = mean(Temperature, na.rm = TRUE)) %>%
      arrange(avg_temperature) %>%
      slice(52) %>%
      pull(DATE_week_year)
    
    # Subset of coldest week
    Dat_statistics_hottest <- Dat_statistics %>%
      filter(DATE_week_year == hottest_week)
    
    # dataset transformation
    data_long <- Dat_statistics_hottest %>%
      pivot_longer(cols = c(Power, Power_fitted_TOW, Power_fitted_ClustH, Power_fitted_ClustH_PRED),
                   names_to = "Variable",
                   values_to = "Value")
    
    # statistics for plotting
    summary_stats <- data_long %>%
      group_by(DATE_day_week, Variable) %>%
      summarise(
        mean_value = mean(Value, na.rm = TRUE),       
        p5 = quantile(Value, 0.05, na.rm = TRUE),    
        p95 = quantile(Value, 0.95, na.rm = TRUE),
        .groups = "drop"
      )
    
    # Plots
    p<-ggplot(data_long,
           aes(x = as.factor(DATE_day_week), y = Value, fill = Variable)) +
      geom_boxplot(position = position_dodge(width = 0.8), outlier.shape = NA, alpha = 0.7) + # Boxplot, Does not show atypical values
      geom_point(data = summary_stats, aes(x = as.factor(DATE_day_week), y = mean_value, color = Variable), 
                 shape = 18, size = 3, inherit.aes = FALSE) + # Average value as a dot
      geom_errorbar(data = summary_stats, aes(x = as.factor(DATE_day_week), ymin = p5, ymax = p95, color = Variable),
                    width = 0.4, position = position_dodge(width = 0.8), inherit.aes = FALSE) + # Arrow bars for percentiles 5 to 95
      labs(
        title = "Statistical distribution of actual and fitted Power values for the hottest week in the year",
        x = "Day of the week",
        y = "Power [kWh]",
        fill = "Variable",
        color = "Variable"
      ) +
      theme_minimal() +
      theme(
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "top"
      )
    
    print(p)
    setwd(paste(WD, "output", sep="/"))
    ggsave("11_Statistics_Graphics006.jpg", plot = p, device = "jpeg", width = 6, height = 4, units = "in", dpi = 300)
    setwd(WD)
    rm(p)
  }
  
  # Hot week. Hourly load
  {
    # Automatic identification of hottest month
    hottest_month <- Dat_statistics %>%
      group_by(DATE_month_year) %>%
      summarise(avg_temperature = mean(Temperature, na.rm = TRUE)) %>%
      arrange(avg_temperature) %>%
      slice(12) %>%
      pull(DATE_month_year)
    
    # Subset of hottest month
    Dat_statistics_hottest <- Dat_statistics %>%
      filter(DATE_month_year == hottest_month)
    
    # dataset transformation
    data_long <- Dat_statistics_hottest %>%
      pivot_longer(cols = c(Power, Power_fitted_TOW, Power_fitted_ClustH, Power_fitted_ClustH_PRED),
                   names_to = "Variable",
                   values_to = "Value")
    
    # statistics for plotting
    summary_stats <- data_long %>%
      group_by(DATE_hour_week, Variable) %>%
      summarise(
        mean_value = mean(Value, na.rm = TRUE),       
        p5 = quantile(Value, 0.05, na.rm = TRUE),    
        p95 = quantile(Value, 0.95, na.rm = TRUE),
        .groups = "drop"
      )
    
    # Plots
    p<-ggplot(data_long,
           aes(x = as.factor(DATE_hour_week), y = Value, fill = Variable)) +
      geom_point(data = summary_stats, aes(x = as.factor(DATE_hour_week), y = mean_value, color = Variable), 
                 shape = 18, size = 2, inherit.aes = FALSE) + # Average value as a dot
      labs(
        title = "Mean actual and fitted Power values for the average week in the hottest month in the year",
        x = "Hour of the week",
        y = "Power [kWh]",
        fill = "Variable",
        color = "Variable"
      ) +
      theme_minimal() +
      theme(
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "top"
      )
    
    print(p)
    setwd(paste(WD, "output", sep="/"))
    ggsave("11_Statistics_Graphics007.jpg", plot = p, device = "jpeg", width = 6, height = 4, units = "in", dpi = 300)
    setwd(WD)
    rm(p)
  }
  
  # Temperate month. Daily load quantiles
  {
    # Automatic identification of temperate month
    temperate_month <- Dat_statistics %>%
      group_by(DATE_month_year) %>%
      summarise(avg_temperature = mean(Temperature, na.rm = TRUE)) %>%
      arrange(avg_temperature) %>%
      slice(8) %>%
      pull(DATE_month_year)
    
    # Subset of hottest month
    Dat_statistics_temperate <- Dat_statistics %>%
      filter(DATE_month_year == temperate_month)
    
    # dataset transformation
    data_long <- Dat_statistics_temperate %>%
      pivot_longer(cols = c(Power, Power_fitted_TOW, Power_fitted_ClustH, Power_fitted_ClustH_PRED),
                   names_to = "Variable",
                   values_to = "Value")
    
    # statistics for plotting
    summary_stats <- data_long %>%
      group_by(DATE_day_month, Variable) %>%
      summarise(
        mean_value = mean(Value, na.rm = TRUE),       
        p5 = quantile(Value, 0.05, na.rm = TRUE),    
        p95 = quantile(Value, 0.95, na.rm = TRUE),
        .groups = "drop"
      )
    
    # Plots
    p<-ggplot(data_long,
           aes(x = as.factor(DATE_day_month), y = Value, fill = Variable)) +
      geom_boxplot(position = position_dodge(width = 0.8), outlier.shape = NA, alpha = 0.7) + # Boxplot, Does not show atypical values
      geom_point(data = summary_stats, aes(x = as.factor(DATE_day_month), y = mean_value, color = Variable), 
                 shape = 18, size = 3, inherit.aes = FALSE) + # Average value as a dot
      geom_errorbar(data = summary_stats, aes(x = as.factor(DATE_day_month), ymin = p5, ymax = p95, color = Variable),
                    width = 0.4, position = position_dodge(width = 0.8), inherit.aes = FALSE) + # Arrow bars for percentiles 5 to 95
      labs(
        title = "Statistical distribution of actual and fitted Power values for a temperate month in the year",
        x = "Day of the month",
        y = "Power [kWh]",
        fill = "Variable",
        color = "Variable"
      ) +
      theme_minimal() +
      theme(
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "top"
      )
    
    print(p)
    setwd(paste(WD, "output", sep="/"))
    ggsave("11_Statistics_Graphics008.jpg", plot = p, device = "jpeg", width = 6, height = 4, units = "in", dpi = 300)
    setwd(WD)
    rm(p)
  }
  
  # Temperate week. Daily load quantiles
  {
    # Automatic identification of hottest week
    temperate_week <- Dat_statistics %>%
      group_by(DATE_week_year) %>%
      summarise(avg_temperature = mean(Temperature, na.rm = TRUE)) %>%
      arrange(avg_temperature) %>%
      slice(35) %>%
      pull(DATE_week_year)
    
    # Subset of coldest week
    Dat_statistics_temperate <- Dat_statistics %>%
      filter(DATE_week_year == temperate_week)
    
    # dataset transformation
    data_long <- Dat_statistics_temperate %>%
      pivot_longer(cols = c(Power, Power_fitted_TOW, Power_fitted_ClustH, Power_fitted_ClustH_PRED),
                   names_to = "Variable",
                   values_to = "Value")
    
    # statistics for plotting
    summary_stats <- data_long %>%
      group_by(DATE_day_week, Variable) %>%
      summarise(
        mean_value = mean(Value, na.rm = TRUE),       
        p5 = quantile(Value, 0.05, na.rm = TRUE),    
        p95 = quantile(Value, 0.95, na.rm = TRUE),
        .groups = "drop"
      )
    
    # Plots
    p<-ggplot(data_long,
           aes(x = as.factor(DATE_day_week), y = Value, fill = Variable)) +
      geom_boxplot(position = position_dodge(width = 0.8), outlier.shape = NA, alpha = 0.7) + # Boxplot, Does not show atypical values
      geom_point(data = summary_stats, aes(x = as.factor(DATE_day_week), y = mean_value, color = Variable), 
                 shape = 18, size = 3, inherit.aes = FALSE) + # Average value as a dot
      geom_errorbar(data = summary_stats, aes(x = as.factor(DATE_day_week), ymin = p5, ymax = p95, color = Variable),
                    width = 0.4, position = position_dodge(width = 0.8), inherit.aes = FALSE) + # Arrow bars for percentiles 5 to 95
      labs(
        title = "Statistical distribution of actual and fitted Power values for a temperate week in the year",
        x = "Day of the week",
        y = "Power [kWh]",
        fill = "Variable",
        color = "Variable"
      ) +
      theme_minimal() +
      theme(
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "top"
      )
    
    print(p)
    setwd(paste(WD, "output", sep="/"))
    ggsave("11_Statistics_Graphics009.jpg", plot = p, device = "jpeg", width = 6, height = 4, units = "in", dpi = 300)
    setwd(WD)
    rm(p)
  }
  
  # Temperate week. Hourly load
  {
    # Automatic identification of temperate month
    temperate_month <- Dat_statistics %>%
      group_by(DATE_month_year) %>%
      summarise(avg_temperature = mean(Temperature, na.rm = TRUE)) %>%
      arrange(avg_temperature) %>%
      slice(8) %>%
      pull(DATE_month_year)
    
    # Subset of hottest month
    Dat_statistics_temperate <- Dat_statistics %>%
      filter(DATE_month_year == temperate_month)
    
    # dataset transformation
    data_long <- Dat_statistics_temperate %>%
      pivot_longer(cols = c(Power, Power_fitted_TOW, Power_fitted_ClustH, Power_fitted_ClustH_PRED),
                   names_to = "Variable",
                   values_to = "Value")
    
    # statistics for plotting
    summary_stats <- data_long %>%
      group_by(DATE_hour_week, Variable) %>%
      summarise(
        mean_value = mean(Value, na.rm = TRUE),       
        p5 = quantile(Value, 0.05, na.rm = TRUE),    
        p95 = quantile(Value, 0.95, na.rm = TRUE),
        .groups = "drop"
      )
    
    # Plots
    p<-ggplot(data_long,
           aes(x = as.factor(DATE_hour_week), y = Value, fill = Variable)) +
      geom_point(data = summary_stats, aes(x = as.factor(DATE_hour_week), y = mean_value, color = Variable), 
                 shape = 18, size = 2, inherit.aes = FALSE) + # Average value as a dot
      labs(
        title = "Mean actual and fitted Power values for the average week in a temperate month in the year",
        x = "Hour of the week",
        y = "Power [kWh]",
        fill = "Variable",
        color = "Variable"
      ) +
      theme_minimal() +
      theme(
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "top"
      )
    
    print(p)
    setwd(paste(WD, "output", sep="/"))
    ggsave("11_Statistics_Graphics010.jpg", plot = p, device = "jpeg", width = 6, height = 4, units = "in", dpi = 300)
    setwd(WD)
    rm(p)
  }
}
