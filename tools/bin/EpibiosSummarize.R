#! /usr/bin/env Rscript
################################################################################
# Plot data for EPIBIOSRx
################################################################################

library(ggplot2)

args = commandArgs(trailingOnly=TRUE)

if (length(args) != 4) {
  stop("usage: script site table var output", call.=FALSE)
} else if (length(args)==1) {
  # default output file
  args[2] = "out.txt"
}

# e.g.
# site <- "UCLA"; 
# table <- "atlas.lesion.stats.absz_median"
# var <- "heme"
# output <- "plot.pdf"

site   <- args[1]
table  <- args[2]
var    <- args[3]
output <- args[4]

data <- "/ifs/loni/postdocs/rcabeen/shared/epibios/rat/"

meta.df <- read.csv(sprintf("%s/workflow/params/%s/meta.csv", data, site))
img.df  <- read.csv(sprintf("%s/data/level6/%s/tables/%s.csv", data, site, table))

my.df <- merge(meta.df, img.df)

my.df$tp <- as.character(my.df$tp)
my.df$tp[my.df$group == "Sham"] <- "Sham"
my.df$tp <- factor(my.df$tp, levels=c("Sham", "2d", "9d", "1mo", "5mo"))
my.df$value <- my.df[,var]

my.plot <- ggplot(data=my.df, aes(x=tp, y=value)) 
my.plot <- my.plot + geom_boxplot(outlier.shape=NA) 
my.plot <- my.plot + geom_jitter(width=0.1, alpha=0.1) 
my.plot <- my.plot + ylab(var) + xlab("Timepoint") 
my.plot <- my.plot + ggtitle("EPIBIOS Rodent TBI Cases")

ggsave(output, plot=my.plot)

################################################################################
# End
################################################################################
