skip_on_cran() # This test suite is long-running (on cran) and is skipped

test_that("colourbar trains without labels", {
  g <- guide_colorbar()
  sc <- scale_colour_continuous(limits = c(0, 4), labels = NULL)

  out <- guide_train(g, sc)
  expect_equal(names(out$key), c("colour", ".value"))
})

test_that("Colorbar respects show.legend in layer", {
  df <- data_frame(x = 1:3, y = 1)
  p <- ggplot(df, aes(x = x, y = y, color = x)) +
    geom_point(size = 20, shape = 21, show.legend = FALSE)
  expect_false("guide-box" %in% ggplotGrob(p)$layout$name)
  p <- ggplot(df, aes(x = x, y = y, color = x)) +
    geom_point(size = 20, shape = 21, show.legend = TRUE)
  expect_true("guide-box" %in% ggplotGrob(p)$layout$name)
})

test_that("show.legend handles named vectors", {
  n_legends <- function(p) {
    g <- ggplotGrob(p)
    gb <- which(g$layout$name == "guide-box")
    if (length(gb) > 0) {
      n <- length(g$grobs[[gb]]) - 1
    } else {
      n <- 0
    }
    n
  }

  df <- data_frame(x = 1:3, y = 20:22)
  p <- ggplot(df, aes(x = x, y = y, color = x, shape = factor(y))) +
    geom_point(size = 20)
  expect_equal(n_legends(p), 2)

  p <- ggplot(df, aes(x = x, y = y, color = x, shape = factor(y))) +
    geom_point(size = 20, show.legend = c(color = FALSE))
  expect_equal(n_legends(p), 1)

  p <- ggplot(df, aes(x = x, y = y, color = x, shape = factor(y))) +
    geom_point(size = 20, show.legend = c(color = FALSE, shape = FALSE))
  expect_equal(n_legends(p), 0)

  # c.f.https://github.com/tidyverse/ggplot2/issues/3461
  p <- ggplot(df, aes(x = x, y = y, color = x, shape = factor(y))) +
    geom_point(size = 20, show.legend = c(shape = FALSE, color = TRUE))
  expect_equal(n_legends(p), 1)
})

test_that("axis_label_overlap_priority always returns the correct number of elements", {
  expect_identical(axis_label_priority(0), numeric(0))
  expect_setequal(axis_label_priority(1), seq_len(1))
  expect_setequal(axis_label_priority(5), seq_len(5))
  expect_setequal(axis_label_priority(10), seq_len(10))
  expect_setequal(axis_label_priority(100), seq_len(100))
})

test_that("axis_label_element_overrides errors when angles are outside the range [0, 90]", {
  expect_s3_class(axis_label_element_overrides("bottom", 0), "element")
  expect_error(axis_label_element_overrides("bottom", 91), "`angle` must")
  expect_error(axis_label_element_overrides("bottom", -91), "`angle` must")
})

test_that("a warning is generated when guides are drawn at a location that doesn't make sense", {
  plot <- ggplot(mpg, aes(class, hwy)) +
    geom_point() +
    scale_y_continuous(guide = guide_axis(position = "top"))
  built <- expect_silent(ggplot_build(plot))
  expect_warning(ggplot_gtable(built), "Position guide is perpendicular")
})

test_that("a warning is not generated when a guide is specified with duplicate breaks", {
  plot <- ggplot(mpg, aes(class, hwy)) +
    geom_point() +
    scale_y_continuous(breaks = c(20, 20))
  built <- expect_silent(ggplot_build(plot))
  expect_silent(ggplot_gtable(built))
})

test_that("a warning is generated when more than one position guide is drawn at a location", {
  plot <- ggplot(mpg, aes(class, hwy)) +
    geom_point() +
    guides(
      y = guide_axis(position = "left"),
      y.sec = guide_axis(position = "left")
    )
  built <- expect_silent(ggplot_build(plot))

  # TODO: These multiple warnings should be summarized nicely. Until this gets
  #       fixed, this test ignores all the following errors than the first one.
  suppressWarnings(
    expect_warning(ggplot_gtable(built), "Discarding guide")
  )
})

test_that("a warning is not generated when properly changing the position of a guide_axis()", {
  plot <- ggplot(mpg, aes(class, hwy)) +
    geom_point() +
    guides(
      y = guide_axis(position = "right")
    )
  built <- expect_silent(ggplot_build(plot))
  expect_silent(ggplot_gtable(built))
})

