#! /usr/bin/env Rscript 

library(ggplot2)
library(purrr)
library(tidyr)
library(broom)
library(glmnet)
library(caret)
library(dplyr)

# This is the directory to where you have the data tables saved
root <- "/Users/rcabeen/sandbox/epibios/2021-05-11"

epibios.read.table <- function(params, sites)
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
      img.fn <- sprintf("%s/group/tables/%s/%s.csv", root, site, param)
   
      cat(sprintf("reading table: %s\n", img.fn))
      my.df <- read.csv(img.fn)
      meta.fields <- c("group", "id", "site", "subject", "tp")
      my.metrics <- names(my.df)[-which(colnames(my.df) %in% meta.fields)]
      
      pte.fn <- sprintf("%s/group/tables/%s/pte.csv", root, site)
      cat(sprintf("reading table: %s\n", pte.fn))
      my.df <- merge(read.csv(pte.fn), my.df)
      my.df$status <- factor(my.df$status, levels=c("Sham", "TBI", "PTE"))
    
      # add the global mean
      my.df$global_mean <- rowMeans(my.df[,my.metrics], na.rm=TRUE)
      my.metrics <- c(my.metrics, "global_mean")

      sites.metrics <- paste(param, my.metrics, sep=".")
      sites.df <- rbind(sites.df, my.df)
    }

    cat("read table!\n")
    
    for (metric in my.metrics)
    {
      pasted <- paste(param, metric, sep=".")
      names(sites.df)[names(sites.df) == metric] <- pasted
    }
  
    out.metrics <- c(out.metrics, sites.metrics)
    if (is.null(out.df))
    {
      out.df <- sites.df
    }
    else
    {
      out.df <- merge(out.df, 
        sites.df[,c("subject", sites.metrics)], by="subject")
    }
  }
  
  long.df <- gather(out.df, metric, value, out.metrics, factor_key=TRUE)
  long.df <- subset(long.df, select=-c(subject) )
  wide.df <- spread(long.df, tp, value)
  if ("1mo" %in% names(wide.df))
  {
     names(wide.df)[names(wide.df) == "1mo"] <- "30d"
  }
  wide.df[,"diff_9d_2d"]   <- wide.df[,"9d"]  - wide.df[,"2d"]
  wide.df[,"diff_30d_2d"]  <- wide.df[,"30d"] - wide.df[,"2d"]
  wide.df[,"diff_5mo_2d"]  <- wide.df[,"5mo"] - wide.df[,"2d"]
  wide.df[,"diff_30d_9d"]  <- wide.df[,"30d"] - wide.df[,"9d"]
  wide.df[,"diff_5mo_9d"]  <- wide.df[,"5mo"] - wide.df[,"9d"]
  wide.df[,"diff_5mo_30d"] <- wide.df[,"5mo"] - wide.df[,"30d"]
  tps <- c("2d", "9d", "30d", "5mo", 
           "diff_9d_2d", "diff_30d_2d", "diff_5mo_2d", 
           "diff_30d_9d", "diff_5mo_9d", 
           "diff_5mo_30d")
  
  for (tp in tps)
  {
    wide.df[is.na(wide.df[,tp]), tp] = 0
  }
  
  long.df <- gather(wide.df, tp, value, tps, factor_key=TRUE)
  out.df <- spread(long.df, metric, value)

  for (tp in tps) 
  {
    for (region in out.metrics)
    {
      vals <- out.df[out.df$status %in% c("TBI", "PTE") & out.df$tp == tp,region]
			meanv <- mean(vals)
			sdv <- sd(vals)
			if (sdv != 0)
			{
        my.tp <- out.df$tp == tp
				out.df[my.tp,region] <- (out.df[my.tp,region] - meanv) / sdv
			}
    }
  }
  
  return(list(df=out.df, metrics=out.metrics))
}

