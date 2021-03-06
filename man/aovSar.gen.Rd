% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/aovSar.gen.R
\name{aovSar.gen}
\alias{aovSar.gen}
\title{Using a SAR model to handle spatial dependence in an aov model.}
\usage{
aovSar.gen(formula, coord, seq.radius, data = NULL)
}
\arguments{
\item{formula}{A formula specifying the model.}

\item{coord}{A matrix or data.frame of point coordinates.}

\item{seq.radius}{A complex vector containing a radii sequence used to set the neighborhood pattern.
The default sequence has ten numbers from 0 to half of the maximum distance between the samples.}

\item{data}{A data frame in which the variables specified in the formula will be found.}
}
\value{
\code{aovSar.gen} returns an object of \code{\link[base]{class}} "SARaov".
The functions summary and anova are used to obtain and print a summary and analysis of variance
table of the results.
An object of class "SARaov" is a list containing the following components:

\item{DF}{degrees of freedom of rho, treatments, residual and total.}
\item{SS}{sum of squares of residuals and total.}
\item{residuals}{residuals of the adjusted model.}
\item{MS}{mean square of residuals and total.}
\item{rho}{the autoregressive parameter.}
\item{Par}{data.frame with the radius tested and its AIC.}
\item{modelAdj}{model of class \code{\link[stats]{aov}} using the adjusted response.}
\item{modelstd}{data frame containing the ANOVA table using non-adjusted response.}
\item{namey}{response variable name.}
}
\description{
Fit a completely randomized design when the experimental units have some degree of
spatial dependence using a Spatial Lag Model (SAR).
}
\details{
Three assumptions are made about the error in the analysis of variance (ANOVA):

1. the errors are normally distributed and, on average, zero;

2. the errors all have the same variance (they are homoscedastic), and

3. the errors are unrelated to each other (they are independent across observations).

When these assumptions are not satisfied, data transformations in the response variable are
often used to circumvent this problem. For example, in absence of normality, the Box-Cox
transformation can be used.

However, in many experiments, especially field trials, there is a type of correlation generated by
the sample locations known as spatial correlation, and this condition violates the independence assumption.
In this setting, this function provides an alternative for using ANOVA when the errors are spatially
correlated, by using a data transformation discussed in Long (1996)

\deqn{Y_{adj} = Y - (\hat{\rho}WY - \hat{\rho}\beta_0),}

where \eqn{\hat{\rho}} denotes the autoregressive spatial parameter of the SAR model estimated by
lagsarlm, \eqn{\beta_0} is the overall mean and W is a spatial neighborhood matrix which neighbors are defined as the
samples located within a radius, this radius is specified as a sequence in \code{seq.radius}. For each radius
in \code{seq.radius} the model is computed as well its AIC, then the radius chosen is the one
that minimizes AIC.

The aim of this transformation is converting autocorrelated observations into non-correlated observations
in order to apply the analysis of variance and obtain suitable inferences.
}
\examples{
data("crd_simulated")
coord <- cbind(crd_simulated$coordX, crd_simulated$coordY)
cv <- aovSar.gen(y ~ trat, coord, data = crd_simulated)
cv

#Summary for class SARanova
summary(cv)

#Anova for class SARanova
anova(cv)

}
\references{
Long, D. S. "Spatial statistics for analysis of variance of agronomic field trials."
Practical handbook of spatial statistics. CRC Press, Boca Raton, FL (1996): 251-278.

Rossoni, D. F.; Lima, R. R. . Autoregressive analysis of variance for experiments with spatial
dependence between plots: a simulation study. Revista Brasileira de Biometria, 2019

Scolforo, Henrique Ferraço, et al. "Autoregressive spatial analysis and individual
tree modeling as strategies for the management of Eremanthus erythropappus." Journal of
forestry research 27.3 (2016): 595-603.
}
