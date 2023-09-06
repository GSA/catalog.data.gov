The data.gov team has deployed its own CloudFront service on the SSB AWS account, instead of using the CloudFront that comes with cloud.gov. This gives us finer control over the CloudFront configurations and allows us to use the latest CloudFront features.

The CloudFront for catalog.data.gov is hosted on the ssb-production AWS account. The CloudFront for catalog-stage.data.gov and catalog-dev.data.gov are hosted on the ssb-development AWS account.

This document contains the CloudFront configurations for all three apps.