epibios.classify <- function(params, sites, time, tbi=FALSE, alpha=0.5)
{
  name <- sprintf("%s.%s.%s.%s", if(tbi) "TBI" else "PTE", paste(sites, sep="-"), paste(params, sep="-"), time)
  
  cat("processing case\n")
  cat("  name: ", name, "\n")
  cat("  params: ", params, "\n")
  cat("  sites: ", sites, "\n")
  cat("  timepoint: ", time, "\n")
  
  tryCatch(
  {
    my.table <- epibios.read.table(params, sites)
    df <- my.table$df 
    metrics <- my.table$metrics
    df <- df[df$tp == time,]
   
    if (tbi)
    {
      df <- df[!df$status %in% c("PTE"),]
      df$outcome <- df$status == "TBI"
    } else {
      df <- df[!df$status %in% c("Sham"),]
      df$outcome <- df$status == "PTE"
    }
    
    out.df <- NULL
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
    
    sink(sprintf("results/models/%s.txt", name))
    cat("EPIBIOS Rodent PTE Classification Report\n")
    cat("\n")
    if (tbi)
    {
       cat("Task: Sham vs TBI\n") 
    } else {
       cat("Task: TBI vs PTE\n")
    }
    cat("\n")
    cat("Sites: \n")
    for (site in sites)
    {
      cat(sprintf("  %s\n", site))
    }
    cat("\n")
    cat(sprintf("Timepoint: %s\n", time))
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
    print(caret::confusionMatrix(data=as.factor(out.df$pred > 0), 
      reference=as.factor(out.df$ref)))
    cat("\n")
    cat("End\n")
    sink()

    my.metrics <- my.coef.df[which(my.coef.df$s0 != 0),"name"]
    my.metrics <- my.metrics[c(-1)] # remove the intercept
    sub.out.df <- NULL
    
    for (metric in my.metrics) 
    {
      my.df <- data.frame(df)
      my.df$value <- my.df[,metric]
      my.test <- NULL  
      
      if (tbi)
      {
         my.subdf <- my.df[my.df$status %in% c("Sham", "TBI"),]
         my.test <- "tbi" 
      } else {
         my.subdf <- my.df[my.df$status %in% c("TBI", "PTE"),]
         my.test <- "pte" 
      }
      
      my.fit <- lm(data=my.subdf, formula="value ~ status")
      my.sum <- summary(my.fit)
      my.coef <- coef(my.sum)
    
      site <- paste(sites, sep="-") 
      out <- data.frame(site=site, tp=time, param=param, metric=metric)
      out$ntbi  <- sum(my.df$status == "TBI")
      out$npte  <- sum(my.df$status == "PTE")
      out$df    <- my.sum$df[[2]]
      out$rsq   <- my.sum$r.squared
      out$arsq  <- my.sum$adj.r.squared
      out$beta  <- my.coef[2, 1]
      out$stde  <- my.coef[2, 2]
      out$tval  <- my.coef[2, 3]
      out$pval  <- my.coef[2, 4]
     
      if (out$pval < 0.01) 
      {
				myplot <- ggplot(data=my.df, aes(x=status, y=value, color=site))
				myplot <- myplot + geom_boxplot(outlier.shape=NA) + geom_point(alpha=0.25, size=1, position=position_jitterdodge())
				myplot <- myplot + xlab("status") + ylab(metric)
				myplot <- myplot + ggtitle(sprintf("%s %s %s: \n  R2 = %0.2g, beta = %0.2g, pval = %g", site, param, metric, out$rsq, out$beta, out$pval))
				plot.fn <- sprintf("results/plots/%s.%s.pdf", name, metric)
				suppressMessages(ggsave(plot.fn, myplot))
				cat(sprintf("......... saved: %s\n", plot.fn))
      }

			sub.out.df <- rbind(sub.out.df, out)
    }
  
    sub.out.fn <- sprintf("results/stats/%s.csv", name)
    cat(sprintf("writing table %s \n", sub.out.fn))
    write.csv(sub.out.df, file=sub.out.fn, row.names=F, quote=F)
    cat(sprintf("......... saved: %s\n", sub.out.fn))
  }, error=function(e) {
     cat(sprintf("ERROR: skipping case %s\n", e))
  }, finally={
  })
}

dir.create("results/models", showWarnings=FALSE, recursive=T)
dir.create("results/plots", showWarnings=FALSE, recursive=T)
dir.create("results/stats", showWarnings=FALSE, recursive=T)

# my.params <- NULL
# my.params <- c(my.params, "native.tract.bundles.dwi.harm.zscore.map.dti_FA_mean")
# my.params <- c(my.params, "native.tract.bundles.dwi.harm.zscore.map.dti_AD_mean")
# my.params <- c(my.params, "native.tract.bundles.dwi.harm.zscore.map.dti_RD_mean")
# my.params <- c(my.params, "native.tract.bundles.map.density_mean")
# my.params <- c(my.params, "native.mge.lesion.stats")
# 
# my.tps <- c("2d", "9d", "30d", "5mo", "diff_9d_2d", "diff_30d_9d")
# my.sites <- c("Finland", "UCLA", "Melbourne")


my.params <- NULL

# my.params <- c(my.params, "atlas.dwi.lesion.stats")
# my.params <- c(my.params, "atlas.mge.lesion.stats")

my.params <- c(my.params, "native.dwi.tract.bundles.tissue.map.density_mean")
my.params <- c(my.params, "native.dwi.tract.bundles.tissue.map.volume")
# my.params <- c(my.params, "native.dwi.tract.bundles.tissue.map.length_mean")
# my.params <- c(my.params, "native.dwi.tract.bundles.tissue.map.mag_mean")
# my.params <- c(my.params, "native.dwi.tract.bundles.tissue.map.num_tissue")
 
my.params <- c(my.params, "native.dwi.tract.bundles.tissue.whole.voxel.fit.map.dti_FA_mean")
my.params <- c(my.params, "native.dwi.tract.bundles.tissue.whole.voxel.fitz.map.dti_FA_mean")
my.params <- c(my.params, "native.dwi.tract.bundles.tissue.whole.voxel.harm.map.dti_FA_mean")
my.params <- c(my.params, "native.dwi.tract.bundles.tissue.whole.voxel.harmz.map.dti_FA_mean")

# my.tps <- c("2d", "9d", "30d", "5mo", "diff_9d_2d", "diff_30d_2d", "diff_5mo_2d", "diff_30d_9d", "diff_5mo_9d", "diff_5mo_30d")
my.tps <- c("2d", "9d", "30d", "5mo")
my.sites <- c("Finland-P1", "Melbourne-P1", "UCLA-P1")

for (my.param in my.params) 
{ 
  for (my.tp in my.tps)
  {
    for (my.site in my.sites)
    {
      epibios.classify(c(my.param), c(my.site), my.tp, tbi=FALSE)
      epibios.classify(c(my.param), c(my.site), my.tp, tbi=TRUE)
    }
  }
}
