#clean MAPS BIRD DATA

library(tidyverse)
library(spData)
library(sf)
library(lubridate)
library(plyr)
library(Ostats)
library(ggplot2)
devtools::install_github('NEON-biodiversity/Ostats')

#loading R data file for maps data
load("./data/MAPSexport.Rdata")

#make a tibble
dat<-lapply(maps.data, as_tibble)

rm(maps.data)#why remove maps data because its o big and will slow things down? Ask Daijiang

head(dat)

dat$band#this is the individual level data




#############################################################################
#data formatting for OSTATS (FROM data_format.R script)
head(dat$band)

#works to get species counts per site (combining across years for now) and filter out sites with < 2 species
bird_site_filt<-ddply(dat$band, .(STATION), mutate,  count = length(unique(SPEC)))%>%#get species counts per station (over time)
                      mutate(Spec_Stat = paste(SPEC, STATION, sep = "_"))%>% #Spec_Stat is the station/species combo 
                      filter(count >1)

head(bird_site_filt)

#there are no sites with only one species
length(unique(dat$band$STATION))#n=946
length(unique(bird_site_filt$STATION))#n=946


#Figure out which sites/species combos have less than 5 individuals and filter them out

hi_abund<-bird_site_filt %>%
  dplyr::count(Spec_Stat) %>%
  filter(n>4)

#filter(n <4) #will allow to filter out all sites that have a species with <5 individuals. problem is, that all but 2 sites...


#use group by and then count, same result as line above
#bird_site_filt %>% group_by(STATION, SPEC) %>%   dplyr::summarise(n = n())

#filter(n <4) #will allow to filter out all sites that have a species with <5 individuals. problem is, that all but 2 sites...

#take data only for species that have >4 individuals
bird_site_input<-bird_site_filt[bird_site_filt$Spec_Stat %in% hi_abund$Spec_Stat, ]

length(unique(hi_abund$Spec_Stat))
length(unique(bird_site_input$Spec_Stat))


#prep data for OSTATs----


#subset number of stations to run in reasonable time... 
sub_station<-unique(bird_site_input$STATION)[1:50]

dat_in <- bird_site_input %>%
  filter(STATION %in% sub_station)%>% 
  select(STATION, SPEC, WEIGHT) %>%
  filter(!is.na(WEIGHT)) %>%
  mutate(log_WEIGHT = log10(WEIGHT))



# Group the data by Station and Species and look at the summary (why? ask quentin or Daijiang)
dat_in %>%
  group_by(STATION, SPEC) %>%
  slice(1)

#look at data that is input for OSTATS functions
head(dat_in)


####run Ostats function: copied from vignette####

Ostats_example <- Ostats(traits = as.matrix(dat_in[,'log_WEIGHT']),
                         sp = factor(dat_in$SPEC),
                         plots = factor(dat_in$STATION),
                         data_type = "linear",
                         nperm = 1)

Ostats_example
#make ostats a data frame

ostats_output<-as.data.frame(Ostats_example)

#make a data frame of site richness
site_richness<-bird_site_filt %>% 
  distinct(STATION, count)

#give Ostats output a site id column from the current rownames

final_output<-ostats_output%>%
  mutate(STATION= row.names(ostats_output))%>%#give Ostats output a site id column from the current rownames
  left_join(.,site_richness, by = "STATION") #join site data to ostats_output

#rename(final_output, SITE = STATION)

mod<-lm(overlaps_norm~count, data=final_output)
summary(mod)

plot(final_output$count,final_output$overlaps_norm)
#need code here to save out OSTATS


#get inputs for the plot function
sites2use<-c('0004','7MIL', 'ADNO')
sites2use<-c(unique(dat_in$STATION))
plots <- dat_in$STATION
sp <- dat_in$SPEC
traits <- dat_in$log_WEIGHT

Ostats_plot(plots = plots, sp = sp, traits = traits,
            overlap_dat = final_output,
            use_plots = sites2use, means = TRUE)

Ostats_plot(plots = plots, sp = sp, traits = traits,
            overlap_dat = final_output,
             means = TRUE)
?Ostats_plot


ostat_norm[rownames(ostat_norm) %in% use_plots, ]



Ostats_plot(plots = dat_in$STATION, sp = dat_in$SPEC, traits = dat_in$log_WEIGHT,
            overlap_dat = Ostats_example,
            use_plots = sites2use, means = TRUE)

