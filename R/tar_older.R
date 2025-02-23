#' @title List old targets
#' @export
#' @family time
#' @description List all the targets whose last successful run occurred
#'   before a certain point in time. Combine with [tar_invalidate()],
#'   you can use `tar_older()` to automatically rerun targets at
#'   regular intervals. See the examples for a demonstration.
#' @details Only applies to targets with recorded time stamps:
#'   just non-branching targets and individual dynamic branches.
#'   As of `targets` version 0.6.0, these time
#'   stamps are available for these targets regardless of
#'   storage format. Earlier versions of `targets` do not record
#'   time stamps for remote storage such as `format = "url"`
#'   or `repository = "aws"` in [tar_target()].
#' @return A character vector of names of old targets with recorded
#'   timestamp metadata.
#' @inheritParams tar_meta
#' @param names Names of eligible targets. Targets excluded from `names`
#'   will not be returned even if they are old.
#'   You can supply symbols
#'   or `tidyselect` helpers like [all_of()] and [starts_with()].
#'   If `NULL`, all names are eligible.
#' @param time A `POSIXct` object of length 1, time threshold.
#'   Targets older than this time stamp are returned.
#'   For example, if `time = Sys.time() - as.difftime(1, units = "weeks")`
#'   then `tar_older()` returns targets older than one week ago.
#' @param inclusive Logical of length 1, whether to include targets
#'   built at exactly the `time` given.
#' @examples
#' if (identical(Sys.getenv("TAR_EXAMPLES"), "true")) {
#' tar_dir({ # tar_dir() runs code from a temporary directory.
#' tar_script({
#'   list(tar_target(x, seq_len(2)))
#' }, ask = FALSE)
#' tar_make()
#' # targets older than 1 week ago
#' tar_older(Sys.time() - as.difftime(1, units = "weeks"))
#' # targets older than 1 week from now
#' tar_older(Sys.time() + as.difftime(1, units = "weeks"))
#' # Everything is still up to date.
#' tar_make()
#' # Invalidate all targets targets older than 1 week from now
#' # so they run on the next tar_make().
#' invalidate_these <- tar_older(Sys.time() + as.difftime(1, units = "weeks"))
#' tar_invalidate(all_of(invalidate_these))
#' tar_make()
#' })
#' }
tar_older <- function(
  time,
  names = NULL,
  inclusive = FALSE,
  store = targets::tar_config_get("store")
) {
  tar_assert_scalar(time)
  tar_assert_inherits(time, "POSIXct")
  tar_assert_scalar(inclusive)
  tar_assert_lgl(inclusive)
  tar_assert_path(path_meta(path_store = store))
  meta <- meta_init(path_store = store)
  meta <- tibble::as_tibble(meta$database$read_condensed_data())
  meta <- meta[!is.na(meta$time), ]
  meta$time <- file_time_posixct(meta$time)
  names_quosure <- rlang::enquo(names)
  names <- tar_tidyselect_eval(names_quosure, meta$name) %|||% meta$name
  if_any(
    inclusive,
    meta$name[meta$name %in% names & meta$time <= time],
    meta$name[meta$name %in% names & meta$time < time]
  )
}
