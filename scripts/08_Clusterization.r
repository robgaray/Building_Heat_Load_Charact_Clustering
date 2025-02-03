# Create data frame with daily power vectors
{
  
  # Pivot data frame to get one observation per day, where 24 variables are obtained.
  # One variable for each hourly observation of "Power_corrected".
  Dat_day <- Dat %>%
    select(DATE_day_year, DATE_hour_day, Power_corrected) %>%
    pivot_wider(names_from = DATE_hour_day, values_from = Power_corrected, names_prefix = "Power.") %>%
    rename(DATE = DATE_day_year)
  
  # Plot of daily profiles
  {
    data_long <- Dat_day %>%
      pivot_longer(cols = starts_with("Power"), 
                   names_to = "Variable", 
                   values_to = "Value") %>%
      mutate(Variable = as.numeric(gsub("Power.", "", Variable))) # Get one column for each hourly value of power
    
    p<-ggplot(data_long, aes(x = Variable, y = Value, group = DATE)) +
      geom_line() +
      labs(title = "Daily profiles",
           x = "Hour of the day",
           y = "Power") +
      theme_minimal() +
      theme(legend.position = "none") # Optional, removes legend if there are too many
    
    print(p)
    setwd(paste(WD, "output", sep="/"))
    ggsave("08_profiles001.jpg", plot = p, device = "jpeg", width = 6, height = 4, units = "in", dpi = 300)
    setwd(WD)
    rm(p)
    
    rm(data_long)
    }
}

# Create data frame to identify clusters
{
  # Avoid missing values
  {
    Dat_day_clean <- Dat_day %>% na.omit()
  }
  
  # 0-1 data normalization
  {
    Dat_day_normalized <- Dat_day_clean %>%
      mutate(across(
        .cols = -DATE,  # Explicitly excludes the DATE column
        .fns = normalize_min_max
      ))
  }
  
  # Plot of daily profiles after normalization
  {
    data_long <- Dat_day_normalized %>%
      pivot_longer(cols = starts_with("Power"), 
                   names_to = "Variable", 
                   values_to = "Value") %>%
      mutate(Variable = as.numeric(gsub("Power.", "", Variable))) # Extraer el número de Power
    
    p<-ggplot(data_long, aes(x = Variable, y = Value, group = DATE)) +
      geom_line() +
      labs(title = "Normalized daily profiles",
           x = "Hour of the day",
           y = "Power (normalized)") +
      theme_minimal() +
      theme(legend.position = "none") # Opcional, para quitar la leyenda si hay muchas fechas
    
    print(p)
    setwd(paste(WD, "output", sep="/"))
    ggsave("08_profiles002.jpg", plot = p, device = "jpeg", width = 6, height = 4, units = "in", dpi = 300)
    setwd(WD)
    rm(p)
    
    rm(data_long)
  }
}

