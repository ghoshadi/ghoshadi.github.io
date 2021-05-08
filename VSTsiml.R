# Poisson classical C.I. v/s VST C.I.

z = qnorm(0.025, lower.tail = F)

poi.exmpl<-function(theta, n, flag = 0 ){
	x = rpois(n, theta)
	xbar = mean(x)
	swd = z*sqrt(xbar)/sqrt(n) 
	lwr = xbar - swd; uppr = xbar + swd
	if((theta < lwr) || (theta > uppr)) cl = 0
	else cl = 1
	if(flag != 0) cat("\nclassic 95% c.i. [", lwr, ",", uppr, "], width = ", uppr - lwr, "\n\n")
	swd = z/(2*sqrt(n))
	lwr = max(sqrt(xbar) - swd, 0)^2 ; uppr = (sqrt(xbar) + swd)^2
	if((theta < lwr) || (theta > uppr)) vs = 0
	else vs = 1
	if(flag != 0) cat("vst 95% c.i. [", lwr, ",", uppr, "], width = ", uppr - lwr, "\n\n")
	return(list(clssc = cl, vst = vs))
}

theta = 3; n = 30
poi.exmpl(theta, n, flag = 1)

theta.list = c(0.25, 0.5, 1, 2, 4, 8)

set.seed(1234)
n = 30; B = 10^5
mat = matrix(nrow = 1, ncol = 2)
for(theta in theta.list){
	comp = 0
	for(k in 1:B) comp = comp + as.numeric(poi.exmpl(theta, n))
	mat = rbind(mat, comp/B)        # classic aage, vst pore
}
poi.table1 = mat[-1,]
colnames(poi.table1) = c("classical", "vst")
poi.table1

set.seed(1234)
n = 100; B = 10^5
theta.list = c(0.25, 0.5, 1, 2, 4, 8)
mat = matrix(nrow = 1, ncol = 2)
for(theta in theta.list){
	comp = 0
	for(k in 1:B) comp = comp + as.numeric(poi.exmpl(theta, n))
	mat = rbind(mat, comp/B)        # classic aage, vst pore
}
poi.table2 = mat[-1,]
colnames(poi.table2) = c("classical", "vst")


# Binomial classical C.I. v/s VST C.I.

bin.exmpl<-function(theta, n, flag = 0){
	x = rbinom(n, 1, theta)
	xbar = mean(x)
	swd = z*sqrt(xbar*(1 - xbar))/sqrt(n) 
	lwr = xbar - swd; uppr = xbar + swd
	if((theta < lwr) || (theta > uppr)) cl = 0
	else cl = 1
	if(flag != 0) cat("\nclassic 95% c.i. [", lwr, ",", uppr, "], width = ", uppr - lwr, "\n\n")
	swd = z/(2*sqrt(n))
	lwr = sin(max(asin(xbar) - swd, 0)) ; uppr = sin(min(asin(xbar) + swd, pi/2))
	if((theta < lwr) || (theta > uppr)) vs = 0
	else vs = 1
	if(flag != 0) cat("vst 95% c.i. [", lwr, ",", uppr, "], width = ", uppr - lwr, "\n\n")
	return(list(clssc = cl, vst = vs))
}

theta = 0.5; n = 30
bin.exmpl(theta, n, flag = 1)

p.list = c(0.1, 0.25, 0.5, 0.75, 0.9)

set.seed(1234)
n = 30; B = 10^5
mat = matrix(nrow = 1, ncol = 2)
for(theta in p.list){
	comp = 0
	for(k in 1:B) comp = comp + as.numeric(bin.exmpl(theta, n))
	mat = rbind(mat, comp/B)        # classic aage, vst pore
}
bin.table1 = mat[-1,]
colnames(bin.table1) = c("classical", "vst")

set.seed(1234)
n = 100; B = 10^5
mat = matrix(nrow = 1, ncol = 2)
for(theta in p.list){
	comp = 0
	for(k in 1:B) comp = comp + as.numeric(bin.exmpl(theta, n))
	mat = rbind(mat, comp/B)        # classic aage, vst pore
}
bin.table2 = mat[-1,]
colnames(bin.table2) = c("classical", "vst")

library(xtable)
print(xtable(cbind(theta.list, poi.table1, poi.table2), type = "latex", digits = 3), include.rownames = FALSE)
print(xtable(cbind(p.list, bin.table1, bin.table2), type = "latex", digits = 3), include.rownames = FALSE)

