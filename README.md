# Release Monitor

This project uses the unauthenticated GitHub APIs to monitor a provided account/repo for a release containing a provided commit.  It is meant to be run as an AWS lambda on a cron, and send an email notification when a release with the provided commit is detected.

## Quickstart
1. Create a lambda in your AWS account.
1. Auth to AWS via environment variables.
1. Run the following:
```bash
make
docker run --rm -it --env-file <(env | grep AWS_) -v $(pwd):/usr/src/app/ -v ${HOME}/.aws:/root/.aws seiso/easy_infra aws lambda update-function-code --function-name release_monitor --zip-file fileb:///usr/src/app/function.zip
```

