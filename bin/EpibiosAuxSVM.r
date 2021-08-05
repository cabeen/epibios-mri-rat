
library(caret)
library(e1071)

table <- read.table("Finland", "native.tract.bundles.along.dwi.raw.map.dti_FA_mean")

mydf <- table$df[table$df$status %in% c("TBI", "PTE"),c(table$metrics, "status")]

truth <- NULL
pred  <- NULL

for (i in seq(nrow(mydf)))
{
  train <- mydf[-i,]
  test  <- mydf[i,]
  model <- svm(status ~ ., data=train)
  truth <- rbind(truth, test$status)
  pred <- rbind(pred, predict(model, test))
}

confusionMatrix(as.factor(pred), as.factor(truth))
