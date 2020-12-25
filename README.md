---
title: "CDA R notebook"
author: "Instructor: Partha Sarathi Mukherjee"
date: "Last updated: `r Sys.time()`"
output: 
  html_document:
    toc: true # table of content true
    toc_depth: 3  # upto three depths of headings (specified by #, ## and ###)
    number_sections: false  ## if you want number sections at each table header
    theme: yeti  # many options for theme, this one is my favorite.
    highlight: tango  # specifies the syntax highlighting style
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

## (20/10/20) Introduction to GLM in R

### Logistic model on ungrouped data

Consider the following data, for illustration.

```{r}
x <- rep(0:2, each = 4)
s <- c(1, 0, 0, 0 , 1, 1, 0, 0, 1, 1, 1, 1)
print(rbind(x, s))
```
Let us fit a logistic regression model:

```{r}
fit1 <- glm(s ~ x, family = binomial(link = logit))
summary(fit1)
``` 

Let us carefully understand each part of the summary. 

- We can see the fitted coefficients, the corresponding standard error, z-score (estimate/std.error), and the p-value for testing that that particular coefficient is 0. A lower p-value indicates that that coefficient has a significant effect. The standard errors are just the square roots of the diagonal entries of the estimated var-cov matrix of the estimated parameters (see below).

- We also see the null-deviance, which is the deviance for the only-intercept model, and the residual deviance. The deviance of any model here is actually -2 loglikelihood of the model fit, since R takes the loglikelihood of the saturated model as 0 (see below). 

- Our goal always is to reduce the residual deviance as much as possible, in exchange of as few degrees of freedom as possible. We loose (fit1\$df.null - fit1\$df.resid) many dfs for estimating the parameters in the model. 

#### Estimated var-cov matrix

The estimated var-cov matrix of the estimated parameters can be found as:

```{r}
vcov(fit1)
```

#### What's the saturated model taken by R?

Here we verify that the saturated model taken by R is indeed the model with perfect fit. 
```{r}
x1 <- rep(0:1, each = 4)
x2 <- rep(0:1, times = 4) 
y <- c(0, 1, 1, 0, 0, 1, 0, 1)
print(cbind(y, x1, x2))

summary(fit <- glm(y ~ x1 + x2, family = binomial))
pi.hat = 1/(1 + exp(-fit$coef[1] - fit$coef[2]*x1 - fit$coef[3]*x2))
- 2 * sum(y * log(pi.hat) + (1 - y) * log(1 - pi.hat))   
```
Note that it matches with the residual deviance given in the summary. Therefore, R takes the log-likelihood for the saturated model to be exactly 0.

#### Chi^2 test from deviances

To understand whether the model fit1 significantly better than the null model (only intercept), we perform a $\chi^2$ test with df = (fit1\$df.null - fit1\$df.resid).

```{r}
pchisq(fit1$null.deviance - fit1$deviance, fit1$df.null - fit1$df.resid, lower.tail = F) 
```
Since the p-value is low, we conclud that our model does significantly improve upon the null model.



### Logistic model on grouped data

```{r}
x <- c(0, 1, 2)
n <- c(4, 4, 4)
s <- c(1, 2, 4)

fit2 <- glm(cbind(s, n-s) ~ x, family = binomial(link = "logit"))
summary(fit2)
```

Let us compare the above model (fit2) with the previous model (fit1).
```{r}
summary(fit1)
```

Note that the estimates and std errors etc. are same, but the deviances are changed, because the saturated model is different. However, the difference (null dev - resid dev) is same as before.



### Overdispersion situations

Overdispersed proportions modelled using Quasi-binomial. Here phi is not specified to be 1 apriori.

```{r}
fit3 <- glm(cbind(s,n-s) ~ x, family = quasibinomial(link = "logit"))
summary(fit3)
```

Observe that estimated phi is less than 1, indicating we have under-estimated the dispersion. Estimated residuals should be higher, they can be adjusted by dividing them by this estimated phi. 

Also note that the estimates did not change between fit1, fit2 and fit3.

