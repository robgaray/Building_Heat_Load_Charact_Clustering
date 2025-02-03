# Create a data frame with the required information
{
  # Summarize data by daily values
  {
    Dat_day_CART <- Dat %>%
      # Add a new column extracting only the date (without time) from the DATE variable
      mutate(DATE = as.Date(DATE)) %>%
      # Group by the daily date and other categorical variables of interest
      group_by(DATE, DATE_day_year, DATE_day_week, DATE_weekday, Holiday) %>%
      # Summarize the data
      summarize(
        Temperature = mean(Temperature, na.rm = TRUE), # Average daily temperature
        Solar_Irradiation = sum(Solar.Irradiation, na.rm = TRUE), # Total (Cumulated) daily solar irradiation
        .groups = "drop" # Ungroup after summarizing
      )
  }
  
  # Merge with cluster information from the previous process
  {
    # Join the summarized daily data with the other dataframe
    Dat_day_CART <- Dat_day_CART %>%
      # Join with 'other_data' on the DATE_day column
      left_join(
        Dat_day_clean %>% select(DATE, cluster),
        by = c("DATE_day_year" = "DATE")
      )
    # Ensure that all the observations have data from both processes
    Dat_day_CART<-Dat_day_CART[complete.cases(Dat_day_CART),]
  }
  
  # Convert variables to appropriate types (factors)
  {
    Dat_day_CART$Holiday <- as.factor(Dat_day_CART$Holiday)
    Dat_day_CART$cluster <- as.factor(Dat_day_CART$cluster)  
  }
}

# Attribute clusters
{
  # Split the dataset into training and testing sets
  train_index <- createDataPartition(Dat_day_CART$cluster, p = 0.8, list = FALSE)  # 80% training data
  train_data <- Dat_day_CART[train_index, ]  # Subset for training data
  test_data <- Dat_day_CART[-train_index, ]  # Subset for testing data
  
  # Build the CART model
  # We are predicting 'cluster' based on other predictors such as 'Temperature', 'Solar_Irradiation', etc.
  cart_model <- rpart(cluster ~ Temperature + Solar_Irradiation + Holiday + DATE_day_year + DATE_day_week + DATE_weekday,
                      data = train_data,
                      method = "class",       # 'method = "class"' indicates classification problem
                      control = rpart.control(
                        cp = 0.01,            # Complexity parameter to control tree size (larger values = simpler tree)
                        minsplit = 5,         # Minimum number of observations required in a node before splitting
                        minbucket = 5,        # Minimum number of observations required in a terminal node
                        maxdepth = 5          # Limit the depth of the tree (depth > 10 might overfit)
                      )
  )
  
  # Predict the cluster and write it into the data frame
  {
    Dat_day_CART$cluster_PRED <- predict(cart_model, Dat_day_CART, type = "class")
  }
  
}

# Inspection
{
  # Evaluate the model on the test set
  {
    # Make predictions on the test data
    predictions <- predict(cart_model, test_data, type = "class")
    
    # Create a confusion matrix to evaluate the model
    confusion_matrix <- confusionMatrix(predictions, test_data$cluster)  
    print(confusion_matrix)  
    
    setwd(paste(WD, "output", sep="/"))
    write.csv(as.data.frame(confusion_matrix[[4]]),"09_confusion_matrix.csv")
    setwd(WD)
  }
  
  # Visualize the decision tree
  rpart.plot(cart_model, main = "CART Decision Tree", type = 3, extra = 101)  
  
  setwd(paste(WD, "output", sep="/"))
  jpeg("09_cart_model001.jpg", width = 800, height = 600)
  rpart.plot(cart_model, main = "CART Decision Tree", type = 3, extra = 101)  
  dev.off()
  setwd(WD)
  
  # Some plots
  {
    plot(Dat_day_CART$DATE,Dat_day_CART$cluster,
         xlab="Date", ylab="Cluster")
    points(Dat_day_CART$DATE,Dat_day_CART$cluster_PRED,col="red")
    
    setwd(paste(WD, "output", sep="/"))
    jpeg("09_cart_model002.jpg", width = 800, height = 600)
    plot(Dat_day_CART$DATE,Dat_day_CART$cluster,
         xlab="Date", ylab="Cluster")
    points(Dat_day_CART$DATE,Dat_day_CART$cluster_PRED,col="red")
    dev.off()
    setwd(WD)
    
    plot(Dat_day_CART$DATE,Dat_day_CART$cluster==Dat_day_CART$cluster_PRED,
         xlab="Date", ylab="Cluster")
    
    setwd(paste(WD, "output", sep="/"))
    jpeg("09_cart_model003.jpg", width = 800, height = 600)
    plot(Dat_day_CART$DATE,Dat_day_CART$cluster==Dat_day_CART$cluster_PRED,
         xlab="Date", ylab="Cluster")
    dev.off()
    setwd(WD)
  }
}

rm(confusion_matrix,test_data,train_data,train_index,predictions,solstice_day)
