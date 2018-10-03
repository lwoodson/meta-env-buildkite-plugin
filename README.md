# meta-env-buildkite-plugin
Buildkite plugin that makes it easy to propagate BuildKite Meta Data to
environment variables in effect during a build.

## Usage
1. Make some meta-data availanle
2. Run a step with the `meta-env` plugin configured for the meta-data
   you want to propagate to environment variables
3. Source the `.meta-env` file in your build root to export the
   environment variables w/propagated meta-data.

Example:
```
steps:
  # collect the TARGET_ENVIRONMENT, LAMBDA_NAME and DEPLOY_VERSION
  # meta-data with a block step
  - block: ":question: specify deploy information"
    prompt: "Specify the deploy information
    fields:
      - select: Choose the environment to deploy to
        key: TARGET_ENVIRONMENT
        required: rue
        options:
          - label: staging
            value: staging
          - label: production
            value: production
      - text: Specify the lambda function
        key: LAMBDA_NAME
        required: true
      - text: Specify the deployment version
        key: DEPLOY_VERSION
        required: true

  # Export the TARGET_ENVIRONMENT, LAMBDA_NAME and DEPLOY_VERSION meta data
  # as environment variables
  - label: ":rocket: do deployment"
    command: source .meta-env && deploy $TARGET_ENVIRONMENT $LAMBDA_NAME $DEPLOY_VERSION
    plugins:
      shippingeasy/meta-env#v0.1.0:
        meta-data:
          - TARGET_ENVIRONMENT
          - LAMBDA_NAME
          - DEPLOY_VERSION
```
