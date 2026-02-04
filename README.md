This project examines the short-run relationship between entry into informal caregiving and subjective well-being using UK longitudinal survey data. The purpose of the repository is to demonstrate a clear and structured econometric workflow in Stata rather than to provide a fully reproducible replication.

The analysis uses data from the UK Household Longitudinal Study. Due to data licensing restrictions, the underlying microdata are not included. The Stata do-file illustrates how the analysis is structured and how key methods are implemented, assuming legal access to the data.

Subjective well-being is measured using a general health questionnaire score, where higher values indicate better well-being. The treatment of interest is short-run entry into caregiving. Individuals who transition into caregiving are compared with those who do not over the same period.

The do-file implements baseline Ordinary Least Squares estimates, Propensity Score Matching, and Difference-in-Differences specifications. The Difference-in-Differences approach exploits within-individual variation over time and controls for time-invariant individual characteristics. Standard errors are clustered at the individual level, and additional checks assess the plausibility of the parallel trends assumption.

Results suggest that entry into caregiving is associated with a short-run decline in subjective well-being. Estimates from Difference-in-Differences are smaller in magnitude than cross-sectional estimates, consistent with unobserved heterogeneity inflating naive associations. All results should be interpreted as associations rather than causal effects.

This repository contains a single Stata do-file demonstrating the analytical approach used in the project. A project report is included for additional context.
