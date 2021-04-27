#! /usr/bin/env Rscript 

library(ggplot2)
library(purrr)
library(tidyr)
library(broom)
library(glmnet)
library(caret)

params <- NULL

params <- c(params, "native.dwi.tract.bundles.tissue.whole.voxel.fit.map.dti_FA_mean")
params <- c(params, "native.dwi.tract.bundles.tissue.whole.voxel.fitz.map.dti_FA_mean")
params <- c(params, "native.dwi.tract.bundles.tissue.whole.voxel.harm.map.dti_FA_mean")
params <- c(params, "native.dwi.tract.bundles.tissue.whole.voxel.harmz.map.dti_FA_mean")

tps <- c("2d", "9d", "30d", "5mo", "diff_9d_2d", "diff_30d_2d", "diff_5mo_2d", "diff_30d_9d", "diff_5mo_9d", "diff_5mo_30d")

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
      img.fn <- sprintf("tables/%s/%s.csv", site, param)
    
      my.df <- read.csv(img.fn)
      my.metrics <- names(my.df)[-which(colnames(my.df) %in% c("group", "id", "site", "subject", "tp"))]
      
      pte.fn <- sprintf("tables/%s/pte.csv", site)
      my.df <- merge(read.csv(pte.fn), my.df)
      my.df$status <- factor(my.df$status, levels = c("Sham", "TBI", "PTE"))
      
      sites.metrics <- paste(param, my.metrics, sep=".")
      sites.df <- rbind(sites.df, my.df)
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
        out.df[out.df$tp == tp,region] <- (out.df[out.df$tp == tp,region] - meanv) / sdv
      }
    }
  }
  
  return(list(df=out.df, metrics=out.metrics))
}

process.all <- function()
{
  cat("started\n")

  out.df <- NULL

	for (site in c("Finland-P1", "Melbourne-P1", "UCLA-P1", "Combined"))
  {
		for (param in params) 
		{
			tryCatch(
			{
				cat(sprintf("... processing: %s %s\n", site, param))

        cat(sprintf("...... reading input\n"))
				if (site == "Combined")
				{
          table <- epibios.read.table(param, c("Finland-P1", "UCLA-P1", "Melbourne-P1"))
					model <- "normvalue ~ status"
        }
        else
        {
          table <- epibios.read.table(param, c(site))
					model <- "normvalue ~ status"
        }

				for (time in tps)
				{
					sub.out.df <- NULL
					sub.in.df <- table$df
					sub.in.df <- sub.in.df[sub.in.df$tp == time,]

					for (metric in table$metrics)
					{
						tryCatch(
						{
							cat(sprintf("...... processing metric at timepoint: %s %s %s\n", site, time, metric))
							my.df <- sub.in.df
							my.df$value <- my.df[,metric]

							my.df$normvalue <- (my.df$value - mean(my.df$value)) / sd(my.df$value)
							# my.df <- my.df[abs(my.df$normvalue) < 5,]

							my.subdf <- my.df[my.df$status %in% c("TBI", "PTE"),]
							
							my.fit <- lm(data=my.subdf, formula=model)
							my.sum <- summary(my.fit)
							my.coef <- coef(my.sum)

							out      <- data.frame(site=site, tp=time, param=param, metric=metric)
							out$ntbi  <- sum(my.df$status == "TBI")
							out$npte  <- sum(my.df$status == "PTE")
							out$df    <- my.sum$df[[2]]
							out$rsq   <- my.sum$r.squared
							out$arsq  <- my.sum$adj.r.squared
							out$beta  <- my.coef[2, 1]
							out$stde  <- my.coef[2, 2]
							out$tval  <- my.coef[2, 3]
							out$pval  <- my.coef[2, 4]

							if (out$pval < 0.05)
							{
								myplot <- ggplot(data=my.df, aes(x=status, y=value, color=site))
								myplot <- myplot + geom_boxplot(outlier.shape=NA) + geom_point(alpha=0.25, size=1, position = position_jitterdodge())
								myplot <- myplot + xlab("status") + ylab(metric)
								myplot <- myplot + ggtitle(sprintf("%s %s %s: \n  R2 = %0.2g, beta = %0.2g, pval = %g", site, param, metric, out$rsq, out$beta, out$pval))
								plot.fn <- sprintf("single-plots/param.%s.site.%s.tp.%s.metric.%s.pdf", param, site, time, metric)
								suppressMessages(ggsave(plot.fn, myplot))
								cat(sprintf("......... saved: %s %s %s\n", site, time, metric))
							}

							sub.out.df <- rbind(sub.out.df, out)
						}, warning = function(w) {
								cat(sprintf("warning: %s\n", w))
						}, error = function(e) {
								cat(sprintf("error: %s\n", e))
						}, finally = {
						})
					} 

					sub.out.fn <- sprintf("single-stats/param.%s.site.%s.tp.%s.csv", param, site, time)
					write.csv(sub.out.df, file=sub.out.fn, row.names=F, quote=F)

					sub.out.df$qval <- p.adjust(sub.out.df$pval, method="fdr") 
					out.df <- rbind(out.df, sub.out.df)
				}
			}, warning = function(w) {
					cat(sprintf("warning: %s\n", w))
			}, error = function(e) {
					cat(sprintf("error: %s\n", e))
			}, finally = {
			})
		}
  }

  cat(sprintf("saving results\n"))
  out.fn <- sprintf("single-stats.csv")
  write.csv(out.df, file=out.fn, row.names=F, quote=F)

  cat("finished\n")
}

args = commandArgs(trailingOnly=TRUE)

dir.create(sprintf("single-plots"), showWarnings = FALSE)
dir.create(sprintf("single-stats"), showWarnings = FALSE)

for (arg in args)
{
  if (arg == "all")
  {
	  process.all()
  }
}