Similarly, overdispersed counts are modelled using quasipoisson.



### Comparing logit and probit links

Let us compare what happens when we apply both the logistic model and probit model on the same data.
```{r}
n = 40
x <- sort(runif(n, 0, 2))
y <- c(rep(0, n/4), sample(rep(0:1, c(n/4, n/4)), n/2, replace = T), rep(1, n/4))

logit.fit <- glm(y ~ x, family = binomial(link = logit))
print(summary(logit.fit))

probit.fit <- glm(y ~ x, family = binomial(link = probit))
print(summary(probit.fit))

curve(1/(1 + exp(-logit.fit$coef[1] - logit.fit$coef[2]*x)), xlim = c(floor(min(x)), floor(max(x)+1)), ylim = c(0, 1), col = 4, ylab = "prob. at x")
points(x, y, col = 1)
points(x, fitted(logit.fit), col = 4)
curve(pnorm(probit.fit$coef[1] + probit.fit$coef[2]*x), xlim = c(floor(min(x)), floor(max(x)+1)), ylim = c(0, 1), col = 2, add = T)
title(main = "fitted curves for logit and probit links")
points(x, fitted(probit.fit), col = 2)
legend("bottomright", legend = c("logit link", "probit link"), col = c(4, 2), lwd = 2, pch = 1)
```

Note that in this example the deviances or the AIC values are almost same for the logit link and the probit link.

## (03/11/20) Model Selection and Residuals

### Subset selection using step() function

Once again, we first create a toy data.
```{r}
y <- rep(1:0, each = 5)
x1 <- c(2, 3, 3, 4, 2, 1, 0, 3, 1, 0)
x2 <- rnorm(10)
print(rbind(y, x1, x2), digits = 2)
```
Here we know for sure that x2 is not significant, just a random quantity indept. of y and x1. 

We fit the full model (with all predictors) and the null model (with only the intercept).
```{r}
full <- glm(y ~ x1 + x2, family = binomial(logit))
null <- glm(y ~ 1, family = binomial(logit))
```

It is possible that while fitting the full model, we get an warning saying that "glm.fit: fitted probabilities numerically 0 or 1 occurred". If so, just simulate x2 once again! 

Let us look at the summary of the above two models.
```{r}
summary(full)
summary(null)
```
Note that for the null model the null and residual deviances should be same, as expected. 

Next, we do a subset regression: choosing the best subset using forward, backward, or the stepwise method. 

#### Forward selection
```{r}
forward = step(null, 
                scope = list(lower = formula(null), upper = formula(full)), 
                direction = "forward")
```

At each step it tries to include each of the remaining predictors, and sees how much the AIC value changes. Starting with the null model, note that the AIC value decreases if we include x1 but decreases if x2 is included. So we include x1 and proceed. In the next step, we see that inclusion of x2 does not decrease the AIC (although it decreases deviance), so the final model is chosen as y ~ x1.

#### Backward selection
The backward selection method: Here we have to start with the full model.
```{r}
backward = step(full, 
                 scope = list(lower = formula(null), upper = formula(full)), 
                 direction = "backward")
```
Here a predictor present in the model is excluded in the next step if that exclusion decreases the AIC.

#### Using BIC instead of AIC
```{r}
backward.BIC = step(full, 
                scope = list(lower = formula(null), upper = formula(full)), 
                direction = "backward", k = log(10))
```


#### Stepwise selection
```{r}
both.BIC = step(null, 
                scope = list(lower = formula(null), upper = formula(full)), 
                direction = "both", k = log(10))
```

#### Printing the chosen models

```{r}
formula(forward)
backward
summary(backward.BIC)
```

Note that backward.BIC does not print the BIC, it still prints the AIC. To print the BIC, we have to do this:
```{r}
backward.BIC$aic - (2 - log(10)) * backward.BIC$rank
```

#### The default direction is backward
```{r}
step(null)
```

#### Hiding the intermediate steps

Setting trace = 0 hides the intermediate steps.
```{r}
step(full, trace = 0)
```

### Different types of residuals

