context("Basic metrics")

expect_01 <- function(x) {
  expect_true(all(x >= 0))
  expect_true(all(x <= 1))
}

sanity <- function(m) {
  expect_is(m, "irmetric")
  expect_01(m$metric)
  expect_01(m$C)
  expect_01(m$W)
  expect_01(m$L)
  expect_true(all(m$cum.metric <= m$metric))
  expect_true(all(m$cum.ETU <= m$ETU))
  expect_01(m$residual)
  expect_01(m$metric + m$residual)
}

sanity_static <- function(m) {
  sanity(m) ; expect_equal(m$residual + sum(m$W), 1, tolerance=0.001)
}

sanity_noresid <- function(m) {
  sanity(m) ; expect_equal(sum(m$W), 1, tolerance=0.001) ; expect_equal(m$residual, 0)
}

test_that("Precision is well-behaved", {
  tmp <- P(c(1), k=1)
  sanity_noresid(tmp) ; expect_equal(tmp$metric, 1) ; expect_equal(tmp$ETU, 1)
  expect_equal(tmp$C, c(0)) ; expect_equal(tmp$W, c(1)) ; expect_equal(tmp$L, c(1)) ; expect_equal(tmp$cum.ETU, c(1))
  tmp <- P(c(1, 0), k=1)
  sanity_noresid(tmp) ; expect_equal(tmp$metric, 1) ; expect_equal(tmp$ETU, 1)
  expect_equal(tmp$C, c(0,0)) ; expect_equal(tmp$W, c(1,0)) ; expect_equal(tmp$L, c(1,0)) ; expect_equal(tmp$cum.ETU, c(1,0))
  tmp <- P(c(0), k=1)
  sanity_noresid(tmp) ; expect_equal(tmp$metric, 0) ; expect_equal(tmp$ETU, 0)
  expect_equal(tmp$C, c(0)) ; expect_equal(tmp$W, c(1)) ; expect_equal(tmp$L, c(1)) ; expect_equal(tmp$cum.ETU, c(0))

  tmp <- P(c(1, 0, 0, 0, 0), k=5)
  sanity_noresid(tmp) ; expect_equal(tmp$metric, 0.2) ; expect_equal(tmp$ETU, 1)
  expect_equal(tmp$C, c(1,1,1,1,0)) ; expect_equal(tmp$W, rep(.2,5)) ; expect_equal(tmp$L, c(0,0,0,0,1)) ; expect_equal(tmp$cum.ETU, c(0,0,0,0,1))
  tmp <- P(c(0, 0, 0, 0, 1), k=5)
  sanity_noresid(tmp) ; expect_equal(tmp$metric, 0.2) ; expect_equal(tmp$ETU, 1)
  expect_equal(tmp$C, c(1,1,1,1,0)) ; expect_equal(tmp$W, rep(.2,5)) ; expect_equal(tmp$L, c(0,0,0,0,1)) ; expect_equal(tmp$cum.ETU, c(0,0,0,0,1))
  tmp <- P(c(0, 0, 0, 0, 0), k=5)
  sanity_noresid(tmp) ; expect_equal(tmp$metric, 0) ; expect_equal(tmp$ETU, 0)
  expect_equal(tmp$C, c(1,1,1,1,0)) ; expect_equal(tmp$W, rep(.2,5)) ; expect_equal(tmp$L, c(0,0,0,0,1)) ; expect_equal(tmp$cum.ETU, c(0,0,0,0,0))
})

test_that("Precision complains with a list too short", {
  expect_warning(tmp <- P(c(1,0,0,0), k=5), "Doc N \\(4\\) is less than minimum expected \\(5\\). Padding with gain=NA.")
  sanity(tmp) ; expect_equal(tmp$metric, 0.2) ; expect_equal(tmp$residual, 0.2) ; expect_equal(tmp$ETU, 1)
  expect_equal(tmp$C, c(1,1,1,1,0)) ; expect_equal(tmp$W, rep(.2,5)) ; expect_equal(tmp$L, c(0,0,0,0,1)) ; expect_equal(tmp$cum.ETU, c(0,0,0,0,1))
})

