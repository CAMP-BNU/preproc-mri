#' Execulte system command with given environment variables
#'
#' @param template Path to the executable template file.
#' @param env A named list of environment variables to set before run.
#' @return This function is called mainly for side effect. And the returned
#'   value is the same as `system()`.
#' @export
system_with_env <- function(template, env = NULL) {
    if (!is.null(env)) {
        do.call(Sys.setenv, env)
    }
    system(template)
}
