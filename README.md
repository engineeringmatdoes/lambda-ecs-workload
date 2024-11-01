# Lambda and ECS behind an ALB

This project will demonstrate using Lambda in a target behind an ALB and if introducing and scaling up ECS tasks when sustained load is present provides performance improvements or not.

This capability is ideal for solutions with long idle periods and infrequent high utilisation periods. Given that AWS allows Lambdas to be deployed from container images, lets see if we can use the same image to run ECS tasks which will allow us to choose the appropriate deployment style to meet demands in the most cost effective way.

This solution is targeting use of an ALB over API Gateway to test this approach due to issues some businesses face in their AWS account structures that may inhibit the use of API Gateway for internal use. In future I may take a look at API Gateway as an alternative for this solution but for now it is out of scope.

## Why and when would this approach be useful?

- To promote improved reuse of applications and artifacts, reducing the burden on teams needing to manage additional code and artifacts to meet both use cases (eg. Function or Container.)
- To reduce costs and simplify maintenance and release activities.
- This could be ideal for situations where use of S3 as a static-website is not possible, serving the packaged static assets from the container image instead. Implementing a proxy of an S3 bucket is out of scope for this exercise.
- Small microservice applications with a short startup time could be run within Lambda with relative ease.

## The goal

1. To achieve the lowest OpEx cost to operate and maintain a service in AWS during long idle periods.
1. To simplify the development and release process for maintaining the service.
1. To determine the performance capabilities of both Lambda and ECS, and possibly a combination of both. This should take into account Lambda warmup time.
1. Determine if this is a viable solution that should be considered when conditions and circumstances align.

## Development environment

To build and deploy this project you will need a few tools:

1. AWS CLI
1. Docker CLI, eg. Linux Docker, Docker Desktop or equivalent.
1. Make
1. NodeJS ~20.x

All supporting commands to build and deploy this project to your AWS account are managed by Make. You can get the task list by simply running `make` or `make help` on the command line.