test_that("Precision is well-behaved with unjudged documents", {
  tmp <- P(c(1,NA,0,0,0), k=5)
  sanity(tmp) ; expect_equal(tmp$metric, 0.2) ; expect_equal(tmp$residual, 0.2) ; expect_equal(tmp$ETU, 1)
  expect_equal(tmp$C, c(1,1,1,1,0)) ; expect_equal(tmp$W, rep(.2,5)) ; expect_equal(tmp$L, c(0,0,0,0,1)) ; expect_equal(tmp$cum.ETU, c(0,0,0,0,1))

  tmp <- P(c(0,NA,0,0,0), k=5)
  sanity(tmp) ; expect_equal(tmp$metric, 0.0) ; expect_equal(tmp$residual, 0.2) ; expect_equal(tmp$ETU, 0)
  expect_equal(tmp$C, c(1,1,1,1,0)) ; expect_equal(tmp$W, rep(.2,5)) ; expect_equal(tmp$L, c(0,0,0,0,1)) ; expect_equal(tmp$cum.ETU, c(0,0,0,0,0))

  tmp <- P(c(NA,NA,NA,NA,NA), k=5)
  sanity(tmp) ; expect_equal(tmp$metric, 0.0) ; expect_equal(tmp$residual, 1.0) ; expect_equal(tmp$ETU, 0)
  expect_equal(tmp$C, c(1,1,1,1,0)) ; expect_equal(tmp$W, rep(.2,5)) ; expect_equal(tmp$L, c(0,0,0,0,1)) ; expect_equal(tmp$cum.ETU, c(0,0,0,0,0))
})

test_that("RBP is well-behaved", {
  tmp <- RBP(c(1), p=.6)
  sanity_static(tmp) ; expect_equal(tmp$metric, .4) ; expect_equal(tmp$ETU, 1)
  expect_equal(tmp$C, c(.6)) ; expect_equal(tmp$W, c(.4)) ; expect_equal(tmp$L, c(.4)) ; expect_equal(tmp$cum.ETU, c(.4))

  tmp <- RBP(c(0), p=.6)
  sanity_static(tmp) ; expect_equal(tmp$metric, 0) ; expect_equal(tmp$ETU, 0)
  expect_equal(tmp$C, c(.6)) ; expect_equal(tmp$W, c(.4)) ; expect_equal(tmp$L, c(.4)) ; expect_equal(tmp$cum.ETU, c(0))
})

test_that("INST is well-behaved", {
  tmp <- INST(c(1), T=1)
  sanity(tmp) ; expect_equal(tmp$metric, 0.608, tolerance=0.001) ; expect_equal(tmp$metric + tmp$residual, 1) ; expect_equal(tmp$ETU, 1, tolerance=0.001)
  tmp <- INST(c(0), T=1)
  sanity(tmp) ; expect_equal(tmp$metric, 0) ; expect_equal(tmp$ETU, 0)

  # these are from Moffat et al., ADCS'15
  adcs <- c(0,1,.5,0,0,1,0,.2,0,1)
  adcs.inst <- INST(adcs, T=2)
  sanity(adcs.inst) ; expect_equal(adcs.inst$metric, 0.306, tolerance=0.001) ; expect_equal(adcs.inst$residual, 0.1, tolerance=0.001)
})

test_that("RR is well-behaved", {
  tmp <- RR(c(1))
  sanity(tmp) ; expect_equal(tmp$metric, 1) ; expect_equal(tmp$ETU, 1)
  expect_equal(tmp$C, c(0)) ; expect_equal(tmp$W, c(1)) ; expect_equal(tmp$L, c(1)) ; expect_equal(tmp$cum.ETU, c(1))
  tmp <- RR(c(0, 1))
  sanity(tmp) ; expect_equal(tmp$metric, .5) ; expect_equal(tmp$ETU, 1)
  expect_equal(tmp$C, c(1,0)) ; expect_equal(tmp$W, c(.5,.5)) ; expect_equal(tmp$L, c(0,1)) ; expect_equal(tmp$cum.ETU, c(0,1))
  tmp <- RR(c(0, 1, 1))
  sanity(tmp) ; expect_equal(tmp$metric, .5) ; expect_equal(tmp$ETU, 1)
  expect_equal(tmp$C, c(1,0,0)) ; expect_equal(tmp$W, c(.5,.5,0)) ; expect_equal(tmp$L, c(0,1,0)) ; expect_equal(tmp$cum.ETU, c(0,1,0))
  tmp <- RR(c(0))
  sanity(tmp) ; expect_equal(tmp$metric, 0) ; expect_equal(tmp$ETU, 0)
  expect_equal(tmp$C, c(1)) ; expect_equal(tmp$W, c(1)) ; expect_equal(tmp$L, c(0)) ; expect_equal(tmp$cum.ETU, c(0))
})