test_that("guide_none() can be used in non-position scales", {
  p <- ggplot(mpg, aes(cty, hwy, colour = class)) +
    geom_point() +
    scale_color_discrete(guide = guide_none())

  built <- ggplot_build(p)
  plot <- built$plot
  guides <- build_guides(
    plot$scales,
    plot$layers,
    plot$mapping,
    "right",
    theme_gray(),
    plot$guides,
    plot$labels
  )

  expect_identical(guides, zeroGrob())
})

test_that("Using non-position guides for position scales results in an informative error", {
  p <- ggplot(mpg, aes(cty, hwy)) +
    geom_point() +
    scale_x_continuous(guide = guide_legend())

  built <- ggplot_build(p)
  expect_error(ggplot_gtable(built), "does not implement guide_transform()")
})

test_that("guide merging for guide_legend() works as expected", {

  merge_test_guides <- function(scale1, scale2) {
    scale1$guide <- guide_legend(direction = "vertical")
    scale2$guide <- guide_legend(direction = "vertical")
    scales <- scales_list()
    scales$add(scale1)
    scales$add(scale2)

    guide_list <- guides_train(scales, theme = theme_gray(), labels = labs(), guides = guides())
    guides_merge(guide_list)
  }

  different_limits <- merge_test_guides(
    scale_colour_discrete(limits = c("a", "b", "c", "d")),
    scale_linetype_discrete(limits = c("a", "b", "c"))
  )
  expect_length(different_limits, 2)

  same_limits <- merge_test_guides(
    scale_colour_discrete(limits = c("a", "b", "c")),
    scale_linetype_discrete(limits = c("a", "b", "c"))
  )
  expect_length(same_limits, 1)
  expect_equal(same_limits[[1]]$key$.label, c("a", "b", "c"))

  same_labels_different_limits <- merge_test_guides(
    scale_colour_discrete(limits = c("a", "b", "c")),
    scale_linetype_discrete(limits = c("one", "two", "three"), labels = c("a", "b", "c"))
  )
  expect_length(same_labels_different_limits, 1)
  expect_equal(same_labels_different_limits[[1]]$key$.label, c("a", "b", "c"))

  same_labels_different_scale <- merge_test_guides(
    scale_colour_continuous(limits = c(0, 4), breaks = 1:3, labels = c("a", "b", "c")),
    scale_linetype_discrete(limits = c("a", "b", "c"))
  )
  expect_length(same_labels_different_scale, 1)
  expect_equal(same_labels_different_scale[[1]]$key$.label, c("a", "b", "c"))

  repeated_identical_labels <- merge_test_guides(
    scale_colour_discrete(limits = c("one", "two", "three"), labels = c("label1", "label1", "label2")),
    scale_linetype_discrete(limits = c("1", "2", "3"), labels = c("label1", "label1", "label2"))
  )
  expect_length(repeated_identical_labels, 1)
  expect_equal(repeated_identical_labels[[1]]$key$.label, c("label1", "label1", "label2"))
})

test_that("size = NA doesn't throw rendering errors", {
  df = data.frame(
    x = c(1, 2),
    group = c("a","b")
  )
  p <- ggplot(df, aes(x = x, y = 0, colour = group)) +
    geom_point(size = NA, na.rm = TRUE)

  expect_silent(plot(p))
})

# Visual tests ------------------------------------------------------------

