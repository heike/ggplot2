% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/facet-wrap.r
\name{facet_wrap}
\alias{facet_wrap}
\title{Wrap a 1d ribbon of panels into 2d}
\usage{
facet_wrap(
  facets,
  nrow = NULL,
  ncol = NULL,
  scales = "fixed",
  shrink = TRUE,
  labeller = "label_value",
  as.table = TRUE,
  switch = deprecated(),
  drop = TRUE,
  dir = "h",
  strip.position = "top"
)
}
\arguments{
\item{facets}{A set of variables or expressions quoted by \code{\link[=vars]{vars()}}
and defining faceting groups on the rows or columns dimension.
The variables can be named (the names are passed to \code{labeller}).

For compatibility with the classic interface, can also be a
formula or character vector. Use either a one sided formula, \code{~a + b},
or a character vector, \code{c("a", "b")}.}

\item{nrow, ncol}{Number of rows and columns.}

\item{scales}{Should scales be fixed (\code{"fixed"}, the default),
free (\code{"free"}), or free in one dimension (\code{"free_x"},
\code{"free_y"})?}

\item{shrink}{If \code{TRUE}, will shrink scales to fit output of
statistics, not raw data. If \code{FALSE}, will be range of raw data
before statistical summary.}

\item{labeller}{A function that takes one data frame of labels and
returns a list or data frame of character vectors. Each input
column corresponds to one factor. Thus there will be more than
one with \code{vars(cyl, am)}. Each output
column gets displayed as one separate line in the strip
label. This function should inherit from the "labeller" S3 class
for compatibility with \code{\link[=labeller]{labeller()}}. You can use different labeling
functions for different kind of labels, for example use \code{\link[=label_parsed]{label_parsed()}} for
formatting facet labels. \code{\link[=label_value]{label_value()}} is used by default,
check it for more details and pointers to other options.}

\item{as.table}{If \code{TRUE}, the default, the facets are laid out like
a table with highest values at the bottom-right. If \code{FALSE}, the
facets are laid out like a plot with the highest value at the top-right.}

\item{switch}{By default, the labels are displayed on the top and
right of the plot. If \code{"x"}, the top labels will be
displayed to the bottom. If \code{"y"}, the right-hand side
labels will be displayed to the left. Can also be set to
\code{"both"}.}

\item{drop}{If \code{TRUE}, the default, all factor levels not used in the
data will automatically be dropped. If \code{FALSE}, all factor levels
will be shown, regardless of whether or not they appear in the data.}

\item{dir}{Direction: either \code{"h"} for horizontal, the default, or \code{"v"},
for vertical.}

\item{strip.position}{By default, the labels are displayed on the top of
the plot. Using \code{strip.position} it is possible to place the labels on
either of the four sides by setting \code{strip.position = c("top",
  "bottom", "left", "right")}}
}
\description{
\code{facet_wrap()} wraps a 1d sequence of panels into 2d. This is generally
a better use of screen space than \code{\link[=facet_grid]{facet_grid()}} because most
displays are roughly rectangular.
}
\examples{
p <- ggplot(mpg, aes(displ, hwy)) + geom_point()

# Use vars() to supply faceting variables:
p + facet_wrap(vars(class))

# Control the number of rows and columns with nrow and ncol
p + facet_wrap(vars(class), nrow = 4)

\donttest{
# You can facet by multiple variables
ggplot(mpg, aes(displ, hwy)) +
  geom_point() +
  facet_wrap(vars(cyl, drv))

# Use the `labeller` option to control how labels are printed:
ggplot(mpg, aes(displ, hwy)) +
  geom_point() +
  facet_wrap(vars(cyl, drv), labeller = "label_both")

# To change the order in which the panels appear, change the levels
# of the underlying factor.
mpg$class2 <- reorder(mpg$class, mpg$displ)
ggplot(mpg, aes(displ, hwy)) +
  geom_point() +
  facet_wrap(vars(class2))

# By default, the same scales are used for all panels. You can allow
# scales to vary across the panels with the `scales` argument.
# Free scales make it easier to see patterns within each panel, but
# harder to compare across panels.
ggplot(mpg, aes(displ, hwy)) +
  geom_point() +
  facet_wrap(vars(class), scales = "free")

# To repeat the same data in every panel, simply construct a data frame
# that does not contain the faceting variable.
ggplot(mpg, aes(displ, hwy)) +
  geom_point(data = transform(mpg, class = NULL), colour = "grey85") +
  geom_point() +
  facet_wrap(vars(class))

# Use `strip.position` to display the facet labels at the side of your
# choice. Setting it to `bottom` makes it act as a subtitle for the axis.
# This is typically used with free scales and a theme without boxes around
# strip labels.
ggplot(economics_long, aes(date, value)) +
  geom_line() +
  facet_wrap(vars(variable), scales = "free_y", nrow = 2, strip.position = "top") +
  theme(strip.background = element_blank(), strip.placement = "outside")
}
}