```{r}
residuals(full, type = "pearson")
residuals(full, type = "deviance")
sum(residuals(full, type = "pearson")^2)   # gives Pearson's X^2
sum(residuals(full, type = "deviance")^2)  # gives Likelihood statistic G^2
deviance(full)      # this also gives Likelihood statistic G^2
```

##  (05/11/20) Fitted values, Cook's distance etc.

Here are two useful links:
<https://data.princeton.edu/wws509/r/c3s8>
<https://maths-people.anu.edu.au/~johnm/courses/r/ASC2008/pdf/glm-ohp.pdf>

We will work with the additive model of contraceptive use by age, education, and desire for more children, which we know to be inadequate.

```{r}
cuse = read.table("https://data.princeton.edu/wws509/datasets/cuse.dat", header = TRUE)
head(cuse)
additive <- glm(cbind(using, notUsing) ~ age + education + wantsMore, 
                family = binomial, data = cuse)
summary(additive)
```

Let us look at a few things we did not discuss earlier.

### Leverage and Influence

Pregibon extended regression diagnostics to GLMs and introduced a weighted hat matrix. The diagonal elements or leverages can be calculated with hatvalues() and Cook's distance with cooks.distance. (Don't be surprised if these look like the same functions we used for linear models. Like many other R functions, these are generic functions; R looks at the class of the object and calls the appropriate function, depending on whether the object is a linear model fitted by lm() or a generalized linear model fitted by glm().)

Let us calculate these diagnostics and list the groups that have potential and/or actual influence on the fit.

```{r}
print(pfit <- fitted(additive)) # these are the pi_i hats.
print(lev <- hatvalues(additive)) # these are the h_i's
print(cd <- cooks.distance(additive)) # Cook's distances
```

We have to be careful whenever Cook's distance is greater than 1.

```{r}
pobs <- cuse$using/(cuse$using + cuse$notUsing) # sample proportions
i <- order(-lev) 
cbind(cuse[, c("age", "education", "wantsMore")], pobs, pfit, lev, cd)[i[1:5],]
```

The three cells with potentially the largest influence in the fit are young women with some education who want more children, and older women with no education who want no more children. The youngest group had the most influence on the fit, whereas older uneducated women had no actual influence at all, with a Cook's distance of zero.

Note: Cook's distance is calculated using Pregibon's one-step approximation, as described on page 49 of the notes. In short, it doesn't refit the model excluding an observation, but takes just one-step in the IRLS algorithm, starting from the full sample mle.

### Standardized Residuals

The values of the (weighed) hat matrix can be used to compute standardized Pearson and deviance residuals, just as we did in linear models. These residuals take into account differences in residual variances originating from both the outcome and the fit.

```{r}
pr <- residuals(additive, "pearson") # Pearson's residuals
dr <- residuals(additive) # default: deviance residuals
spr <- pr/sqrt(1-lev)
sdr <- dr/sqrt(1-lev)
i <- order(-spr^2)
cbind(cuse[,c("age","education","wantsMore")], pobs, pfit, spr, sdr)[i[1:5],]
```
We identify the same three observations picked up by the conventional residuals, but the absolute values are now closer to three, highlighting the lack of fit of these groups.

### Goodness of Fit

For **Hosmer-Lemeshow** chi-squared test to check the goodness of fit of a logistic regression model, see the bottom of this web-page: <https://data.princeton.edu/wws509/r/c3s8>. Small p-value indiactes that there are evidences of lack of fit.

## (06/11/20) ROC curve, complete and quasi-complete separations


### ROC curve

We will use the Default dataset available in **ISLR** package.
```{r, message = F}
library(ISLR)
library(tibble)
as_tibble(Default)
```
We select half of the data randomly as the test data and the remaining half as the test data.
```{r}
train.id = sample(nrow(Default), nrow(Default)/2)
default_train = Default[train.id, ]
default_test = Default[-train.id, ]
```
It is very reasonable that we estimate the model parameters using the training data, and apply the ROC curve on the test data to assess how the model performs on a fresh data. To get the ROC curve, we need the **pROC** package.