test_that("ERR is well-behaved", {
  tmp <- ERR(c(1))
  sanity(tmp) ; expect_equal(tmp$metric, 1)
  expect_equal(tmp$C, c(0)) ; expect_equal(tmp$W, c(1)) ; expect_equal(tmp$L, c(1))
  tmp <- ERR(c(0, 1))
  sanity(tmp) ; expect_equal(tmp$metric, .5)
  expect_equal(tmp$C, c(1,0)) ; expect_equal(tmp$W, c(.5,.5)) ; expect_equal(tmp$L, c(0,1))
  tmp <- ERR(c(0, 1, 1))
  sanity(tmp) ; expect_equal(tmp$metric, .5)
  expect_equal(tmp$C, c(1,0,0)) ; expect_equal(tmp$W, c(.5,.5,0)) ; expect_equal(tmp$L, c(0,1,0))
  tmp <- ERR(c(0))
  sanity(tmp) ; expect_equal(tmp$metric, 0)
  expect_equal(tmp$C, c(1)) ; expect_equal(tmp$W, c(1)) ; expect_equal(tmp$L, c(0))

  tmp <- ERR(c(.5))
  sanity(tmp) ; expect_equal(tmp$metric, .5)
  expect_equal(tmp$C, c(.5)) ; expect_equal(tmp$W, c(1)) ; expect_equal(tmp$L, c(.5))
  tmp <- ERR(c(0, .5))
  sanity(tmp) ; expect_equal(tmp$metric, .25)
  expect_equal(tmp$C, c(1,.5)) ; expect_equal(tmp$W, c(.5,.5)) ; expect_equal(tmp$L, c(0,.5))
  tmp <- ERR(c(0, .5, .5))
  sanity(tmp) ; expect_equal(tmp$metric, .3)
  expect_equal(tmp$C, c(1,.5,.5)) ; expect_equal(tmp$W, c(.4,.4,.2)) ; expect_equal(tmp$L, c(0,.5,.25))
})

test_that("SDCG is well-behaved", {
  tmp <- SDCG(c(1), k=1)
  sanity_noresid(tmp) ; expect_equal(tmp$metric, 1) ; expect_equal(tmp$ETU, 1)
  tmp <- SDCG(c(1, 0), k=2)
  sanity_noresid(tmp) ; expect_equal(tmp$metric, .613, tolerance=0.001) ; expect_equal(tmp$ETU, 1)
  tmp <- SDCG(c(0), k=1)
  sanity_noresid(tmp) ; expect_equal(tmp$metric, 0) ; expect_equal(tmp$ETU, 0)

  tmp <- SDCG(c(1, 0, 0, 0, 0), k=5)
  sanity_noresid(tmp) ; expect_equal(tmp$metric, .339, tolerance=0.001) ; expect_equal(tmp$ETU, 1)
  tmp <- SDCG(c(0, 0, 0, 0, 1), k=5)
  sanity_noresid(tmp) ; expect_equal(tmp$metric, .131, tolerance=0.001) ; expect_equal(tmp$ETU, .387, tolerance=0.001)
  tmp <- SDCG(c(0, 0, 0, 0, 0), k=5)
  sanity_noresid(tmp) ; expect_equal(tmp$metric, 0)

  # check truncation works
  tmp <- SDCG(c(1, 0, 0, 0, 0), k=2)
  sanity_noresid(tmp) ; expect_equal(tmp$metric, .613, tolerance=0.001) ; expect_equal(tmp$ETU, 1)
  tmp <- SDCG(c(0, 0, 0, 0, 1), k=2)
  sanity_noresid(tmp) ; expect_equal(tmp$metric, 0) ; expect_equal(tmp$ETU, 0)
  tmp <- SDCG(c(0, 0, 0, 0, 0), k=2)
  sanity_noresid(tmp) ; expect_equal(tmp$metric, 0) ; expect_equal(tmp$ETU, 0)
})

test_that("AP is well-behaved", {
  tmp <- AP(c(1))
  sanity_noresid(tmp) ; expect_equal(tmp$metric, 1) ; expect_equal(tmp$ETU, 1)
  tmp <- AP(c(0))
  sanity_noresid(tmp) ; expect_equal(tmp$metric, 0) ; expect_equal(tmp$ETU, 0)
  tmp <- AP(c(0,1,0,0,1,1)) # from CIKM'13
  sanity_noresid(tmp) ; expect_equal(tmp$metric, 0.467, tolerance=0.001)
})
