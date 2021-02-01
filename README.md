Putting R models into production
================

## Videos:

-   [Pt. 1 The
    concepts](https://www.youtube.com/watch?v=w4yHEQWct20&list=PLL9TGqB5UVHtC3V5Qhw_RY9UXiE6rCC8Q&index=1&ab_channel=JosiahParry)
-   [Pt. 2 Making
    functions](https://www.youtube.com/watch?v=Iqzu5SLpOeg&list=PLL9TGqB5UVHtC3V5Qhw_RY9UXiE6rCC8Q&index=2&t=481s&ab_channel=JosiahParry)
-   [Pt. 3 Turning your functions into an
    API](https://www.youtube.com/watch?v=oPC5OTeQYgw&feature=youtu.be&ab_channel=JosiahParry)
-   [Pt. 4 Calling your own API](https://youtu.be/NywS_eYCWPk)
-   Pt. 5 Deploy to RStudio Connect

# Pt. 1 - The conceptual bits

## The scenario:

You’ve made a model in R and you want to enable other systems to use
your model in production.

How do you put the model in production?

## The challenge:

Other tools and systems that will leverage your model will not know R or
be able to call it directly.

## The Solution:

Creating a REST API that serves predictions from your model.

## Okay, but what is an API?

-   Application Programming Interface

-   A way for computers to talk to other computers

-   RESTful APIs speak with HTTP

    -   Hyper text transfer protocol (the thing the internet uses)

    -   Think of HTTP as a universal language

### Why an API, though?

-   Most—if not all software languages—speak HTTP

-   No care for what is “under the hood”

-   You can make changes to the model without affecting the other
    systems using it

    -   Unless you change the output format or other breaking changes

## Anatomy of an API:

-   Host (fixed) e.g. `https://api.hostname.com/`

-   Endpoint (varied) e.g. `https://api.hostname.com/endpoint`

    -   Endpoints are like a function
    -   Determines what will happen

-   Parameters (optional)
    e.g. `https://api.hostname.com/endpoint/?param=value`

    -   Think of these like function arguments
    -   Addresses varying parts of a request

## Types of API requests:

-   Each API endpoint has a different request **method**

-   **GET** requests are used to retrieve data

    -   Takes parameters only
    -   All information is contained in the URL
    -   (Don’t send sensitive information via GET!)

-   **POST** requests are used for sending data (files, text, data,
    etc.)

    -   Can be used for creating or modifying something.

    -   Very flexible request type

-   Other methods that are used:

    -   PUT
    -   DELETE (yikes!)
    -   HEAD
    -   PATCH
    -   and more…

# Pt. 2 - Making functions

## How can I do this in R?

Plumber, that is how.

-   Plumber turns an R function into an API.
-   It uses special code comments—like {roxygen2}—to turn the functions
    into API endpoints

## Function review

-   Functions are code shortcuts

-   A special kind of object

-   Use arguments as placeholders

-   Whatever is printed last is returned

    ``` r
    my_fun <- function(argument) {
      # do something with the argument
      argument
    }

    my_fun("Spits out whatever it is given")
    ```

        ## [1] "Spits out whatever it is given"

-   Remember how I said you can think of API parameters like function
    arguments? 😏

## Creating useful functions

-   Identify the values that will be changing or up to the users
    discretion
-   We’re going to use some data from the Boston Area Research
    Initiative [(BARI)](https://cssh.northeastern.edu/bari/) for an
    example

``` r
library(tidyverse)

acs_url <- "https://raw.githubusercontent.com/JosiahParry/uitk/master/data-raw/acs_edu.csv"

acs_edu <- read_csv(acs_url)

filter(acs_edu, med_house_income > 90000)
```

    ## # A tibble: 472 x 7
    ##    med_house_income less_than_hs hs_grad some_coll  bach white   black
    ##               <dbl>        <dbl>   <dbl>     <dbl> <dbl> <dbl>   <dbl>
    ##  1           105735       0.0252  0.196      0.221 0.325 0.897 0.0122 
    ##  2            97417       0.0625  0.254      0.227 0.284 0.969 0.00710
    ##  3            91469       0.0337  0.203      0.263 0.305 0.865 0.00523
    ##  4           110765       0.0548  0.152      0.185 0.312 0.605 0.0338 
    ##  5            92250       0.0228  0.166      0.194 0.254 0.939 0.00548
    ##  6            99167       0.0504  0.263      0.291 0.236 0.921 0.00666
    ##  7            97700       0.0357  0.232      0.230 0.289 0.848 0.0924 
    ##  8            90139       0.0709  0.271      0.282 0.214 0.902 0.0261 
    ##  9            90102       0.0555  0.155      0.249 0.250 0.810 0.00544
    ## 10           105625       0.0719  0.0523     0.229 0.242 0.587 0.0741 
    ## # … with 462 more rows

-   Things that change should become arguments
-   For example filtering the dataset based on median household income:

``` r
filter_acs <- function(min_house_inc) {
  
  # min_house_inc acts as a placeholder
  # passes the value into the filter function
  filter(acs_edu, med_house_income > min_house_inc)

  }

# call the function
filter_acs(225000)
```

    ## # A tibble: 2 x 7
    ##   med_house_income less_than_hs hs_grad some_coll  bach white black
    ##              <dbl>        <dbl>   <dbl>     <dbl> <dbl> <dbl> <dbl>
    ## 1           250001            0  0         0      0.409 1         0
    ## 2           228438            0  0.0194    0.0781 0.368 0.856     0

## Model prediction function

-   In the case of models, this will be prediction inputs

-   Take `predict()` for linear models the arguments are:

    -   `predict(object, newdata)`
    -   In this case what will change is `newdata`

-   We will first need to create the model

-   Example model will be predicting median household income based on
    the bachelor degree attainment rate and how white a census tract is.

``` r
housing_model <- lm(med_house_income ~ bach + white, data = acs_edu)

summary(housing_model)
```

    ## 
    ## Call:
    ## lm(formula = med_house_income ~ bach + white, data = acs_edu)
    ## 
    ## Residuals:
    ##     Min      1Q  Median      3Q     Max 
    ## -104611  -14700   -2204   11829  124296 
    ## 
    ## Coefficients:
    ##             Estimate Std. Error t value Pr(>|t|)    
    ## (Intercept)     7067       2131   3.317 0.000932 ***
    ## bach          209814       7643  27.450  < 2e-16 ***
    ## white          32805       3017  10.875  < 2e-16 ***
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## Residual standard error: 24690 on 1453 degrees of freedom
    ## Multiple R-squared:  0.5091, Adjusted R-squared:  0.5084 
    ## F-statistic: 753.3 on 2 and 1453 DF,  p-value: < 2.2e-16

-   We’ve got a model, but now we need to make predictions.

    -   To make predictions the `predict()` function will need a data
        frame to predict against.

``` r
to_predict <- data.frame(bach = .75, white = .5)

predict(housing_model, to_predict)
```

    ##        1 
    ## 180830.1

-   We want to easily make predictions for different values of `bach`
    and `white`.

    -   `bach` and `white` are the values which will change and as such
        should become the `arguments`

-   To make a prediction function:

    1.  copy and paste the above lines of code into the function
        **body**—the part between the curly braces.
    2.  Replace the hard coded values with the function argument names

``` r
pred_income <- function(bach_edu_rate, prop_white) {
  
  # create data frame to predict against
  to_predict <- data.frame(bach = bach_edu_rate, white = prop_white)

  # create prediction
  predict(housing_model, to_predict)
}
```

-   Now we’ve got a function to use! Let’s try it out.

``` r
pred_income(.75, .5)
```

    ##        1 
    ## 180830.1

# Pt. 3 - Making an API with plumber

## Outline:

-   Now that we have the ability to create a function that serves
    predictions from a model we will be able to create the API

-   The process to build the API will consist of:

    1.  Serializing the model (saving it as a file)
    2.  Creating a `plumber.R` file
    3.  Define model prediction endpoint
    4.  Serve the API

## Building a simple API endpoint

-   With your prediction function, you’re 90% of the way there to making
    the API
-   The final API looks like

``` r
library(plumber)

housing_model <- readr::read_rds("housing-model.rds")  

#* @apiTitle Boston Median Household Income Prediction

#* @apiDescription Predict the median household income of a census tract based in the Bachelor's degree attainment rate and the racial diversity.

#* @param bach_edu_rate Bachelor's degree attainment rate of a census tract. Between 0 and 1.
#* @param prop_white The proportion of the population that identifies as white. Between 0 and 1.

#* @get /median-income
function(bach_edu_rate = 0, prop_white = 0) {
  
  to_predict <- data.frame(bach = as.numeric(bach_edu_rate),
                           white = as.numeric(prop_white))
  
  predict(housing_model, to_predict)
}
```

    ## function(bach_edu_rate = 0, prop_white = 0) {
    ##   
    ##   to_predict <- data.frame(bach = as.numeric(bach_edu_rate),
    ##                            white = as.numeric(prop_white))
    ##   
    ##   predict(housing_model, to_predict)
    ## }

-   Let’s work backwards from here

## Anatomy of a Plumber API

-   Uses roxygen-like commenting `#*` to document

-   `#*` is followed by **tags**

-   Tags look like `@tagName`

-   End points are defined by the appropriate method tag and endpoint
    name

    -   e.g. `@get /predict`

-   Endpoint functionality is defined by an unassigned function
    immediately following the endpoint name

-   Code outside of a function can be considered **global**

-   

------------------------------------------------------------------------

Now that you’ve created a model it needs to be saved as a serialized R
object. You can do this with the function `readr::write_rds()` .

``` r
write_rds(housing_model, "housing-model.rds")
```