test_that("axis guides are drawn correctly", {
  theme_test_axis <- theme_test() + theme(axis.line = element_line(size = 0.5))
  test_draw_axis <- function(n_breaks = 3,
                             break_positions = seq_len(n_breaks) / (n_breaks + 1),
                             labels = as.character,
                             positions = c("top", "right", "bottom", "left"),
                             theme = theme_test_axis,
                             ...) {

    break_labels <- labels(seq_along(break_positions))

    # create the axes
    axes <- lapply(positions, function(position) {
      draw_axis(break_positions, break_labels, axis_position = position, theme = theme, ...)
    })
    axes_grob <- gTree(children = do.call(gList, axes))

    # arrange them so there's some padding on each side
    gt <- gtable(
      widths = unit(c(0.05, 0.9, 0.05), "npc"),
      heights = unit(c(0.05, 0.9, 0.05), "npc")
    )
    gt <- gtable_add_grob(gt, list(axes_grob), 2, 2, clip = "off")
    plot(gt)
  }

  # basic
  expect_doppelganger("axis guides basic", function() test_draw_axis())
  expect_doppelganger("axis guides, zero breaks", function() test_draw_axis(n_breaks = 0))

  # overlapping text
  expect_doppelganger(
    "axis guides, check overlap",
    function() test_draw_axis(20, labels = function(b) comma(b * 1e9), check.overlap = TRUE)
  )

  # rotated text
  expect_doppelganger(
    "axis guides, zero rotation",
    function() test_draw_axis(10, labels = function(b) comma(b * 1e3), angle = 0)
  )

  expect_doppelganger(
    "axis guides, positive rotation",
    function() test_draw_axis(10, labels = function(b) comma(b * 1e3), angle = 45)
  )

  expect_doppelganger(
    "axis guides, negative rotation",
    function() test_draw_axis(10, labels = function(b) comma(b * 1e3), angle = -45)
  )

  expect_doppelganger(
    "axis guides, vertical rotation",
    function() test_draw_axis(10, labels = function(b) comma(b * 1e3), angle = 90)
  )

  expect_doppelganger(
    "axis guides, vertical negative rotation",
    function() test_draw_axis(10, labels = function(b) comma(b * 1e3), angle = -90)
  )

  # dodged text
  expect_doppelganger(
    "axis guides, text dodged into rows/cols",
    function() test_draw_axis(10, labels = function(b) comma(b * 1e9), n.dodge = 2)
  )
})

test_that("axis guides are drawn correctly in plots", {
  expect_doppelganger("align facet labels, facets horizontal",
    qplot(hwy, reorder(model, hwy), data = mpg) +
      facet_grid(manufacturer ~ ., scales = "free", space = "free") +
      theme_test() +
      theme(strip.text.y = element_text(angle = 0))
  )
  expect_doppelganger("align facet labels, facets vertical",
    qplot(reorder(model, hwy), hwy, data = mpg) +
      facet_grid(. ~ manufacturer, scales = "free", space = "free") +
      theme_test() +
      theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5))
  )
  expect_doppelganger("thick axis lines",
    qplot(wt, mpg, data = mtcars) +
      theme_test() +
      theme(axis.line = element_line(size = 5, lineend = "square"))
  )
})

test_that("axis guides can be customized", {
  plot <- ggplot(mpg, aes(class, hwy)) +
    geom_point() +
    scale_y_continuous(
      sec.axis = dup_axis(guide = guide_axis(n.dodge = 2)),
      guide = guide_axis(n.dodge = 2)
    ) +
    scale_x_discrete(guide = guide_axis(n.dodge = 2))

  expect_doppelganger("guide_axis() customization", plot)
})

test_that("guides can be specified in guides()", {
  plot <- ggplot(mpg, aes(class, hwy)) +
    geom_point() +
    guides(
      x = guide_axis(n.dodge = 2),
      y = guide_axis(n.dodge = 2),
      x.sec = guide_axis(n.dodge = 2),
      y.sec = guide_axis(n.dodge = 2)
    )

  expect_doppelganger("guides specified in guides()", plot)
})

test_that("guides have the final say in x and y", {
  df <- data_frame(x = 1, y = 1)
  plot <- ggplot(df, aes(x, y)) +
    geom_point() +
    guides(
      x = guide_none(title = "x (primary)"),
      y = guide_none(title = "y (primary)"),
      x.sec = guide_none(title = "x (secondary)"),
      y.sec = guide_none(title = "y (secondary)")
    )

  expect_doppelganger("position guide titles", plot)
})

