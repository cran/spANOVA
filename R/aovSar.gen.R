#' @name aovSar.gen
#'
#' @title Using a SAR model to handle spatial dependence in an aov model.
#' @description Fit a completely randomized design when the experimental units have some degree of
#' spatial dependence using a Spatial Lag Model (SAR).
#' @usage aovSar.gen(formula, coord, seq.radius, data = NULL)
#'
#' @param formula A formula specifying the model.
#' @param coord A matrix or data.frame of point coordinates.
#' @param data A data frame in which the variables specified in the formula will be found.
#' @param seq.radius A complex vector containing a radii sequence used to set the neighborhood pattern.
#' The default sequence has ten numbers from 0 to half of the maximum distance between the samples.
#'
#' @details
#' Three assumptions are made about the error in the analysis of variance (ANOVA):
#'
#' 1. the errors are normally distributed and, on average, zero;
#'
#' 2. the errors all have the same variance (they are homoscedastic), and
#'
#' 3. the errors are unrelated to each other (they are independent across observations).
#'
#'When these assumptions are not satisfied, data transformations in the response variable are
#'often used to circumvent this problem. For example, in absence of normality, the Box-Cox
#'transformation can be used.
#'
#'However, in many experiments, especially field trials, there is a type of correlation generated by
#'the sample locations known as spatial correlation, and this condition violates the independence assumption.
#'In this setting, this function provides an alternative for using ANOVA when the errors are spatially
#'correlated, by using a data transformation discussed in Long (1996)
#'
#' \deqn{Y_{adj} = Y - (\hat{\rho}WY - \hat{\rho}\beta_0),}
#'
#'where \eqn{\hat{\rho}} denotes the autoregressive spatial parameter of the SAR model estimated by
#'lagsarlm, \eqn{\beta_0} is the overall mean and W is a spatial neighborhood matrix which neighbors are defined as the
#'samples located within a radius, this radius is specified as a sequence in \code{seq.radius}. For each radius
#'in \code{seq.radius} the model is computed as well its AIC, then the radius chosen is the one
#'that minimizes AIC.
#'
#' The aim of this transformation is converting autocorrelated observations into non-correlated observations
#' in order to apply the analysis of variance and obtain suitable inferences.
#'
#' @return \code{aovSar.gen} returns an object of \code{\link[base]{class}} "SARaov".
#' The functions summary and anova are used to obtain and print a summary and analysis of variance
#' table of the results.
#' An object of class "SARaov" is a list containing the following components:
#'
#' \item{DF}{degrees of freedom of rho, treatments, residual and total.}
#' \item{SS}{sum of squares of residuals and total.}
#' \item{residuals}{residuals of the adjusted model.}
#' \item{MS}{mean square of residuals and total.}
#' \item{rho}{the autoregressive parameter.}
#' \item{Par}{data.frame with the radius tested and its AIC.}
#' \item{modelAdj}{model of class \code{\link[stats]{aov}} using the adjusted response.}
#' \item{modelstd}{data frame containing the ANOVA table using non-adjusted response.}
#' \item{namey}{response variable name.}
#'
#'
#' @references Long, D. S. "Spatial statistics for analysis of variance of agronomic field trials."
#' Practical handbook of spatial statistics. CRC Press, Boca Raton, FL (1996): 251-278.
#'
#' Rossoni, D. F.; Lima, R. R. . Autoregressive analysis of variance for experiments with spatial
#' dependence between plots: a simulation study. Revista Brasileira de Biometria, 2019
#'
#' Scolforo, Henrique Ferraço, et al. "Autoregressive spatial analysis and individual
#' tree modeling as strategies for the management of Eremanthus erythropappus." Journal of
#' forestry research 27.3 (2016): 595-603.
#'
#'
#' @examples
#' data("crd_simulated")
#' coord <- cbind(crd_simulated$coordX, crd_simulated$coordY)
#' cv <- aovSar.gen(y ~ trat, coord, data = crd_simulated)
#' cv
#'
#' #Summary for class SARanova
#' summary(cv)
#'
#' #Anova for class SARanova
#' anova(cv)
#'
#' @importFrom utils capture.output
#' @importFrom car Anova
#' @export
aovSar.gen <- function(formula, coord, seq.radius, data = NULL) {

  # Defensive programming
  if(!(is.matrix(coord) | inherits(coord, "SpatialPoints"))) {
    stop("'coord' must be a matrix")
  }

  if(ncol(coord) < 2){
    stop("'coord' must have at least two columns")
  }

  if(missing(data)){
    stop("'data' must be provided")
  }

  if(!inherits(data, "data.frame")){
    stop("'data' must be a data.frame")
  }

  if(is.data.frame(coord)){
    coord <- as.matrix(coord, ncol = ncol(coord))
  }

  if(missing(seq.radius)){
    max.dist <- max(dist(coord))
    seq.radius <- seq(0, 0.5*max.dist, l = 11)[-1]
  }

  params <- data.frame(radius = 0, rho = 0, AIC = 0)
  anova.list <- list()
  p.radius <- length(seq.radius)
  Y_ajus <- NULL
  form.char <- invisible(capture.output(print(formula, showEnv = FALSE)))
  formula.sar <- as.formula(form.char)


  for (i in 1:p.radius) {
    nb <- dnearneigh(coord, 0, seq.radius[i])
    w <- try(nb2mat(nb, style = "W"), silent = TRUE)
    test <- grepl("Error", w)

    # Se caso nao forem encontradas amostras dentro do raio especificado
    k <- 0.1 # incremento
    while(test[1] == TRUE){
      seq.radius <- seq(0, (0.5+k)*max.dist, l = 11)[-1]
      nb <- dnearneigh(coord, 0, seq.radius[i])
      w <- try(nb2mat(nb, style = "W"), silent = TRUE)
      test <- grepl("Error", w)
      k <- k + 0.1
    }

    listw <- nb2listw(nb, glist = NULL, style = "W")

    # SAR model
    SAR <- lagsarlm(formula.sar, data = data, listw = listw,
                    method = "eigen", tol.solve = 1e-15)
    ajuste <- summary(SAR)
    rho <- as.numeric(ajuste["rho"]$rho)
    params[i, ] <- c(raio = seq.radius[i], rho = rho, AIC = AIC(SAR))
  }

  # Separar o nome da variavel resposta na formula para substitui-la por Y_ajus
  form.split <- strsplit(form.char, "~")[[1]]
  new.formula <- as.formula(paste("Y_ajus","~",form.split[2]))
  resp.name <- sub(" ","",form.split[1])
  resp <- data[ ,resp.name]

  # Adjusting the data and constructing the ANOVA table
  best.par <- which.min(params$AIC)
  beta <- mean(resp)
  nb <- dnearneigh(coord, 0, seq.radius[best.par])
  w <- nb2mat(nb, style = "W")
  Y_ajus <- resp - (params[best.par,"rho"] * w%*%resp - params[best.par,"rho"] * beta)
  model.cl <- aov(formula, data = data)
  aov.cl <- anova(model.cl)

  # Fazer a analise com os dados ajustados
  new.data <- data
  new.data[ ,resp.name] <- Y_ajus
  model.adj <- aov(new.formula, data = new.data)
  aov.adj <- anova(model.adj)
  Sqt.nadj <- sum(aov.cl[,2])

  #Degres of freedom
  glerror <- model.cl$df.residual

  #Sum of squares
  sqerror <- sum(model.cl$residuals^2)
  sqtot <- sum(aov.adj[,2])
  sqtotcor <- Sqt.nadj - sqtot

  #Mean Squares
  mserror <- sqerror/glerror

  name.y <- names(attr(model.cl$terms,"dataClasses")[1])

  outpt <- list(DF = glerror,
                SS = c(sqerror, sqtotcor),
                residuals = resid(model.adj),
                MS = c(mserror),
                rho = params[best.par,"rho"], Par = params,
                modelAdj = model.adj, modelstd = aov.cl, namey = name.y)

  class(outpt)<-c("SARaov",class(aov.adj))
  return(outpt)
}

