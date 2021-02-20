#! /usr/bin/env Rscript 

library(ggplot2)
library(purrr)
library(tidyverse)
library(broom)
library(glmnet)
library(caret)

setwd("~/ifs/loni/postdocs/rcabeen/shared/epibios/rat/data/level6")

read.single.table <- function(site, param)
{
  img.fn <- sprintf("tables/%s/%s.csv", site, param)

  df <- read.csv(img.fn)
  metrics <- names(df)[-which(colnames(df) %in% c("group", "id", "site", "subject", "tp"))]
  
  pte.fn <- sprintf("tables/%s/pte.csv", site)
  df <- merge(read.csv(pte.fn), df)
  df$status <- factor(df$status, levels = c("Sham", "TBI", "PTE"))

  # add the global mean
  df$global_mean <- rowMeans(df[,metrics], na.rm=TRUE)
  metrics <- c(metrics, "global_mean")

  return(list(df=df, metrics=metrics))
}

read.multi.table <- function(params, sites)
{
  out.metrics <- NULL
  out.df <- NULL
  
  for (param in params)
  {
    my.metrics <- NULL 
    sites.metrics <- NULL
    sites.df <- NULL 
  
    for (site in sites)
    {
      my.table <- read.single.table(site, param)
      sites.df <- rbind(sites.df, my.table$df)
      
      my.metrics <- my.table$metrics
      sites.metrics <- paste(param, my.metrics, sep=".")
    }
    
    for (metric in my.metrics)
    {
      names(sites.df)[names(sites.df) == metric] <- paste(param, metric, sep=".")
    }
  
    out.metrics <- c(out.metrics, sites.metrics)
    if (is.null(out.df))
    {
      out.df <- sites.df
    }
    else
    {
      out.df <- merge(out.df, sites.df[,c("subject", sites.metrics)], by="subject")
    }
  }
  
  long.df <- gather(out.df, metric, value, out.metrics, factor_key=TRUE)
  long.df <- subset(long.df, select = -c(subject) )
  wide.df <- spread(long.df, tp, value)
  wide.df[,"diff_9d_2d"]   <- wide.df[,"9d"]  - wide.df[,"2d"]
  wide.df[,"diff_30d_2d"]  <- wide.df[,"30d"] - wide.df[,"2d"]
  wide.df[,"diff_5mo_2d"]  <- wide.df[,"5mo"] - wide.df[,"2d"]
  wide.df[,"diff_30d_9d"]  <- wide.df[,"30d"] - wide.df[,"9d"]
  wide.df[,"diff_5mo_9d"]  <- wide.df[,"5mo"] - wide.df[,"9d"]
  wide.df[,"diff_5mo_30d"] <- wide.df[,"5mo"] - wide.df[,"30d"]
  wide.df[,"sum_9d_2d"]   <- wide.df[,"9d"]  + wide.df[,"2d"]
  wide.df[,"sum_30d_2d"]  <- wide.df[,"30d"] + wide.df[,"2d"]
  wide.df[,"sum_5mo_2d"]  <- wide.df[,"5mo"] + wide.df[,"2d"]
  wide.df[,"sum_30d_9d"]  <- wide.df[,"30d"] + wide.df[,"9d"]
  wide.df[,"sum_5mo_9d"]  <- wide.df[,"5mo"] + wide.df[,"9d"]
  wide.df[,"sum_5mo_30d"] <- wide.df[,"5mo"] + wide.df[,"30d"]
  wide.df[,"sum_30d_9d_2d"]  <- wide.df[,"30d"] + wide.df[,"sum_9d_2d"]
  wide.df[,"sum_5mo_30d_9d"]  <- wide.df[,"5mo"] + wide.df[,"sum_30d_9d"]
  wide.df[,"sum_all"]  <- wide.df[,"5mo"] + wide.df[,"sum_30d_9d_2d"]
  tps <- names(wide.df)[c(5:length(names(wide.df)))]
  
  for (tp in tps)
  {
    # use mean-imputation
    vals <- wide.df[,tp]
    nas <- is.na(vals)
    if (any(nas))
    {
      tryCatch(
      {
        wide.df[nas, tp] = mean(wide.df[,tp], na.rm=T)
      }, warning = function(w) {
          cat(sprintf("warning: timepoint %s, %s\n", tp, w))
      }, error = function(e) {
          cat(sprintf("error: timepoint %s, %s\n", tp, e))
      }, finally = {
      })
    }
  }
  
  long.df <- gather(wide.df, tp, value, tps, factor_key=TRUE)
  out.df <- spread(long.df, metric, value)
 
  for (tp in tps) 
  {
    for (region in out.metrics)
    {
      vals <- out.df[out.df$status=="TBI" & out.df$tp == tp,region]
      out.df[out.df$tp == tp,region] <- (out.df[out.df$tp == tp,region] - mean(vals)) / sd(vals)
    }
  }
  
  return(list(df=out.df, metrics=out.metrics))
}

