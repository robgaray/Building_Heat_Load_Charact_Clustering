# Inspection of changepoint models
{
  Changepoint_plot_coordinates <- Changepoint_Pars_summ_TOW1
  
  Changepoint_plot_coordinates$x1 <- -50
  Changepoint_plot_coordinates$y1 <- Changepoint_plot_coordinates$intercept + Changepoint_plot_coordinates$slope_Temp * Changepoint_plot_coordinates$x1
  
  Changepoint_plot_coordinates$x2 <- -(Changepoint_plot_coordinates$intercept - Changepoint_plot_coordinates$minimum) / Changepoint_plot_coordinates$slope_Temp
  Changepoint_plot_coordinates$y2 <- Changepoint_plot_coordinates$minimum
  
  Changepoint_plot_coordinates$x3 <- 50
  Changepoint_plot_coordinates$y3 <- Changepoint_plot_coordinates$minimum
  
  plot(c(-50,50),c(0,max (Changepoint_plot_coordinates$y1)),
       type="n",
       xlab="Temperature [C]",
       ylab="Heat Load [kWh]")
  
  for (ni in Changepoint_plot_coordinates$DATE_hour_week)
  {
    bool<-Changepoint_plot_coordinates$DATE_hour_week==ni
    varX<-c(Changepoint_plot_coordinates$x1[bool],Changepoint_plot_coordinates$x2[bool],Changepoint_plot_coordinates$x3[bool])
    varY<-c(Changepoint_plot_coordinates$y1[bool],Changepoint_plot_coordinates$y2[bool],Changepoint_plot_coordinates$y3[bool])
    
    lines (varX,varY)
  }
  
  
  setwd(paste(WD, "output", sep="/"))
  jpeg("04_Changepoint001.jpg", width = 800, height = 600)
  plot(c(-50,50),c(0,max (Changepoint_plot_coordinates$y1)),
       type="n",
       xlab="Temperature [C]",
       ylab="Heat Load [kWh]")
  
  for (ni in Changepoint_plot_coordinates$DATE_hour_week)
  {
    bool<-Changepoint_plot_coordinates$DATE_hour_week==ni
    varX<-c(Changepoint_plot_coordinates$x1[bool],Changepoint_plot_coordinates$x2[bool],Changepoint_plot_coordinates$x3[bool])
    varY<-c(Changepoint_plot_coordinates$y1[bool],Changepoint_plot_coordinates$y2[bool],Changepoint_plot_coordinates$y3[bool])
    
    lines (varX,varY)
  }
  dev.off()
  setwd(WD)
  
  
  
  
  rm(bool,ni,start_time,varX,varY,Changepoint_plot_coordinates)
}

# Inspection of outliers
{
  p<-ggplot(Dat, aes(x = Power, y = Power_fitted)) +
    geom_point(aes(color = IS_Outlier)) +
    scale_color_manual(values = c("FALSE" = "black", "TRUE" = "red")) +
    labs(x = "Power",
         y = "Power_fitted") +
    theme_minimal() + 
    theme(
      panel.background = element_rect(fill = "white", color = NA), # Fondo del panel blanco
      plot.background = element_rect(fill = "white", color = NA)   # Fondo de la figura blanco
    )
  print(p)
  setwd(paste(WD, "output", sep="/"))
  ggsave("04_outliers001.jpg", plot = p, device = "jpeg", width = 6, height = 4, units = "in", dpi = 300)
  setwd(WD)
  rm(p)
  
  p<-ggplot(Dat, aes(x = Temperature, y = Power)) +
    geom_point(aes(color = IS_Outlier)) +
    scale_color_manual(values = c("FALSE" = "black", "TRUE" = "red")) +
    labs(x = "Temperature",
         y = "Power") +
    theme_minimal() + 
    theme(
      panel.background = element_rect(fill = "white", color = NA), # Fondo del panel blanco
      plot.background = element_rect(fill = "white", color = NA)   # Fondo de la figura blanco
    )
  print(p)
  setwd(paste(WD, "output", sep="/"))
  ggsave("04_outliers002.jpg", plot = p, device = "jpeg", width = 6, height = 4, units = "in", dpi = 300)
  setwd(WD)
  rm(p)
  
  # Aggregation by month
  {
    Dat_monthly <- Dat %>%
      mutate(Month = as.yearmon(DATE)) %>%
      group_by(Month) %>%
      summarise(Sum_IS_Outlier = sum(IS_Outlier, na.rm = TRUE),
                Total_Count = n(),
                Percentage_IS_Outlier = (Sum_IS_Outlier / Total_Count) * 100)
    
    max_sum <- max(Dat_monthly$Sum_IS_Outlier, na.rm = TRUE)
    max_percentage <- 100
    Dat_monthly <- Dat_monthly %>%
      mutate(Scaled_Percentage = Percentage_IS_Outlier * (max_sum / max_percentage))
    
    p<-ggplot(Dat_monthly, aes(x = Month)) +
      geom_point(aes(y = Sum_IS_Outlier), color = "blue", size = 3, shape = 16) +
      geom_bar(aes(y = Scaled_Percentage), stat = "identity", fill = "red", alpha = 0.5) +
      scale_x_yearmon(format = "%b %Y") +
      scale_y_continuous(
        name = "Number of outliers",
        sec.axis = sec_axis(~ . * (max_percentage / max_sum), name = "Share of Outliers (%)")) +
      labs(x = "Month") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1)) + 
      theme(
        panel.background = element_rect(fill = "white", color = NA), # Fondo del panel blanco
        plot.background = element_rect(fill = "white", color = NA)   # Fondo de la figura blanco
      )
    print(p)
    setwd(paste(WD, "output", sep="/"))
    ggsave("04_outliers003.jpg", plot = p, device = "jpeg", width = 6, height = 4, units = "in", dpi = 300)
    setwd(WD)
    
    rm(max_percentage, max_sum, Dat_monthly,p)
  }
  
  # Identification of outliers based on residuals
  # plot with 95% confidence interval
  {
    # Statistics
    mean_residuals <- mean(Dat$Power_residuals, na.rm = TRUE)
    sd_residuals <- sd(Dat$Power_residuals, na.rm = TRUE)
    
    # 95% confidence interval band
    ci_lower <- mean_residuals - 1.96 * sd_residuals
    ci_upper <- mean_residuals + 1.96 * sd_residuals
    
    # Plot
    # Data
    p<-ggplot(Dat, aes(x = Power_residuals)) +
      geom_histogram(aes(y = ..density..), bins = 300, fill = "skyblue", color = "black", alpha = 0.7) +
      # Normal distribution
      stat_function(fun = dnorm, args = list(mean = mean_residuals, sd = sd_residuals), 
                    color = "red", size = 1) +
      # Confidence Interval
      geom_vline(xintercept = c(ci_lower, ci_upper), linetype = "dashed", color = "blue", size = 1) +
      # Labels & Theme
      labs(title = "Histogram of power residuals [kWh] over normaly adjusted curve",
           x = "Power_residuals",
           y = "Density") +
      theme_minimal() + 
      theme(
        panel.background = element_rect(fill = "white", color = NA), # Fondo del panel blanco
        plot.background = element_rect(fill = "white", color = NA)   # Fondo de la figura blanco
      )
    print(p)
    setwd(paste(WD, "output", sep="/"))
    ggsave("04_outliers004.jpg", plot = p, device = "jpeg", width = 6, height = 4, units = "in", dpi = 300)
    setwd(WD)
    
    rm(p, ci_lower, ci_upper, mean_residuals, sd_residuals)
  }
}