# spANOVA 0.99.4


## Major Updates:
Title Length Reduction: The length of the package title has been reduced to less than 65 characters as per the recommendations of the R CRAN revisor.

Improved Author Declaration: Authors, Maintainer, and Contributors are now declared using the `Authors@R` field with appropriate roles specified using `person()` calls. This enhances clarity and conformity with R standards.

## Enhanced Documentation:

Added `\value` to .Rd files for exported methods, explaining the structure and meaning of function results.
Missing `\value` tags in `spANOVAapp.Rd` and `spCrossvalid.Rd` have been rectified.

Preservation of User Settings: Modifications to user options, par, or working directory have been revised. Functions now ensure the restoration of settings using immediate calls of `on.exit()`, preventing unintended alterations.

# spANOVA 0.99.3

## Bug-fixes

* S3 methods `anova`, `print` and `summary` are no longer imported from `spatialreg`

# spANOVA 0.99.2

## Bug-fixes

* Addressing `_R_CLASS_MATRIX_ARRAY_=true`, switch from class to inherits.


# spANOVA 0.99.1

## Bug-fixes

* `spTukey()` shows the original mean and the spatial filtered mean.

* `aovGeo()` The iterative process take into account the semivariogram parameters in the initial model.

* `spANOVAapp()` shows a loader when the output is (re)calculating.


# spANOVA 0.99.0

The first working version of the package.