```{r, message = F}
library(pROC)
model_fit = glm(default ~ balance, data = default_train, family = "binomial")
test_prob = predict(model_fit, newdata = default_test, type = "response")
test_roc = roc(default_test$default ~ test_prob, plot = TRUE, print.auc = TRUE)
as.numeric(test_roc$auc)
```

A good model will have a high AUC, that is as often as possible a high sensitivity and specificity.

**A good reference:** (for Logistic Regression as a whole) <https://daviddalpiaz.github.io/r4sl/logistic-regression.html>


### Complete and quasi-complete separations

A simple function that I will use as a short cut:
```{r}
mylogistic.single<-function(x, y){
	fit <- glm(y ~ x, family = binomial(link = logit))
	print(summary(fit))
	curve(1/(1 + exp(-fit$coef[1] - fit$coef[2]*x)), xlim = c(floor(min(x)), floor(max(x)+1)), ylim = c(0, 1), ylab = "prob. at x", main = "fitted logistic curve")
	points(x, y, col = 2)
	points(x, fitted(fit), col = 4)
}
```

#### Complete separation
```{r}
n = 20
x <- sort(runif(n, 0, 2))
y <- c(rep(0, n/2), rep(1, n/2))
mylogistic.single(x, y)
```

Note that the residual deviance is almost zero and the estimates and std. errors are so high. We also got several warnings.

#### Quasi-complete separation
```{r}
n = 20
x <- sort(c(runif(n/2, 0, 1), 1, 1, runif(n/2, 1, 2)))
y <- c(rep(0, n/2), 0, 1, rep(1, n/2))
mylogistic.single(x, y)
```

Note that the residual deviance is not as small as in the last case, but the estimates and std. errors are still very high. We also got several warnings.


#### Usual case (neither of the above situations)
```{r}
n = 40
x <- sort(runif(n, 0, 2))
y <- c(rep(0, n/4), sample(rep(0:1, c(n/4, n/4)), n/2, replace = T), rep(1, n/4))
mylogistic.single(x, y)
```

## (12/11/20) Log-linear models for multinomial responses 

To fit multinomial log-linear models, we use the function *multinom* available in the **nnet** package. It fits multinomial log-linear models via neural networks.

```{r}
library(nnet)
# Lets create an artificial data:
y <- c(0, 0, 0, 1, 1, 1, 2, 2, 2) # so, y has 3 levels
x1 <- c(2, 3, 1, 7, 2, 0, -9, 6, 7)
x2 <- rnorm(9, mean = 0, sd = 1)
loglin.fit <- multinom(y ~ x1 + x2)
summary(loglin.fit)
coef(loglin.fit)
```

Note, a baseline category logit model was fitted above. The way to read the coefficients is that if the coefficients in the i-th row are $\beta_{i0}, \beta_{i1}, \beta_{i2},$ then the model was actually $\log(\Pr(y = i)/\Pr(y = 0)) = \beta_{i0} + \beta_{i1}\cdot x_1 + \beta_{i2}\cdot x_2.$

## (17/11/20) Models for ordinal responses

### Cumulative logit model

We use the **vglm** function in the **VGAM** package to fit a proportional odds cumulative logit model on the Pneumoconiosis in Coalminers Data, which is also available in the **VGAM** package. The pneumo data frame has 8 rows and 4 columns, exposure time is explanatory, and there are 3 ordinal response variables.

```{r, message = FALSE}
library(VGAM)
pneumo
pneumo <- transform(pneumo, lexptime = log(exposure.time))
# Fitting a proportional odds cumulative logit model
fit.cuml <- vglm(cbind(normal, mild, severe) ~ lexptime, 
                  family = "propodds", data = pneumo)
summary(fit.cuml)
coef(fit.cuml, matrix = TRUE)
```

### Adjacent category model

To illustrate this, we use a data set from the 2006 General Social Survey that shows the relationship in the United States between opinion about funding stem cell research and the fundamentalism/liberalism of one’s religious beliefs, stratified by gender.

