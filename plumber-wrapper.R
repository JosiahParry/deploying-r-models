library(httr)

# run the API in a background job for API wrapper development

b_url <- "http://127.0.0.1:5022/median-income"

params <- list(prop_white = 0.75, attain_edu_rate = 0.75)

query_url <- modify_url(url = b_url, query = params)

resp <- GET(query_url)

content(res)

jsonlite::fromJSON(resp_raw)

get_incom_pred <- function(prop_white, edu_rate) {}
