# Mimicks autoplot() for glmer-like plots.

diagnose.glmer <- function(model, leverage.threshold=0.175){
  library(gridExtra)
  library(ggplot2)
  qqplot.data <- function (vec){
    y <- quantile(vec[!is.na(vec)], c(0.25, 0.75))
    x <- qnorm(c(0.25, 0.75))
    slope <- diff(y)/diff(x)
    int <- y[1L] - slope * x[1L]

    d <- data.frame(resids = vec)
    plot <- ggplot(d, aes(sample = resids)) +
      stat_qq(alpha=0.8) +
      geom_abline(slope = slope, intercept = int, col = "blue", alpha=0.8) +
      ggtitle("Normal Q-Q of Residuals") +
      theme_minimal() +
      xlab("Theoretical Quantiles") + ylab("Pearson Residuals")
    return(plot)
  }

  p1 <- ggplot(
    data.frame(eta=predict(model,type="link"),
               pearson=residuals(model, type="pearson")
        ),
    aes(x=eta, y=pearson)
    ) +
    geom_point(alpha=0.8) +
    theme_minimal() +
    ggtitle("Residuals vs Estimates") +
    xlab("Estimates") + ylab("Pearson Residuals") +
    geom_smooth(col="blue", method = "loess", formula = "y ~ x", se=FALSE, alpha=0.8, size = 0.7)

  p2 <- qqplot.data(residuals(model))

  lever <- suppressWarnings(hatvalues(model))
  toohigh <- which(lever >= leverage.threshold)
  len <- length(residuals(model))

  stuff <- data.frame(lev=lever,pearson=residuals(model,type="pearson"), len=seq(from=1, to=len, by=1))

  p3 <- ggplot(stuff, aes(x=lev, y=pearson, label=len)) +
    geom_point(alpha=0.8) +
    theme_minimal() +
    ggtitle("Residuals vs Leverage") +
    xlab("Leverage") + ylab("Pearson Residuals") +
    geom_point(data=subset(stuff, stuff$lev >= leverage.threshold), col="red", shape=1, size=2.8) +
    geom_smooth(col="blue", method = "loess", formula = "y ~ x", se=FALSE, alpha=0.8, size = 0.7)

  objclass <- suppressWarnings(class(model))[1]

  if(objclass == "glmerMod"){
    p4 <- ggplot(model, aes(fitted(model), sqrt(abs(residuals(model)))))+geom_point(na.rm=TRUE) +
    stat_smooth(method="loess", na.rm = TRUE, col="blue", size=0.7, se=FALSE)+xlab("Fitted Value") +
    ylab(expression(sqrt("|Standardized residuals|"))) +
    ggtitle("Scale-Location")+ theme_minimal()
    grid.arrange(p1, p2, p4, p3, nrow = 2)
  }else{
    grid.arrange(p1, p2, p3, nrow = 2)
  }


  if (length(toohigh) != 0){
    print(paste("The point(s)", paste(toohigh, collapse=", "), "have leverage which is higher than", leverage.threshold, sep=" "))
  }
  if(summary(model)[["family"]] == "poisson"){
    require(blmeco)
    paste("Residual deviance over DOF for Poisson model: ", dispersion_glmer(model), sep="")
  }
}
