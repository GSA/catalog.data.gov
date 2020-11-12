import argparse
import os
import re
import time

# Regex (allow IPv6)
LOG_REGEX = r'(?P<ip>[(\d\.\w\:)]+) - - \[(?P<date>.*?) (.*?)\] "(?P<method>\w+) (?P<request_path>.*?) HTTP/(?P<http_version>.*?)" (?P<status_code>\d+) (?P<response_size>\d+) "(?P<referrer>.*?)" "(?P<user_agent>.*?)"'
compiled = re.compile(LOG_REGEX)

def parse_line(line):
    """ Analize one Apache log line
        to test line = 172.183.134.216 - - [12/Jul/2016:12:22:14 -0700] "GET /wp-content HTTP/1.0"       200 4980  "http://farmer-harris.com/category/index/" "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_8; rv:1.9.3.20) Gecko/2013-07-10 02:46:11 Firefox/9.0"
        Parsing          34.196.108.51 - - [20/Oct/2020:06:28:21 +0000] "GET /harvest/sba-json HTTP/1.1" 200 51458 "-"                                        "Amazon CloudFront"

        result {'ip': '172.183.134.216', 'date': '12/Jul/2016:12:22:14', 'method': 'GET', 'request_path': '/wp-content', 'http_version': '1.0', 'status_code': '200', 'response_size': '4980', 'referrer': 'http://farmer-harris.com/category/index/', 'user_agent': 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_8; rv:1.9.3.20) Gecko/2013-07-10 02:46:11 Firefox/9.0'}
        """
    match = compiled.match(line)
    if match is None:
        print('Not match for \n\t[{}]'.format(line))
        # sample 172.30.74.115 - - [20/Oct/2020:06:35:52 +0000] "OPTIONS / RTSP/1.0" 400 0 "-" "-"


        return None
    data = match.groupdict()
    return process_line(data)

def process_line(data):
    """ Analize a line to determine if we want it """

    if data['request_path'].startswith('/fanstatic'):
        print('SKIP {}'.format(data['request_path']))
        return None
    if data['method'] != 'GET':
        print('SKIP {} {}'.format(data['method'], data['request_path']))
        return None

    return data

# data = parse_line('172.183.134.216 - - [12/Jul/2016:12:22:14 -0700] "GET /wp-content HTTP/1.0" 200 4980 "http://farmer-harris.com/category/index/" "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_8; rv:1.9.3.20) Gecko/2013-07-10 02:46:11 Firefox/9.0"')
# print(data)

# data = parse_line('34.196.108.51 - - [20/Oct/2020:06:28:21 +0000] "GET /harvest/sba-json HTTP/1.1" 200 51458 "-" "Amazon CloudFront"')
# print(data)

def parse_file(apache_log_path, output_path='results.txt'):
    f = open(apache_log_path, 'r')
    out = open(output_path, 'w')

    for line in f:
        print('Parsing {}'.format(line))
        data = parse_line(line)
        if data is None:
            continue
        out.write(data['request_path'] + "\n")

    f.close()
    out.close()

parser = argparse.ArgumentParser()
parser.add_argument("--apache_logs_path", type=str, default="apache.log", help="Path for the apache log file")
parser.add_argument("--output_path", type=str, default="results.txt", help="Destination file for URLs")
args = parser.parse_args()

parse_file(args.apache_logs_path, output_path=args.output_path)