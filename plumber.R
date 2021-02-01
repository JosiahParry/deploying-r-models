library(plumber)

housing_model <- readr::read_rds("housing-model.rds")

#* @apiTitle Boston Median Household Income Predictions

#* @apiDescription This API servers up predictions of median household income based on the Bachelor's attainment rate and the proportion of individuals who identify as white for a given census tract in Boston. 

#* @param prop_white The proportion of individuals in a census tract who identify as white. Must be between 0 and 1.
#* @param attain_edu_rate The proportion of individuals in a census tract who have at least a Bachelor's degree. Must be between 0 and 1.

#* @get /median-income
function(prop_white, attain_edu_rate) {
  
  to_predict <- data.frame(bach = as.numeric(attain_edu_rate),
                           white = as.numeric(prop_white))
  
  predict(housing_model, to_predict)
  
}
