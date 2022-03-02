library(readr)
library(tidyverse)

#Read all 2004 plate appearances by any player into a single file
#IF YOU ARE RECREATING THIS CHANGE "Retrosheet/" TO THE DIRECTORY LOCATION WHERE YOU HAVE DOWNLOADED THE 2004 RETROSHEET EVENT FILES
setwd("Retrosheet/")
retrofile <- list.files(pattern="")
testsheet <- retrofile %>% map_df(~read_csv(., 
                                            col_names = c("type","a","b","player","c","hitting")))

#isolate Barry Bonds plate appearances
bondsheet <- filter(testsheet,player == "bondb001")
bondsheet <- filter(bondsheet,is.na(hitting) == FALSE)
bondhit <- select(bondsheet,hitting)

#clean out some irrelevant plate appearance events
bondhit <- bondhit %>% map_df(str_remove_all, pattern = "([+*.123>])")

#split hit lines into separate cells (one hit per cell)
bondhit <- bondhit %>% separate(hitting, into = c(as.character(0:7)), 
                                sep = "", remove = TRUE)

#assign each plate appearance an EBV of 1 (to be diluted later)
bondhit$`0` <- rep(1,length(bondhit$`0`))

#coerce pitches into B, C, H, X, F
same_pitch_types <- function(hitting){
  for (i in 1:length(hitting)){
    for (j in 1:nrow(hitting)){
      if(hitting[[j,i]] %>% is.na() == FALSE){
        if (hitting[[j,i]] == "T"|hitting[[j,i]] == "L"){
          hitting[[j,i]] <- "F"
        } else if (hitting[[j,i]]=="S"){
          hitting[[j,i]] <- "C"
        } else if (hitting[[j,i]]=="I"){
          hitting[[j,i]] <- "B"
        }
      }
    }
  } 
  return(hitting)
}
bondhit <- same_pitch_types(bondhit)

#label EBV column and pitch columns, add strike and ball count columns
colnames(bondhit) <- c("EBV",1:7 %>% as.character())
bondhit$strike_count <- rep(0,length(bondhit$EBV))
bondhit$ball_count <- rep(0,length(bondhit$EBV)) 
bondhit <- bondhit %>% select(EBV,strike_count,ball_count,`1`,`2`,`3`,`4`,`5`,`6`,`7`)

#function that assigns HBP appearances an EBV of 1 and prevents 
#them from being re-analyzed
hbp_splitter <- function(hitline){
  for (i in 4:length(hitline)){
    if (hitline[,i] == "H" && is.na(hitline[,i])==FALSE){
      hitline <- tibble(
        EBV = c(1),
        strike_count = c(0),
        ball_count = c(0),
        `1` = c("H"),
        `2` = c("H"),
        `3` = c("H"),
        `4` = c("H"),
        `5` = c("H"),
        `6` = c("H"),
        `7` = c("H"))
    }
  }
  return(hitline)
}

#function that splits X and F pitches into B and C 
#with EBV multipliers of 0.809 and 0.191
swung_splitter <- function(hitline){
  hitline_dupe <- hitline
  for (i in 4:length(hitline)){
    hitline_dupe <- hitline
    if ((hitline[,i] == "F" | hitline[,i] == "X")
        && is.na(hitline[,i])==FALSE){
      hitline[,i] <- "C";
      hitline$EBV <- hitline$EBV*0.809;
      hitline_dupe[,i] <- "B";
      hitline_dupe$EBV <- hitline_dupe$EBV*0.191;
      hitline <- rbind(hitline, hitline_dupe)
    } 
  }
  return(hitline)
}

#function that splits empty cell values into B and C 
#with EBV multipliers of 0.413 and 0.587 
hit_maker <- function(hitline){
  for (i in 4:length(hitline)){
    hitline_dupe <- hitline
    if (is.na(hitline[,i]) == TRUE){
      hitline[,i] <- "C";
      hitline$EBV <- hitline$EBV*0.413;
      hitline_dupe[,i] <- "B";
      hitline_dupe$EBV <- hitline_dupe$EBV*0.587;
      hitline <- rbind(hitline, hitline_dupe)
    }
  }
  return(hitline)
}

#function that counts a plate appearance's balls and strikes in order, 
#assigns strikeouts an EBV of 0
ball_strike_counter <- function(hitline){
  for (j in 1:nrow(hitline)){
    for (i in 4:length(hitline)){
      if (hitline[j,3] == 4){
        break;
      };
      if (hitline[j,2] == 3){
        hitline[j,1] <- 0
        break;
      };
      if (hitline[j,i] == "C"){
        hitline[j,2] <- hitline[j,2]+1
      }
      if (hitline[j,i] == "B"){
        hitline[j,3] <-  hitline[j,3]+1
      }
    }
  }
  return(hitline)
}

#function that applies a column-wise function to each row in a table
row_applier <- function(df,func){
  big_dummy <- tibble(
    EBV = numeric(),
    strike_count = numeric(),
    ball_count = numeric(),
    `1` = character(),
    `2` = character(),
    `3` = character(),
    `4` = character(),
    `5` = character(),
    `6` = character(),
    `7` = character(),
  )
  for (i in 1:nrow(df)){
    dummy <- func(df[i,])
    big_dummy <-  rbind(dummy, big_dummy)
  }
  return(big_dummy)
}

#apply all the above functions to all 2004 Bonds plate appearances
bond_results <- row_applier(bondhit,hbp_splitter)
bond_results <- row_applier(bond_results,swung_splitter)
bond_results <- row_applier(bond_results,hit_maker)
bond_results <- bond_results %>% ball_strike_counter()

#sum the EBVs and divide by 613
final_obp <- sum(bond_results$EBV) / 613
final_obp