test_that("guides are positioned correctly", {
  df <- data_frame(x = 1, y = 1, z = factor("a"))

  p1 <- ggplot(df, aes(x, y, colour = z)) +
    geom_point() +
    labs(title = "title of plot") +
    theme_test() +
    theme(
      axis.text.x = element_text(angle = 90, vjust = 0.5),
      legend.background = element_rect(fill = "grey90"),
      legend.key = element_rect(fill = "grey90")
    ) +
    scale_x_continuous(breaks = 1, labels = "very long axis label") +
    scale_y_continuous(breaks = 1, labels = "very long axis label")

  expect_doppelganger("legend on left",
    p1 + theme(legend.position = "left")
  )
  expect_doppelganger("legend on bottom",
    p1 + theme(legend.position = "bottom")
  )
  expect_doppelganger("legend on right",
    p1 + theme(legend.position = "right")
  )
  expect_doppelganger("legend on top",
    p1 + theme(legend.position = "top")
  )
  expect_doppelganger("facet_grid, legend on left",
    p1 + facet_grid(x~y) + theme(legend.position = "left")
  )
  expect_doppelganger("facet_grid, legend on bottom",
    p1 + facet_grid(x~y) + theme(legend.position = "bottom")
  )
  expect_doppelganger("facet_grid, legend on right",
    p1 + facet_grid(x~y) + theme(legend.position = "right")
  )
  expect_doppelganger("facet_grid, legend on top",
    p1 + facet_grid(x~y) + theme(legend.position = "top")
  )
  expect_doppelganger("facet_wrap, legend on left",
    p1 + facet_wrap(~ x) + theme(legend.position = "left")
  )
  expect_doppelganger("facet_wrap, legend on bottom",
    p1 + facet_wrap(~ x) + theme(legend.position = "bottom")
  )
  expect_doppelganger("facet_wrap, legend on right",
    p1 + facet_wrap(~ x) + theme(legend.position = "right")
  )
  expect_doppelganger("facet_wrap, legend on top",
    p1 + facet_wrap(~ x) + theme(legend.position = "top")
  )

  # padding
  dat <- data_frame(x = LETTERS[1:3], y = 1)
  p2 <- ggplot(dat, aes(x, y, fill = x, colour = 1:3)) +
    geom_bar(stat = "identity") +
    guides(color = "colorbar") +
    theme_test() +
    theme(legend.background = element_rect(colour = "black"))

  expect_doppelganger("padding in legend box", p2)

  # Placement of legend inside
  expect_doppelganger("legend inside plot, centered",
    p2 + theme(legend.position = c(.5, .5))
  )
  expect_doppelganger("legend inside plot, bottom left",
    p2 + theme(legend.justification = c(0,0), legend.position = c(0,0))
  )
  expect_doppelganger("legend inside plot, top right",
    p2 + theme(legend.justification = c(1,1), legend.position = c(1,1))
  )
  expect_doppelganger("legend inside plot, bottom left of legend at center",
    p2 + theme(legend.justification = c(0,0), legend.position = c(.5,.5))
  )
})

test_that("guides title and text are positioned correctly", {
  df <- data_frame(x = 1:3, y = 1:3)
  p <- ggplot(df, aes(x, y, color = factor(x), fill = y)) +
    geom_point(shape = 21) +
    # setting the order explicitly removes the risk for failed doppelgangers
    # due to legends switching order
    guides(color = guide_legend(order = 2),
           fill = guide_colorbar(order = 1)) +
    theme_test()

  expect_doppelganger("multi-line guide title works",
    p +
      scale_color_discrete(name = "the\ndiscrete\ncolorscale") +
      scale_fill_continuous(name = "the\ncontinuous\ncolorscale")
  )
  expect_doppelganger("vertical gap of 1cm between guide title and guide",
    p + theme(legend.spacing.y = grid::unit(1, "cm"))
  )
  expect_doppelganger("horizontal gap of 1cm between guide and guide text",
    p + theme(legend.spacing.x = grid::unit(1, "cm"))
  )

  # now test label positioning, alignment, etc
  df <- data_frame(x = c(1, 10, 100))
  p <- ggplot(df, aes(x, x, color = x, size = x)) +
    geom_point() +
    # setting the order explicitly removes the risk for failed doppelgangers
    # due to legends switching order
    guides(shape = guide_legend(order = 1),
           color = guide_colorbar(order = 2)) +
    theme_test()

  expect_doppelganger("guide title and text positioning and alignment via themes",
    p + theme(
      legend.title = element_text(hjust = 0.5, margin = margin(t = 30)),
      legend.text = element_text(hjust = 1, margin = margin(l = 5, t = 10, b = 10))
    )
  )

  # title and label rotation
  df <- data_frame(x = c(5, 10, 15))
  p <- ggplot(df, aes(x, x, color = x, fill = 15 - x)) +
    geom_point(shape = 21, size = 5, stroke = 3) +
    scale_colour_continuous(
      name = "value",
      guide = guide_colorbar(
        title.theme = element_text(size = 11, angle = 0, hjust = 0.5, vjust = 1),
        label.theme = element_text(size = 0.8*11, angle = 270, hjust = 0.5, vjust = 1),
        order = 2 # set guide order to keep visual test stable
      )
    ) +
    scale_fill_continuous(
      breaks = c(5, 10, 15),
      limits = c(5, 15),
      labels = paste("long", c(5, 10, 15)),
      name = "fill value",
      guide = guide_legend(
        direction = "horizontal",
        title.position = "top",
        label.position = "bottom",
        title.theme = element_text(size = 11, angle = 180, hjust = 0, vjust = 1),
        label.theme = element_text(size = 0.8*11, angle = 90, hjust = 1, vjust = 0.5),
        order = 1
      )
    )

  expect_doppelganger("rotated guide titles and labels", p )
})