# Print method for this class
#' @export
#' @method print SARaov
print.SARaov <- function(x, ...) {
  cat("Response: ", x$namey, "\n")
  rse <- sqrt(x$MS)
  cat("\n")
  cat("Residual standard error:",rse)
  cat("\n")
  cat("Spatial autoregressive parameter:", x$rho,"\n")
  cat("Samples considered neighbor within a",x$Par[which.min(x$Par[,3]),1],"units radius")
}

# Summary method for this class
#' @export
#' @method summary SARaov
summary.SARaov <- function(object, ...) {
  cat("      Summary of SARaov","\n","\n")
  cat("Parameters tested:","\n")
  print(object$Par)
  cat("\n")
  cat("Selected parameters:","\n")
  print(object$Par[which.min(object$Par[,3]),])
}

# Anova method for this class
#' @export
#' @method anova SARaov
anova.SARaov <- function(object, type = c("II","III", 2, 3), compare = FALSE, verbose = TRUE, ...) {
  type <- as.character(type)
  type <- match.arg(type)

  if(missing(type)){
    type = "II"
  }

  if(is.logical(compare) == FALSE){
    warning("'compare' must be logical. Assuming compare == FALSE")
    compare = FALSE
  }
  if(verbose){
  cat("Analysis of Variance With Spatially Correlated Errors","\n")
  cat("\n")
  print(Anova(object$modelAdj, type = type))}


  if(compare){
    if(verbose){
    cat("\n", "\n")
    cat("---------------------------------------------------------------","\n")
    cat("Standard Analysis of Variance", "\n")
    cat("---------------------------------------------------------------")
    cat("\n")
    print(object$modelstd)}
  }

  return(invisible(Anova(object$modelAdj, type = type)))

}


#exportar a funcao stars.pval do pacote gtools

