# Fill 1h voids with observations available for interpolation
{
  STRING_date<-"DATE"
  VEC_vars<-c("Holiday",
              "Temperature",
              "Solar.Irradiation",
              "Power",
              "Power_fitted",
              "IS_Outlier")
  VEC_repair<-c("Power")
  
  Dat<-RG_Repair_1h_double_side (Dat,STRING_date,VEC_vars,VEC_repair)
  rm(STRING_date, VEC_vars, VEC_repair)
}

# Fill 5h voids with observations available for interpolation
{
  STRING_date<-"DATE"
  VEC_vars<-c("Holiday",
              "Temperature",
              "Solar.Irradiation",
              "Power",
              "Power_fitted",
              "IS_Outlier")
  VEC_repair<-c("Power")
  
  num_hours_max <- 5
  for (cont_num_hours in 2:num_hours_max)
  {
    num_hours<-cont_num_hours
    for (cont_num_hour_pre in 1: num_hours)
    {
      nh_pre<-cont_num_hour_pre
      nh_post<-num_hours+1-nh_pre
      Dat<-RG_Repair_multiple_h_double_side (Dat,STRING_date,VEC_vars,VEC_repair, nh_pre, nh_post)
    }
  }
  
  rm(STRING_date, VEC_vars, VEC_repair)
  rm(cont_num_hour_pre, cont_num_hours, nh_post, nh_pre, num_hours, num_hours_max)
}