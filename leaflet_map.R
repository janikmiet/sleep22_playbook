## duckdb: get database -----
con <- dbConnect(duckdb::duckdb(), dbdir="data/sleep22_calculator.duckdb", read_only=TRUE)
duckdb::dbListTables(conn = con)

## Base map -----
# Center point
# 54.1384668053237, 19.632137995418812
m <- leaflet() %>% setView(lng = 19.632137995418812, lat = 54.1384668053237, zoom = 4)
m %>% addTiles()


## Polygons -----
# download.file("http://thematicmapping.org/downloads/TM_WORLD_BORDERS_SIMPL-0.3.zip" , destfile="data/map/world_shape_file.zip")
## You now have it in your current working directory, have a look!
## Unzip this file. You can do it with R (as below), or clicking on the object you downloaded.
# system("unzip data/map/world_shape_file.zip")
##  -- > You now have 4 files. One of these files is a .shp file! (TM_WORLD_BORDERS_SIMPL-0.3.sh

# Read this shape file with the rgdal library. 
library(rgdal)
world_spdf <- readOGR( 
  dsn= paste0(getwd(),"/data/map/") , 
  layer="TM_WORLD_BORDERS_SIMPL-0.3",
  verbose=FALSE
)

## Countries in our data
countries <- tbl(con, "summary_slapnea_costs") %>% 
  group_by(location_name) %>% 
  summarise(1) %>% 
  collect()
countries <- countries$location_name

## Countries in world data
sort(world_spdf$NAME)

## Rename few countries in world data and subset
world_spdf$NAME[world_spdf$NAME == "The former Yugoslav Republic of Macedonia"] <- "Macedonia"
world_spdf$NAME[world_spdf$NAME == "Republic of Moldova" ] <- "Moldova"
europe_spdf <- subset(world_spdf, world_spdf$NAME %in% countries)
countries[!countries %in% europe_spdf$NAME]

## Try to map
leaflet(europe_spdf) %>%
  setView(lng = 19.632137995418812, lat = 54.1384668053237, zoom = 3) %>% 
  addTiles() %>% 
  addPolygons(color = "#444444", weight = 1, smoothFactor = 0.5,
              opacity = 1.0, fillOpacity = 0.5,
              highlightOptions = highlightOptions(color = "white", weight = 2,
                                                  bringToFront = TRUE))
## Insert costs data to europe_spdf
tbl(con, "summary_slapnea_costs") %>% 
  collect() -> d1

d <- sp::merge(europe_spdf, d1, by.x="NAME", by.y="location_name")

## disconnect duckdb
dbDisconnect(con, shutdown=TRUE)

## Write to calculation database
saveRDS(d, file = "data/slapnea22.RDS")

slapnea22 <- d

## Create a color palette with handmade bins.
library(RColorBrewer)
mybins <- c(0,800,1600,2400,3200,Inf)
mypalette <- colorBin( palette="YlOrBr", domain=slapnea22@data$POP2005, na.color="transparent", bins=mybins)

# Prepare the text for tooltips:
mytext <- paste(
  "<b> ", d@data$NAME,"</b> <br/>", 
  "Population (15-74yrs): ", round(d@data$pop_female + d@data$pop_male, 0),"<br/>", 
  "<b> Cost per patient </b> <br/>",
  "Direct: ", round(d@data$patient_direct_cost, 0), "€ <br/>",
  "Non-healthcare: ", round(d@data$patient_nonhealthcare_cost, 0), "€ <br/>",
  "Productivity: ", round(d@data$patient_productivity_cost, 0), "€<br/>",
  "Total: ", round(d@data$patient_total_cost, 0), "€", 
  sep="") %>%
  lapply(htmltools::HTML)

## With costs data
leaflet(d) %>%
  setView(lng = 19.632137995418812, lat = 54.1384668053237, zoom = 3) %>% 
  # addTiles() %>% 
  addPolygons(color = "#444444", 
              weight = 1,  # 0.3,
              smoothFactor = 0.5,
              opacity = 1.0, 
              fillColor = ~mypalette(patient_total_cost),
              highlightOptions = highlightOptions(color = "white", 
                                                  weight = 2,
                                                  bringToFront = TRUE),
              stroke=TRUE, 
              fillOpacity = 0.9, #0.5
              label = mytext,
              labelOptions = labelOptions( 
                style = list("font-weight" = "normal", padding = "3px 8px"), 
                textsize = "13px", 
                direction = "auto"
              )) %>%
  addLegend(pal=mypalette, 
    values=~patient_total_cost, opacity=0.9, title = "Patient cost", position = "bottomleft" )


### costs bar plot -----
library(ggplot2)
library(dplyr)
library(tidyr)

slapnea22 %>% 
  filter(location_name == "Finland") %>% 
  select(location_name, patient_direct_cost, patient_nonhealthcare_cost, patient_productivity_cost) %>% 
  pivot_longer(c(patient_direct_cost, patient_nonhealthcare_cost, patient_productivity_cost)) -> dplot



ggplot(data = dplot) +
  geom_bar(aes(x=reorder(name, -value), y=value, fill=name), stat="identity") +
  labs(x="", 
       y="euros", 
       fill="",
       title="Costs by classes",
       subtitle = "") +
  hrbrthemes::theme_ipsum() +
  scale_fill_brewer(palette = "Set2", labels=c('Direct healthcare cost', 'Direct non-helthcare cost', 'Productivity losses')) +
  scale_x_discrete(labels=c('Direct healthcare cost', 'Direct non-helthcare cost', 'Productivity losses')) +
  scale_y_continuous(expand = c(0,0)) +
  theme(plot.caption = element_text(hjust = 0, face= "italic"), #Default is hjust=1
        plot.title.position = "plot", #NEW parameter. Apply for subtitle too.
        plot.caption.position =  "plot",
        legend.position = "none")  #NEW parameter


## Cost bar plot all locations -----

slapnea22 %>% 
  select(location_name, patient_direct_cost, patient_nonhealthcare_cost, patient_productivity_cost) %>% 
  pivot_longer(c(patient_direct_cost, patient_nonhealthcare_cost, patient_productivity_cost)) -> dplot

## Barplot of the costs
## Create a bar plot by countries
ggplot(data = dplot) +
  geom_bar(aes(x=reorder(location_name, value), y=value, fill=name), stat="identity") +
  coord_flip() +
  labs(x="", 
       y="euros", 
       fill="",
       title="Costs  by countries",
       subtitle = "Patient direct healthcare, direct non-healthcare and productivity lost costs") +
  hrbrthemes::theme_ipsum() +
  # scale_fill_discrete(labels=c('Direct healthcare cost', 'Direct non-helthcare cost', 'Productivity losses')) +
  scale_fill_brewer(palette = "Set2", labels=c('Direct healthcare cost', 'Direct non-helthcare cost', 'Productivity losses')) +
  scale_y_continuous(expand = c(0,0)) +
  theme(plot.caption = element_text(hjust = 0, face= "italic"), #Default is hjust=1
        plot.title.position = "plot", #NEW parameter. Apply for subtitle too.
        plot.caption.position =  "plot",
        legend.position = "right")  #NEW parameter
