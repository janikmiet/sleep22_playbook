
## TODO function to register multiple tables at once
# register_tbls <- function(con, df){
#   # names_df <- deparse(substitute(df))
#   # print(names_df)
#   for (i in 1:length(df)) {
#     # name <- deparse(substitute(i))
#     # df <- df[i]
#     nm <- deparse(substitute(df[i]))
#     print(nm)
#     # duckdb::duckdb_register(conn = con, name = nm, df = i) 
#   }
# }
# register_tbls(con, c(prevalences, pop, popu_info))

## TODO save to parquet all in once
# duckdb_to_parquet <- function(df){
#   for (i in df) {
#     df_name <- deparse(substitute(df[i]))
#     dbSendQuery(con, paste0("COPY (SELECT * FROM ", df_name,") TO 'data/parquet_shiny/", df_name,".parquet' (FORMAT 'parquet');"))  
#   }
# }