test_that("colorbar can be styled", {
  df <- data_frame(x = c(0, 1, 2))
  p <- ggplot(df, aes(x, x, color = x)) + geom_point()

  expect_doppelganger("white-to-red colorbar, white ticks, no frame",
    p + scale_color_gradient(low = 'white', high = 'red')
  )

  expect_doppelganger("white-to-red colorbar, thick black ticks, green frame",
    p + scale_color_gradient(
          low = 'white', high = 'red',
          guide = guide_colorbar(
            frame.colour = "green",
            frame.linewidth = 1.5,
            ticks.colour = "black",
            ticks.linewidth = 2.5
            )
        )
    )
})

test_that("guides can handle multiple aesthetics for one scale", {
  df <- data_frame(x = c(1, 2, 3),
                   y = c(6, 5, 7))

  p <- ggplot(df, aes(x, y, color = x, fill = y)) +
    geom_point(shape = 21, size = 3, stroke = 2) +
    scale_colour_viridis_c(
      name = "value",
      option = "B", aesthetics = c("colour", "fill")
    )

  expect_doppelganger("one combined colorbar for colour and fill aesthetics", p)
})

test_that("bin guide can be styled correctly", {
  df <- data_frame(x = c(1, 2, 3),
                   y = c(6, 5, 7))

  p <- ggplot(df, aes(x, y, size = x)) +
    geom_point() +
    scale_size_binned()

  expect_doppelganger("guide_bins looks as it should", p)
  expect_doppelganger("guide_bins can show limits",
    p + guides(size = guide_bins(show.limits = TRUE))
  )
  expect_doppelganger("guide_bins can show arrows",
    p + guides(size = guide_bins(axis.arrow = arrow(length = unit(1.5, "mm"), ends = "both")))
  )
  expect_doppelganger("guide_bins can remove axis",
    p + guides(size = guide_bins(axis = FALSE))
  )
  expect_doppelganger("guide_bins work horizontally",
    p + guides(size = guide_bins(direction = "horizontal"))
  )
})

test_that("coloursteps guide can be styled correctly", {
  df <- data_frame(x = c(1, 2, 4),
                   y = c(6, 5, 7))

  p <- ggplot(df, aes(x, y, colour = x)) +
    geom_point() +
    scale_colour_binned(breaks = c(1.5, 2, 3))

  expect_doppelganger("guide_coloursteps looks as it should", p)
  expect_doppelganger("guide_coloursteps can show limits",
    p + guides(colour = guide_coloursteps(show.limits = TRUE))
  )
  expect_doppelganger("guide_coloursteps can have bins relative to binsize",
    p + guides(colour = guide_coloursteps(even.steps = FALSE))
  )
  expect_doppelganger("guide_bins can show ticks",
    p + guides(colour = guide_coloursteps(ticks = TRUE))
  )
})

test_that("a warning is generated when guides(<scale> = FALSE) is specified", {
  df <- data_frame(x = c(1, 2, 4),
                   y = c(6, 5, 7))

  # warn on guide(<scale> = FALSE)
  expect_warning(g <- guides(colour = FALSE), "The `<scale>` argument of `guides()` cannot be `FALSE`. Use \"none\" instead as of ggplot2 3.3.4.", fixed = TRUE)
  expect_equal(g[["colour"]], "none")

  # warn on scale_*(guide = FALSE)
  p <- ggplot(df, aes(x, y, colour = x)) + scale_colour_continuous(guide = FALSE)
  built <- expect_silent(ggplot_build(p))
  expect_warning(ggplot_gtable(built), "It is deprecated to specify `guide = FALSE`")
})
