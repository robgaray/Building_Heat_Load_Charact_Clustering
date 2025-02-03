p<-ggplot(Dat, aes(x = Power, y = Power_corrected)) +
  geom_point(aes(color = IS_Repaired)) +
  scale_color_manual(values = c("FALSE" = "black", "TRUE" = "red")) +
  labs(x = "Power [kh], original value",
       y = "Power [kh], corrected value") +
  theme_minimal() + 
  theme(
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA)
  )
print(p)
setwd(paste(WD, "output", sep="/"))
ggsave("06_repair001.jpg", plot = p, device = "jpeg", width = 6, height = 4, units = "in", dpi = 300)
setwd(WD)

rm(p)

p<-ggplot(Dat, aes(x = Temperature, y = Power_corrected)) +
  geom_point(aes(color = IS_Repaired)) +
  scale_color_manual(values = c("FALSE" = "black", "TRUE" = "red")) +
  labs(x = "Temperature",
       y = "Power") +
  theme_minimal() + 
  theme(
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA)
  )
print(p)
setwd(paste(WD, "output", sep="/"))
ggsave("06_repair002.jpg", plot = p, device = "jpeg", width = 6, height = 4, units = "in", dpi = 300)
setwd(WD)

rm(p)