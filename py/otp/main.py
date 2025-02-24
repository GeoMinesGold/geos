#!/usr/bin/env python

import sys
import pyotp
import urllib.parse

def parse_otpauth_url(otpauth_url):
    parsed_url = urllib.parse.urlparse(otpauth_url)
    query_params = urllib.parse.parse_qs(parsed_url.query)
    issuer = parsed_url.netloc.split(':')[0]
    secret = query_params['secret'][0]
    return issuer, secret

def generate_totp(secret):
    totp = pyotp.TOTP(secret)
    return totp.now()

if __name__ == "__main__":
    if len(sys.argv) == 2:
        otpauth_url = sys.argv[1]
    else:
        otpauth_url = input("Enter otpauth URL: ").strip()

    issuer, secret = parse_otpauth_url(otpauth_url)

    # Generate and print TOTP
    otp_code = generate_totp(secret)
    print(f"OTP: {otp_code}")
