#!/usr/bin/env python3
"""
Search GitHub to see if a given commit is in a release
"""

from argparse import ArgumentParser
from typing import Dict
import json
import logging
import requests
import sys



def lambda_handler(event, context):
    """
    AWS Lambda handler
    """
    # print(event)
    try:
        logging.info("Trying API gateway")
        status = check_for_commit(
            account=event["queryStringParameters"]["account"],
            commitish=event["queryStringParameters"]["commit"],
            repository=event["queryStringParameters"]["repository"],
        )
        logging.warn("API gateway method failed")
    except:
        logging.info("Trying json input")
        status = check_for_commit(
            account=event["account"],
            commitish=event["commit"],
            repository=event["repository"],
        )
    logging.info("json method succeeded")
    response_code = 200
    body = json.dumps({'status': status})
    response = {'statusCode': response_code, 'body': body}
    return response


def main():
    """
    Retrieve the arguments and check for the provided commit in the latest release
    """
    config = get_args_config()

    check_for_commit(
        account=config["account"],
        repository=config["repository"],
        commitish=config["commit"],
    )


def check_for_commit(*, account: str, repository: str, commitish: str) -> bool:
    """
    Check a provided account/repo for a commitish
    """
    url = (
        "https://api.github.com/repos/"
        + account
        + "/"
        + repository
        + "/releases/latest"
    )
    headers = {"Accept": "application/vnd.github.v3+json"}

    response = requests.get(url, headers=headers)
    latest_release_json = response.json()
    try:
        latest_release_sha = latest_release_json["target_commitish"]
    except KeyError:
        print(
            "Unable to identify the latest release commitish, are you being rate limited?"
        )
        sys.exit(1)

    url = (
        "https://api.github.com/repos/"
        + account
        + "/"
        + repository
        + "/compare/"
        + commitish
        + "..."
        + latest_release_sha
    )

    response = requests.get(url, headers=headers)
    github_status_json = response.json()
    try:
        github_status = github_status_json["status"]
    except KeyError:
        print("Unable to identify the comparison status, are you being rate limited?")
        sys.exit(1)

    if github_status in ("ahead", "identical"):
        print("YES!  Go update")
        return True

    print("not yet ;(")
    return False


def get_args_config() -> Dict:
    """
    Get the configs passed as arguments
    """
    parser = create_arg_parser()
    return vars(parser.parse_args())


def create_arg_parser() -> ArgumentParser:
    """Parse the arguments"""
    parser = ArgumentParser()
    parser.add_argument(
        "--account", type=str, required=True, help="github account",
    )
    parser.add_argument(
        "--repository", type=str, required=True, help="github repository",
    )
    parser.add_argument(
        "--commit", type=str, required=True, help="commitish to monitor for",
    )
    return parser


if __name__ == "__main__":
    main()
