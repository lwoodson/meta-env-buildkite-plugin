# meta-env-buildkite-plugin
Buildkite plugin that makes it easy to access BuildKite meta-data from
build scripts without them having a dependency on the `buildkite-agent`.
It does this by propagating specified meta-data to environment variables
in a sourceable script prior to a step's command execution.

## Usage
NOTE: It is recommended that this plugin be used with the docker or
docker-compose plugins.  This will ensure environment changes are
sandboxed to the container execution.  It is unknown/tested at this
time if running outside of a container will result in env var's
persisting on the agent node beyond the life of a single pipeline
execution.

The basic steps for usage are:

1. Make some meta-data available
2. Run a step with the `meta-env` plugin configured for the meta-data
   you want to propagate to environment variables
3. Source the `.meta-env` file in your build root to export the
   environment variables w/propagated meta-data.

Example:
```yml
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
  - command: source .meta-env && deploy $TARGET_ENVIRONMENT $LAMBDA_NAME $DEPLOY_VERSION
    label: ":rocket: do deployment"
    plugins:
      - shippingeasy/meta-env#v0.1.2:
          meta-data:
            - TARGET_ENVIRONMENT
            - LAMBDA_NAME
            - DEPLOY_VERSION
      - docker-compose#v2.5.1:
          run: deploy-env
```

The following happens with the above pipeline:

* We collect the `TARGET_ENVIRONMENT`, `LAMBDA_NAME` and `DEPLOY_VERSION` as
  meta-data with the `block` step.
* The `post-checkout` hook of the `meta-env` plugin executes to generate the
  `.meta-env` file at the root of the build checkout directory
* The `.meta-env` file is a sourceable bash script that contains environment
  variable exports for the `TARGET_ENVIRONMENT`, `LAMBDA_NAME` and
  `DEPLOY_VERSION` meta-data
* The `docker-compose` plugin runs the command step within the context of the
  `deploy-env` service/container defined in a `docker-compose.yaml` fle.
* The `command` run in the container first sources the `.meta-env` file to
  set the `TARGET_ENVIRONMENT`, `LAMBDA_NAME` and `DEPLOY_VERSION` env
  variables within the container only
* The `command` run in the container then executes the `deploy` script,
  passing in `TARGET_ENVIRONMENT`, `LAMBDA_NAME` and `DEPLOY_VERSION`
  as command-line args.

## Contributing
Feel free to fork, hack and submit a PR.  Make sure the tests still pass with

```
docker-compose run tests
```

Changes should also be submitted with tests of the added/changed functionality
