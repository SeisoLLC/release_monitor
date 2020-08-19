#!/usr/bin/env python3
"""
Client for interacting with the release monitor's API gateway trigger
"""
# pylint: disable=line-too-long

import os
from typing import Dict
from argparse import ArgumentParser
from urllib.parse import urlencode
import requests
from aws_requests_auth.boto_utils import BotoAWSRequestsAuth


def main():
    """Do the thing"""
    config = get_args_config()

    account = config["account"]
    commit = config["commit"]
    repository = config["repository"]
    method = config["method"]
    rest_api_id = config["rest_api_id"]

    uri = "/default/release_monitor"
    querystring = {
        "account": account,  # pylint: disable=undefined-variable
        "commit": commit,  # pylint: disable=undefined-variable
        "repository": repository,  # pylint: disable=undefined-variable
    }
    querystring_encoded = urlencode(sorted(querystring.items()))

    region = "us-east-1"
    host = rest_api_id + ".execute-api." + region + ".amazonaws.com"
    url = "https://" + host + uri + "?" + querystring_encoded
    service = "execute-api"

    # Uses boto logic for auth
    auth = BotoAWSRequestsAuth(
        aws_host=rest_api_id + ".execute-api." + region + ".amazonaws.com",
        aws_region=region,
        aws_service=service,
    )

    response = getattr(requests, method.lower())(url, auth=auth)
    print("Request sent.  Hope it worked :shrug:")


def get_args_config() -> Dict:
    """
    Get the configs passed as arguments
    """
    parser = create_arg_parser()
    config = vars(parser.parse_args())
    return config


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
    parser.add_argument(
        "--rest-api-id", type=str, required=True, help="The AWS API Gateway REST API ID"
    )
    parser.add_argument(
        "--method", type=str.upper, default="GET", help="HTTP method to use",
    )
    return parser


if __name__ == "__main__":
    main()
