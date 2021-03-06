## Richard Wanjohi


library(randomForest) 
library(ROCR)
library(nnet) 
library(rpart)
library(e1071)
library(bnlearn)
library(ggplot2)
library(caret)

# read the data
df = read.table('C:/**********/*****/***/***.csv', sep = ',', header = TRUE)
# basics
dim(df)
names(df)
head(df)
summary(df)
# split the data, 20:80 
N = nrow(df)
Ind = sample(N, N*0.8, replace = FALSE)
train = df[Ind, ]
test  = df[-Ind, ]
p = ncol(df)
## assuming target variable is in the last column
Y_train = train[ , p]
Y_test  = test[, p]

# Logistic Regression 
logit.fit = glm( Y_train ~., family = binomial(logit),data = train) 
## fm12 = stepAIC(logit.fit) # stepwise 

logit.preds = predict(logit.fit,newdata=test,type="response") 
logit.pred = prediction(logit.preds,Y_test) 
logit.perf = performance(logit.pred,"tpr","fpr")
logit.auc  = performance(logit.pred, 'auc')
# Area under curve
print(logit.auc@y.values[[1]])
# confusion matrix 
tabs.reg = table(logit.preds >= 0.5, Y_test)
dimnames(tabs.reg)[[1]] <- c(levels(Y_train)[1], levels(Y_train)[2])
print(confusionMatrix( tabs.reg), mode = 'everything')

#---------------------------------------------------------------------
# Random Forest 
bestmtry <- tuneRF(train[, -p],Y_train, ntreeTry=100, stepFactor=1.5,improve=0.01, trace=TRUE, plot=TRUE, dobest=FALSE) 
m = bestmtry[which.min(bestmtry[, 2]), 1]
rf.fit <-randomForest(Y_train ~.,data=train, mtry=m, ntree=100, keep.forest=TRUE, importance=TRUE,test=test) 
rf.preds = predict(rf.fit,type="prob",newdata=test)[,2] 
rf.pred = prediction(rf.preds, Y_test) 
rf.perf = performance(rf.pred,"tpr","fpr") 
rf.auc  = performance(rf.pred, 'auc')
# Area under curve
print(rf.auc@y.values[[1]])
# confusion matrix
tabs.rf = table(rf.preds >= 0.5, Y_test)
dimnames(tabs.rf)[[1]] <- c(levels(Y_train)[1], levels(Y_train)[2])
print(confusionMatrix( tabs.rf), mode = 'everything')

#--------------------------------------------------------------------
# CART Trees 
mycontrol = rpart.control(cp = 0.02, xval = 10) 
tree.fit = rpart(Y_train ~., method = "class",data = train, control = mycontrol) 
tree.cp = tree.fit$cptable[which.min(tree.fit$cptable[, 'xerror']), 'CP']

tree.prune = prune(tree.fit,cp=tree.cp) 
tree.preds = predict(tree.prune,newdata=test,type="prob")[,2] 
tree.pred = prediction(tree.preds,Y_test) 
tree.perf = performance(tree.pred,"tpr","fpr")
tree.auc = performance(tree.pred, 'auc')
# Area unde curve
print(tree.auc@y.values[[1]])
# confusion matrix
tabs.tree <- table(tree.preds >= 0.5, Y_test)
dimnames(tabs.tree)[[1]] <- c(levels(Y_train)[1], levels(Y_train)[2])
print(confusionMatrix( tabs.tree), mode = 'everything')

#---------------------------------------------------------------------
# Neural Network 
nnet.fit = nnet(Y_train~., data=train,size= 5,maxit=10000,decay=.001) 
nnet.preds = predict(nnet.fit,newdata=test,type="raw") 
nnet.pred = prediction(nnet.preds,Y_test) 
nnet.perf = performance(nnet.pred,"tpr","fpr") 
nnet.auc = performance(nnet.pred, 'auc')
# Area under curve
print(nnet.auc@y.values[[1]])
# confusion matrix
tabs.nnet <- table(nnet.preds >= 0.5, Y_test)
dimnames(tabs.nnet)[[1]] <- c(levels(Y_train)[1], levels(Y_train)[2])
print(confusionMatrix( tabs.nnet), mode = 'everything')

#-----------------------------------------------------------------------
# SVM
svm.tune <- tune(svm, Y_train ~., data = train,
                 ranges = list(gamma = 2^(-8:1), cost = 2^(0:4)),
                 tunecontrol = tune.control(sampling = "fix"))
svm.tune      

svm.fit = svm(Y_train ~., data = train, cost = 4, gamma = 0.015625, decision.values = TRUE, probability = TRUE)
svm.preds = predict(svm.fit, newdata = test, type = 'prob', decision.values = TRUE, probability = TRUE)
svm.pred = prediction(attr(svm.preds, 'probabilities')[, 2], Y_test) 
svm.perf = performance(svm.pred,"tpr","fpr") 

# Area under curve
svm.auc = performance(svm.pred, 'auc')
print(svm.auc@y.values[[1]])
# confusion matrix
tabs.svm = table(svm.preds, Y_test)
print(confusionMatrix(tabs.svm), mode = 'everything')


#----------------------------------------------------------------------
# Naive Bayes

nb.fit = naiveBayes(Y_train~., data = train,  iss = 'Y')
nb.preds = predict(nb.fit, newdata =  test, type =  'raw')[, 1]
nb.pred = prediction(nb.preds,Y_test) 
nb.perf = performance(nb.pred,"tpr","fpr") 
nb.auc  = performance(nb.pred, 'auc')
# Area under curve
print(nb.auc@y.values[[1]])
# confusion matrix
tabs.nb <- table(nb.preds <= 0.5, Y_test)
dimnames(tabs.nb)[[1]] <- c(levels(Y_train)[1], levels(Y_train)[2])
print(confusionMatrix( tabs.nb), mode = 'everything')
#--------------------------------------------------------------------------------------
# Gradient Boosting

 #tune
fitControl <- trainControl(method = "repeatedcv", number = 4, repeats = 4)
gbc.fit <- train(Y_train ~ ., data = train, method = "gbm", 
                 trControl = fitControl,verbose = FALSE)

gbc.preds = predict(gbc.fit, newdata =  test, type =  'raw')[, 1]
gbc.pred = prediction(gbc.preds,Y_test) 
gbc.perf = performance(gbc.pred,"tpr","fpr") 
gbc.auc  = performance(gbc.pred, 'auc')
# Area under curve
print(gbc.auc@y.values[[1]])
# confusion matrix
tabs.nb <- table(gbc.preds <= 0.5, Y_test)
dimnames(tabs.gbc)[[1]] <- c(levels(Y_train)[1], levels(Y_train)[2])
print(confusionMatrix( tabs.gbc), mode = 'everything')



##------------------------------------------------------------------------
# Plotting ROC Curves 

plot(logit.perf, lwd = 2, col=2,main="ROC Curve for Classifiers") 

plot(rf.perf, lwd = 2,col=3, add=T) 
plot(tree.perf,lwd=2,col=4,add=T) 
plot(nnet.perf,lwd=2,col=5,add=T)
plot(svm.perf, lw=2, col = 6, add = T)
plot(nb.perf, lw = 2, col = 7, add = T)
plot(gbc.perf, lw = 2, col = 8, add = T)
abline(a=0,b=1,lwd=2,lty=2,col="gray") 
legend("bottomright",col=c(2:8),lwd=2,legend=c("Logistic","RF","CART","Neural Net", 'SVM', 'N. Bayes', 'GBC'),bty='n', cex = 0.8)