run.classify <- function(name, params, sites, tp, tbi=FALSE, alpha=1)
{
  cat("processing case\n")
  cat("  name: ", name, "\n")
  cat("  params: ", params, "\n")
  cat("  sites: ", sites, "\n")
  cat("  timepoint: ", tp, "\n")
  
  tryCatch(
  {
    my.table <- read.multi.table(params, sites)
    df <- my.table$df 
    metrics <- my.table$metrics
    
    df <- df[df$tp %in% c(tp),]
   
    if (tbi) 
    {
      df <- df[!df$status %in% c("PTE"),]
      df$outcome <- df$status == "TBI"
    } else {
      df <- df[!df$status %in% c("Sham"),]
      df$outcome <- df$status == "PTE"
    }
    
    out.df = NULL
    numcv <- nrow(df)
    for (i in 1:numcv)
    {
      cat(sprintf("processing fold: %d of %d\n", i, numcv))
      train.df <- df[-i,]
      test.df <- df[i,]
      
      my.test.x <- as.matrix(test.df[,metrics])
      my.test.y <- as.factor(test.df$outcome)
      
      my.train.x <- as.matrix(train.df[,metrics])
      my.train.y <- as.factor(train.df$outcome)
      my.up <- caret::upSample(my.train.x, my.train.y)
      my.train.x <- as.matrix(my.up[,-ncol(my.up)])
      my.train.y <- my.up$Class
      
      my.fit.cv <- cv.glmnet(x=my.train.x, y=my.train.y, family="binomial", alpha=alpha, nfolds=nrow(train.df))
      my.pred <- predict(my.fit.cv, my.test.x, s="lambda.min")
      
      for (j in 1:length(my.pred))
      {
        out.df <- rbind(out.df, data.frame(
          pred=my.pred[j],
          ref=my.test.y[j],
          lamb=my.fit.cv$lambda.min,
          cvm=max(my.fit.cv$cvm)
        )) 
      }
    }
    
    my.lamb <- median(out.df$lamb)
    my.fit <- glmnet(x=my.train.x, y=my.train.y, lambda=my.lamb, family="binomial", alpha=alpha)
    my.coef <- coef(my.fit)
    my.coef.df <- as.data.frame(as.matrix(my.coef))
    my.coef.df$name <- row.names(my.coef)
    row.names(my.coef.df) <- NULL
    
    dir.create("classify")
    sink(sprintf("classify/%s.txt", name))
    cat("EPIBIOS Rodent PTE Classification Report\n")
    cat("\n")
    if (tbi)
    {
       cat("Task: Sham vs TBI\n") 
    }
    else
    {
       cat("Task: TBI vs PTE\n")
    }
    cat("\n")
    cat("Sites: \n")
    for (site in sites)
    {
      cat(sprintf("  %s\n", site))
    }
    cat("\n")
    cat(sprintf("Timepoint: %s\n", tp))
    cat("\n")
    cat("Parameters: \n")
    for (param in params)
    {
      cat(sprintf("  %s\n", param))
    }
    cat("\n")
    cat(sprintf("Median Lambda: %g\n", my.lamb))
    cat("\n")
    cat("Coefficients:\n")
    print(my.coef.df[which(my.coef.df$s0 != 0),])
    cat("\n")
    print(caret::confusionMatrix(data=as.factor(out.df$pred > 0), reference=as.factor(out.df$ref)))
    cat("\n")
    cat("End\n")
    sink()
  }, error = function(e) {
     cat(sprintf("ERROR: skipping case %s\n", e))
  }, finally = {
  })
}

my.tps <- c("2d", "9d", "30d", "5mo", "diff_9d_2d", "diff_30d_9d", "diff_5mo_30d", "sum_9d_2d", "sum_30d_9d", "sum_5mo_30d", "sum_al")

for (my.tp in my.tps)
{
  my.param <- "native.tract.bundles.dwi.harm.zscore.map.dti_FA_mean"
  run.classify(sprintf("PTE.Bundles.Finland.%s.%s", my.tp, my.param), c(my.param), c("Finland"), my.tp, tbi=FALSE)
  run.classify(sprintf("TBI.Bundles.Finland.%s.%s", my.tp, my.param), c(my.param), c("Finland"), my.tp, tbi=TRUE)
  
  my.params <- NULL
  my.params <- c(my.params, "native.tract.bundles.map.volume")
  my.params <- c(my.params, "native.tract.bundles.map.length_mean")
  my.params <- c(my.params, "native.tract.bundles.map.density_mean")
  run.classify(sprintf("PTE.Morph.Finland.%s", my.tp), my.params, c("Finland"), my.tp, tbi=FALSE)
  run.classify(sprintf("TBI.Morph.Finland.%s", my.tp), my.params, c("Finland"), my.tp, tbi=TRUE)

  my.params <- NULL
  my.params <- c(my.params, "native.tract.bundles.map.volume")
  my.params <- c(my.params, "native.tract.bundles.map.length_mean")
  my.params <- c(my.params, "native.tract.bundles.map.density_mean")
  my.params <- c(my.params, "native.tract.bundles.dwi.harm.zscore.map.dti_FA_mean")
  run.classify(sprintf("PTE.Combined.Finland.%s", my.tp), my.params, c("Finland"), my.tp, tbi=FALSE)
  run.classify(sprintf("TBI.Combined.Finland.%s", my.tp), my.params, c("Finland"), my.tp, tbi=TRUE)
  
  my.param <- c("native.mge.lesion.stats")
  run.classify(sprintf("PTE.Lesion.Finland.%s", my.tp), c(my.param), c("Finland"), my.tp, tbi=FALSE)
  run.classify(sprintf("TBI.Lesion.Finland.%s", my.tp), c(my.param), c("Finland"), my.tp, tbi=TRUE)
}