# Clusterization
{
  # Defines the optimum number of clusters through various methods
  {
    k_min<-3 # Avoids a 2-cluster output, where only weekdays and weekends are separated
    k_max<-30
    
    # Elbow method
    {
      # Numerical calculation of the elbow method
      wss_values <- sapply(1:k_max, function(k){kmeans(Dat_day_normalized[,-1], centers = k, nstart = 25)$tot.withinss})
      
      # Difference between two consecutive WSS values
      wss_diffs <- abs(diff(wss_values))
      
      # Defines the optimal number of clusters as the position of the "elbow"
      # This means, the value of k where the reduction of WSS becomes less significant
      optimal_k_elbow <- which.min(wss_diffs > 0.05 * max(wss_diffs)) + 1
    }
    
    # Silhouette method
    {
      # Calculates the average silhouette value for each k
      silhouette_scores <- sapply(2:k_max, function(k) {
        km_res <- kmeans(Dat_day_normalized[,-1], centers = k, nstart = 25)
        silhouette_avg <- mean(silhouette(km_res$cluster, dist(Dat_day_normalized[,-1]))[, 3])  # Puntaje promedio de silueta
        return(silhouette_avg)
      })
      
      # Defines the optimal number of clusters as the one that maximizes the silhouette score
      optimal_k_silhouette <- which.max(silhouette_scores) + 1  # Adds 1 because indexes begin at 2
    }
    
    # Optimal number of clusters
    {
      optimal_k<-max(optimal_k_elbow,optimal_k_silhouette)
      optimal_k<- max(optimal_k, k_min) # Avoid weekend/weekday
    }
    
    # Graphics
    {
      # Elbow method
      p <- data.frame(k = 1:k_max, wss = wss_values) %>%
        ggplot(aes(x = k, y = wss)) +
        geom_line(color = "blue", size = 1) +
        geom_point(color = "red", size = 2) +
        geom_vline(xintercept = optimal_k_elbow, linetype = "dashed", color = "darkgreen") +
        labs(title = "Elbow method", x = "Number of clusters (k)", y = "Intra Cluster sum (WSS)")
      
      print(p)
      setwd(paste(WD, "output", sep="/"))
      ggsave("08_ElbowClust001.jpg", plot = p, device = "jpeg", width = 6, height = 4, units = "in", dpi = 300)
      setwd(WD)
      rm(p)
      
      # Silhouette method
      p <- data.frame(k = 2:k_max, silhouette = silhouette_scores) %>%
        ggplot(aes(x = k, y = silhouette)) +
        geom_line(color = "blue", size = 1) +
        geom_point(color = "red", size = 2) +
        geom_vline(xintercept = optimal_k_silhouette, linetype = "dashed", color = "darkgreen") +
        labs(title = "Silhouette method", x = "Number of clusters (k)", y = "Average Silhouette value")
      
      print(p)
      setwd(paste(WD, "output", sep="/"))
      ggsave("08_SilhouetteClust001.jpg", plot = p, device = "jpeg", width = 6, height = 4, units = "in", dpi = 300)
      setwd(WD)
      rm(p)
    }
    
    # cleanup
    rm(k_min, k_max, wss_diffs, wss_values, silhouette_scores, optimal_k_elbow, optimal_k_silhouette)
  }
  
  # Definition of clusters
  {
    # Apply K-means with the already defined optimal number of clusters
    kmeans_res <- kmeans(Dat_day_normalized[,-1], centers = optimal_k, nstart = 25)
    
    # Assign clusters to the original dataset
    Dat_day_clean$cluster <- kmeans_res$cluster
    Dat_day_normalized$cluster <- kmeans_res$cluster
    
    rm(kmeans_res)
  }
  
  # Inspection
  {
    # Cluster by date
    plot(Dat_day_normalized$cluster)
    
    setwd(paste(WD, "output", sep="/"))
    jpeg("08_Cluster001.jpg", width = 800, height = 600)
    plot(Dat_day_normalized$cluster)
    dev.off()
    setwd(WD)
    
    # Hourly load profiles by cluster
    {
      #Data preparation
      {
        Dat_day_clusters_hourly_mean <- Dat_day_normalized %>%
          group_by(cluster) %>%
          summarise(across(starts_with("Power."), mean, na.rm = TRUE))
        
        Dat_day_clusters_hourly_sd <- Dat_day_normalized %>%
          group_by(cluster) %>%
          summarise(across(starts_with("Power."), sd, na.rm = TRUE))
        
        Dat_day_clusters_hourly_q05 <- Dat_day_normalized %>%
          group_by(cluster) %>%
          summarise(across(starts_with("Power."), ~ quantile(.x, 0.05, na.rm = TRUE)))
        
        Dat_day_clusters_hourly_q95 <- Dat_day_normalized %>%
          group_by(cluster) %>%
          summarise(across(starts_with("Power."), ~ quantile(.x, 0.95, na.rm = TRUE)))
        
        
        clusters<-(Dat_day_clusters_hourly_mean$cluster)
        hours<-gsub("Power.","",names(Dat_day_clusters_hourly_mean)[!"cluster" == names(Dat_day_clusters_hourly_mean)])
        
        Dat_day_clusters_hourly_mean<-as.data.frame(t(Dat_day_clusters_hourly_mean))
        names(Dat_day_clusters_hourly_mean)<-clusters
        Dat_day_clusters_hourly_mean<-Dat_day_clusters_hourly_mean[-1,]
        Dat_day_clusters_hourly_mean$hours<-hours
        
        Dat_day_clusters_hourly_sd<-as.data.frame(t(Dat_day_clusters_hourly_sd))
        names(Dat_day_clusters_hourly_sd)<-clusters
        Dat_day_clusters_hourly_sd<-Dat_day_clusters_hourly_sd[-1,]
        Dat_day_clusters_hourly_sd$hours<-hours
        
        Dat_day_clusters_hourly_q05<-as.data.frame(t(Dat_day_clusters_hourly_q05))
        names(Dat_day_clusters_hourly_q05)<-clusters
        Dat_day_clusters_hourly_q05<-Dat_day_clusters_hourly_q05[-1,]
        Dat_day_clusters_hourly_q05$hours<-hours
        
        Dat_day_clusters_hourly_q95<-as.data.frame(t(Dat_day_clusters_hourly_q95))
        names(Dat_day_clusters_hourly_q95)<-clusters
        Dat_day_clusters_hourly_q95<-Dat_day_clusters_hourly_q95[-1,]
        Dat_day_clusters_hourly_q95$hours<-hours
      }
      
      # Load profiles based on mean and standard deviation
      {
        for (k in 1:optimal_k){
          plot(Dat_day_clusters_hourly_mean$hours,
               Dat_day_clusters_hourly_mean[,k],
               type="l",
               ylim=c(0,1),
               xlab="hour", ylab="normalized load (0-1)", main= paste("Variation range (mean & std.dev), cluster", k))
          lines(Dat_day_clusters_hourly_mean$hours,
                Dat_day_clusters_hourly_mean[,k]-1.95*Dat_day_clusters_hourly_sd[,k])
          lines(Dat_day_clusters_hourly_mean$hours,
                Dat_day_clusters_hourly_mean[,k]+1.95*Dat_day_clusters_hourly_sd[,k])
          
          subset<-Dat_day_normalized[Dat_day_normalized$cluster==k,]
          subset<-subset[,!names(subset)=="cluster"]
          for (j in 1:length(subset$DATE))
          {
            points(Dat_day_clusters_hourly_mean$hours,subset[j,-1]) 
          }
        }
      
        
        setwd(paste(WD, "output", sep="/"))
        for (k in 1:optimal_k){
          jpeg(paste("08_ClusterN",k,"_001.jpg",sep=""), width = 800, height = 600)
          plot(Dat_day_clusters_hourly_mean$hours,
               Dat_day_clusters_hourly_mean[,k],
               type="l",
               ylim=c(0,1),
               xlab="hour", ylab="normalized load (0-1)", main= paste("Variation range (mean & std.dev), cluster", k))
          lines(Dat_day_clusters_hourly_mean$hours,
                Dat_day_clusters_hourly_mean[,k]-1.95*Dat_day_clusters_hourly_sd[,k])
          lines(Dat_day_clusters_hourly_mean$hours,
                Dat_day_clusters_hourly_mean[,k]+1.95*Dat_day_clusters_hourly_sd[,k])
          
          subset<-Dat_day_normalized[Dat_day_normalized$cluster==k,]
          subset<-subset[,!names(subset)=="cluster"]
          for (j in 1:length(subset$DATE))
          {
            points(Dat_day_clusters_hourly_mean$hours,subset[j,-1]) 
          }
          dev.off()
        }
        setwd(WD)
      }
      
      # Load profiles based on quantiles
      {
        for (k in 1:optimal_k){
          plot(Dat_day_clusters_hourly_mean$hours,
               Dat_day_clusters_hourly_mean[,k],
               type="l",
               ylim=c(0,1),
               xlab="hour", ylab="normalized load (0-1)", main= paste("Variation range (5-95% quantiles), cluster", k))
          lines(Dat_day_clusters_hourly_mean$hours,
                Dat_day_clusters_hourly_q05[,k])
          lines(Dat_day_clusters_hourly_mean$hours,
                Dat_day_clusters_hourly_q95[,k])
          
          subset<-Dat_day_normalized[Dat_day_normalized$cluster==k,]
          subset<-subset[,!names(subset)=="cluster"]
          for (j in 1:length(subset$DATE))
          {
            points(Dat_day_clusters_hourly_mean$hours,subset[j,-1]) 
          }
        }

        setwd(paste(WD, "output", sep="/"))
        for (k in 1:optimal_k){
          jpeg(paste("08_ClusterN",k,"_002.jpg",sep=""), width = 800, height = 600)
          plot(Dat_day_clusters_hourly_mean$hours,
               Dat_day_clusters_hourly_mean[,k],
               type="l",
               ylim=c(0,1),
               xlab="hour", ylab="normalized load (0-1)", main= paste("Variation range (5-95% quantiles), cluster", k))
          lines(Dat_day_clusters_hourly_mean$hours,
                Dat_day_clusters_hourly_q05[,k])
          lines(Dat_day_clusters_hourly_mean$hours,
                Dat_day_clusters_hourly_q95[,k])
          
          subset<-Dat_day_normalized[Dat_day_normalized$cluster==k,]
          subset<-subset[,!names(subset)=="cluster"]
          for (j in 1:length(subset$DATE))
          {
            points(Dat_day_clusters_hourly_mean$hours,subset[j,-1]) 
          }
          dev.off()
        }
        setwd(WD)
      }
    }
    
    # clean
    rm(Dat_day_clusters_hourly_mean, Dat_day_clusters_hourly_q05, Dat_day_clusters_hourly_q95, Dat_day_clusters_hourly_sd, subset, hours, j, k)
  }
}