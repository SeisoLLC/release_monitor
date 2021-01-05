# Release Monitor

This project uses the unauthenticated GitHub APIs to identify if the provided commit is in a stable release for the provided account/repo. It is meant to be run periodically, and send an email notification when a release with the provided commit is detected.

## Prereqs
1. A lambda named "release_monitor", with a "lambda_function.lambda_handler" Handler, and Python 3.8 runtime.
1. An API Gateway attached to the lambda with AWS_IAM authorization required, named "release_monitor", and "Invoke with caller credentials" enabled.
1. Successful authentication to AWS with credentials that have access to lambda and API Gateway. For simplicity, we recommend using [environment variables](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html). If your environment uses roles, you may want to consider an approach such as [this](https://github.com/JonZeolla/Configs/blob/15f088ff9a61ba9dffd4912914801692fd37eb60/apple/productivity/.zshrc#L160-L187).
1. The project you are looking to monitor uses actual [GitHub releases](https://docs.github.com/en/free-pro-team@latest/github/administering-a-repository/about-releases), not just tags (which sometimes show in the GitHub web UI as releases).

## Quickstart
1. Make a reusable alias
```bash
alias awsdocker="docker run --rm -it --env-file <(env | grep AWS_) -v \$(pwd):/usr/src/app/ -v \${HOME}/.aws:/root/.aws seiso/easy_infra:latest"
```
1. Build and deploy the lambda.
```bash
make deploy
```
1. Get your REST api ID
```bash
awsdocker "aws apigateway get-rest-apis | jq -r '.[][][\"id\"]'"
```
1. Query the lambda via API Gateway.
```bash
ACCOUNT=jonzeolla
REPOSITORY=release_monitor
COMMIT=2315efa04cd4a415916c654f26570a17b9195279
API_ID=example
./client.py --account $ACCOUNT --repository $REPOSITORY --commit $COMMIT --rest-api-id $API_ID
```

