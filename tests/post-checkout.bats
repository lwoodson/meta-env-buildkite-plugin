#!/usr/bin/env bats

load "$BATS_PATH/load.bash"

setup() {
  export BUILDKITE_BUILD_CHECKOUT_PATH='.'
}

@test "sets no environment variables for no mappings" {
  # Set up plugin environment

  # run the plugin hook
  run $PWD/hooks/post-checkout
  assert_success
  refute_output --partial "Propagating meta-data TARGET_ENVIRONMENT to env var"
  refute_output --partial "Propagating meta-data LAMBDA_NAME to env var"
  refute_output --partial "Propagating meta-data DEPLOY_VERSION to env var"

  # simulate execution of 'source .meta-env' as part of step's command
  source .meta-env

  # validate environment vars set up for specified meta-data
  run echo "${TARGET_ENVIRONMENT}"
  assert_success
  assert_output ""

  run echo "${LAMBDA_NAME}"
  assert_success
  assert_output ""

  run echo "${DEPLOY_VERSION}"
  assert_success
  assert_output ""
}

@test "sets environment variable for single mapping" {
  export BUILDKITE_PLUGIN_META_ENV_META_DATA_0="TARGET_ENVIRONMENT"

  stub buildkite-agent "meta-data get TARGET_ENVIRONMENT : echo staging"

  # run the plugin hook
  run $PWD/hooks/post-checkout

  # simulate execution of 'source .meta-env' as part of step's command
  source .meta-env
  assert_success
  assert_output --partial "Propagating meta-data TARGET_ENVIRONMENT to env var"
  refute_output --partial "Propagating meta-data LAMBDA_NAME to env var"
  refute_output --partial "Propagating meta-data DEPLOY_VERSION to env var"

  # validate environment vars set up for specified meta-data
  run echo "${TARGET_ENVIRONMENT}"
  assert_success
  assert_output "staging"

  run echo "${LAMBDA_NAME}"
  assert_success
  assert_output ""

  run echo "${DEPLOY_VERSION}"
  assert_success
  assert_output ""
}

@test "sets environment variables for multiple mappings" {
  # Set up plugin environment
  export BUILDKITE_PLUGIN_META_ENV_META_DATA_0="TARGET_ENVIRONMENT"
  export BUILDKITE_PLUGIN_META_ENV_META_DATA_1="LAMBDA_NAME"
  export BUILDKITE_PLUGIN_META_ENV_META_DATA_2="DEPLOY_VERSION"

  # Stub buildkite-agent behavior
  stub buildkite-agent "meta-data get TARGET_ENVIRONMENT : echo staging" \
                       "meta-data get LAMBDA_NAME : echo my-fn"          \
                       "meta-data get DEPLOY_VERSION : echo 1.0.0"

  # run the plugin hook
  run $PWD/hooks/post-checkout
  assert_success
  assert_output --partial "Propagating meta-data TARGET_ENVIRONMENT to env var"
  assert_output --partial "Propagating meta-data LAMBDA_NAME to env var"
  assert_output --partial "Propagating meta-data DEPLOY_VERSION to env var"

  # simulate execution of 'source .meta-env' as part of step's command
  source .meta-env

  # validate environment vars set up for specified meta-data
  run echo "${TARGET_ENVIRONMENT}"
  assert_success
  assert_output "staging"

  run echo "${LAMBDA_NAME}"
  assert_success
  assert_output "my-fn"

  run echo "${DEPLOY_VERSION}"
  assert_success
  assert_output "1.0.0"
}

@test "fails if collision between meta-data and environment variable" {
  # Set up plugin environment
  export LAMBDA_NAME="your-fn"
  export BUILDKITE_PLUGIN_META_ENV_META_DATA_0="TARGET_ENVIRONMENT"
  export BUILDKITE_PLUGIN_META_ENV_META_DATA_1="LAMBDA_NAME"
  export BUILDKITE_PLUGIN_META_ENV_META_DATA_2="DEPLOY_VERSION"

  # Stub buildkite-agent behavior
  stub buildkite-agent "meta-data get TARGET_ENVIRONMENT : echo staging" \
                       "meta-data get LAMBDA_NAME : echo my-fn"          \
                       "meta-data get DEPLOY_VERSION : echo 1.0.0"

  # run the plugin hook
  run $PWD/hooks/post-checkout
  assert_failure
  assert_output --partial "ERROR: LAMBDA_NAME environment variable already set"

  run cat .meta-env
  assert_success
  assert_output ""
}

@test "fails if no value found for configured meta-data" {
  # Set up plugin environment
  export BUILDKITE_PLUGIN_META_ENV_META_DATA_0="TARGET_ENVIRONMENT"
  export BUILDKITE_PLUGIN_META_ENV_META_DATA_1="LAMBDA_NAME"
  export BUILDKITE_PLUGIN_META_ENV_META_DATA_2="DEPLOY_VERSION"

  # Stub buildkite-agent behavior
  stub buildkite-agent "meta-data get TARGET_ENVIRONMENT : echo staging" \
                       "meta-data get LAMBDA_NAME : echo ''"             \
                       "meta-data get DEPLOY_VERSION : echo 1.0.0"

  # run the plugin hook
  run $PWD/hooks/post-checkout
  assert_failure
  assert_output --partial "ERROR: no meta-data found for LAMBDA_NAME"

  run cat .meta-env
  assert_success
  assert_output ""
}
