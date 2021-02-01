library(tidyverse)

acs_url <- "https://raw.githubusercontent.com/JosiahParry/uitk/master/data-raw/acs_edu.csv"

# Step 1. Read the data
acs_edu <- read_csv(acs_url)

# Step 2. Create the model
housing_model <- lm(med_house_income ~ bach + white, data = acs_edu)

# Step 3. Make predictions from model
to_predict <- data.frame(bach = 1, white = 0)

predict(housing_model, to_predict)

# Step 4. Create a function for model predictions.
pred_income <- function(prop_white, attain_edu_rate) {
  
  to_predict <- data.frame(bach = attain_edu_rate, white = prop_white)
  
  predict(housing_model, to_predict)
}

pred_income(1, 1)

# Step 5. Save our model for future use. 
write_rds(housing_model, "housing-model.rds")