First we store the counts in stemcell data in another form which will be suitable to us.

```{r, message = TRUE}
library(brglm2)
library(tibble)
as_tibble(stemcell)
Dat = matrix(stemcell$frequency, ncol = 4)
colnames(Dat) = levels(stemcell$research)
gender = rep(1:0, each = 3)
religion = rep(1:3, times = 2)
print(Stemcell <- data.frame(religion, gender, Dat))
```

Now let us fit the adjacent category model.

```{r}
fit.acat = vglm(Dat ~ religion + gender, data = Stemcell,
     family = "acat"(reverse = TRUE, parallel = TRUE)) 
# reverse = TRUE means we are going in the reverse order for the log-odds, and parallel = TRUE stands for prop odds, i.e., using same beta
summary(fit.acat)
coef(fit.acat, matrix = TRUE)
```
Let's see what happens if we set reverse = FALSE.
```{r}
fit.acat2 = vglm(Dat ~ religion + gender, data = Stemcell,
     family = "acat"(reverse = FALSE, parallel = TRUE)) 
# reverse = TRUE means we are going in the reverse order for the log-odds, and parallel = TRUE stands for prop odds, i.e., using same beta
summary(fit.acat2)
```

Thus, setting reverse = FALSE means taking linear predictors: loglink(P[Y=2]/P[Y=1]), 
loglink(P[Y=3]/P[Y=2]), loglink(P[Y=4]/P[Y=3]). Whereas for reverse = TRUE we take the linear predictors: loglink(P[Y=1]/P[Y=2]), 
loglink(P[Y=2]/P[Y=3]), loglink(P[Y=3]/P[Y=4]).

### Continuation ratio model

We use the Stemcell data again.

```{r}
fit.cratio = vglm(Dat ~ religion + gender, data = Stemcell,
     family = "cratio"(reverse = TRUE, parallel = TRUE)) 
# reverse = TRUE means we are going in the reverse order for the log-odds, and parallel = TRUE stands for prop odds, i.e., using same beta
summary(fit.cratio)
coef(fit.cratio, matrix = TRUE)
```

#### If we wish to use non-proportional odds:

We use the Stemcell data again.

```{r}
fit.cratio.n = vglm(Dat ~ religion + gender, data = Stemcell,
     family = "cratio"(reverse = TRUE, parallel = FALSE)) 
summary(fit.cratio.n)
coef(fit.cratio.n, matrix = TRUE)
```

Note that it gives three different slopes for both the attributes religion and gender.

## (27/11/20) Log-linear models

We use the following dataset to illustrate log-linear models.
```{r}
HairEyeColor
```
Note that it is essentially a 3-way table.

### Fitting the (XY, YZ, XZ) model

```{r}
loglin.pairwise <- loglin(table = HairEyeColor, 
                          margin = list(c(1, 2), c(1, 3), c(2, 3)), 
                          fit = TRUE) # fit = TRUE means we want to see the fitted values
# margin = list(c(1, 2), c(1, 3), c(2, 3)) means we are using the (XY, YZ, XZ) model
loglin.pairwise$fit
pchisq(loglin.pairwise$lrt, loglin.pairwise$df, lower.tail = FALSE)
```
Since the last p-value is high, we conclude that the model with pairwise interactions and no 3-factor interaction fits well.

### Fitting the (XY, Z) model

```{r}
loglin.xy.z <- loglin(table = HairEyeColor, 
                          margin = list(c(1, 2), 3), 
                          fit = TRUE) # fit = TRUE means we want to see the fitted values
# margin = list(c(1, 2), 3) means we are using the (XY, Z) model
loglin.xy.z$fit
```

### Fitting the independence model

```{r}
loglin.x.y.z <- loglin(table = HairEyeColor, 
                          margin = list(1, 2, 3), 
                          fit = TRUE) # fit = TRUE means we want to see the fitted values
# margin = list(1, 2, 3) means we are using the (X, Y, Z) model
loglin.x.y.z$fit
```


```{r}
sessionInfo()
```
