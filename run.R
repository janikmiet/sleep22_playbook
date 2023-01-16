## Renders files and uploads
## !USER SPECIFIC!

# ## Select which chapters runs code ----
# if(TRUE){
#   ## 01-Flatfiles
#   eval_pop = FALSE
#   eval_IHME = FALSE
#   ## 02-Database
#   eval_loadflat=FALSE
#   eval_dbsave = FALSE
#   ## 03-EDA
#   eval_exploreihme <- TRUE #FALSE
#   ## 04-Calculations
#   eval_prevalences_savedb = FALSE
#   eval_costs_savedb = FALSE
#   ## 05-Results
#   
# }

## Render book ----
if(TRUE){
  if(dir.exists("temp")) fs::dir_delete("temp")
  if(!dir.exists("temp")) dir.create("temp")
  file.copy(from = c(
    "index.Rmd",
    "01-flatfiles.Rmd",
    "02-database.Rmd",
    "03-eda.Rmd",
    "04-newdb.Rmd",
    "05-results.Rmd",
    "06-interactive.Rmd",
    "09-about.Rmd",
    "global.R",
    "site.yaml",
    "data/",
    "files/",   ## TODO how to use datasets without copying?
    "img/"
  ),
  to = "temp", 
  overwrite = TRUE,
  recursive = TRUE)
  
  bookdown::serve_book(dir = here::here("temp"),
                       output_dir = here::here("docs"))
}

## Run dataexplorer render ----
if(FALSE){
  # install.packages("DataExplorer")
  ## load data first manually!!!! check 02-database.rmd for more information.
  DataExplorer::create_report(ihme, output_dir = "docs/reports/", output_file = "report_ihme.pdf")
  DataExplorer::create_report(pop, output_dir = "docs/reports/", output_file = "report_pop.pdf")
}

## Move to kapsi ----
if(TRUE){
  system("scp -r ./docs/* janikmiet@kapsi.fi:/home/users/janikmiet/sites/research.janimiettinen.fi/www/material/sleep22")
}
