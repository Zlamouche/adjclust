#' Adjacency-constrained Clustering of Hi-C contact maps
#' 
#' Adjacency-constrained hierarchical agglomerative clustering of Hi-C contact
#' maps
#' 
#' Adjacency-constrained hierarchical agglomerative clustering (HAC) is HAC in
#' which each observation is associated to a position, and the clustering is 
#' constrained so as only adjacent clusters are merged. Genomic regions (loci)
#' are clustered according to information provided by high-throughput
#' conformation capture data (Hi-C).
#' 
#' @param x either: 1. A pxp contact map of class Matrix::dsCMatrix in which the
#'   entries are the number of counts of physical interactions observed between 
#'   all pairs of loci 2. An object of class HiTC::HTCexp. The corresponding 
#'   Hi-C data is stored as a Matrix::dsCMatrix object in the intdata slot 3. A 
#'   text file with one line per pair of loci for which an interaction has been 
#'   observed (in the format: locus1<tab>locus2<tab>signal).
#'   
#' @param h band width. If not provided, \code{h} is set to default value `p-1`.
#' 
#' @param log logical. Whether to log-transform the count data. Default to 
#' \code{FALSE}.
#'   
#' @param \dots further arguments to be passed to \code{\link{read.table}} 
#'   function when \code{x} is a text file name. If not provided, the text file 
#'   is supposed to be separated by tabulations, with no header.
#'   
#' @return An object of class \code{\link{chac}}.
#'   
#' @seealso \code{\link{adjClust}} \code{\link[HiTC:HTCexp]{HTCexp}}
#'   
#' @references Dehman A. (2015) \emph{Spatial Clustering of Linkage 
#'   Disequilibrium Blocks for Genome-Wide Association Studies}, PhD thesis, 
#'   Universite Paris Saclay.
#'   
#' @references Servant N. \emph{et al} (2012). \emph{HiTC : Exploration of 
#'   High-Throughput 'C' experiments. Bioinformatics}.
#'   
#' @examples
#' # input as HiTC::HTCexp object
#' if (require("HiTC", quietly = TRUE)) {
#'   load(system.file("extdata", "hic_imr90_40_XX.rda", package = "adjclust"))
#'   res1 <- hicClust(hic_imr90_40_XX)
#' }
#' 
#' # input as Matrix::dsCMatrix contact map
#' \dontrun{
#' mat <- HiTC::intdata(hic_imr90_40_XX) 
#' res2 <- hicClust(mat)
#' }
#' 
#' # input as text file
#' res3 <- hicClust(system.file("extdata", "sample.txt", package = "adjclust"))
#' 
#' @export
#' 
#' @importFrom utils read.table

hicClust <- function(x, h = NULL, log = FALSE, ...) {
  
  if (!is.null(h)) {
    if (!is.numeric(h))
      stop("h should be numeric")
  }
    
  inclass <- class(x)
  if (inclass == "HTCexp" && !requireNamespace("HiTC", quietly = TRUE)) {
    stop("Package 'HiTC' not available. This function cannot be used with 'HTCexp' data.")
  } else {
    if( (inclass != "dsCMatrix") && (inclass !=  "HTCexp") && (!file.exists(x)) )
      stop("Invalid Input:x should be a text file or an object of class Matrix::dsCMatrix/HiTC::HTCexp")
      
    if (inclass == "dsCMatrix" || inclass  == "HTCexp") {
      if (inclass == "HTCexp") {
        x <- HiTC::intdata(x)
      }
      if (log) x@x <- log(x@x + 1)
      p <- x@Dim[1]
      if (is.null(h)) h <- p-1  
        res <- adjClust(x, type = "similarity", h)
        return(res)
    } else {
      inoptions <- list(...)
      inoptions$file <- x
      if (is.null(inoptions$sep)) {
        inoptions$sep <- "\t"
      }
      if (is.null(inoptions$header)) {
        inoptions$header <- FALSE
      }
      if (is.null(inoptions$stringsAsFactors)) {
          inoptions$stringsAsFactors <- FALSE
      }
      df <- do.call("read.table", inoptions) 
          
      lis <- sort(unique(c(df[,1], df[,2])))
      p <- length(lis)
      rowindx <- match(df[,1], lis)
      colindx <- match(df[,2], lis)
          
      mat <- matrix(0, nrow = p, ncol = p)
      if (log) {
        mat[cbind(rowindx,colindx)] <- mat[cbind(colindx,rowindx)] <- log(df[,3] + 1)
      } else {
        mat[cbind(rowindx,colindx)] <- mat[cbind(colindx,rowindx)] <- df[,3]
      }
        
      if (is.null(h)) h <- p-1  
      res <- adjClust(mat, type = "similarity", h = h)
      res$method <- "hicClust"
        
      return(res)
    }
  }
}
