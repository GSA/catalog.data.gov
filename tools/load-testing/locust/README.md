# Catalog load testing tool

## Base test

Run basic tests just for basic CKAN URLs

```
locust --config base.conf -H http://catalog-next.data.gov --csv=results
```
### Sample results

```
 Name                                                          # reqs      # fails  |     Avg     Min     Max  Median  |   req/s failures/s
--------------------------------------------------------------------------------------------------------------------------------------------
 GET /                                                             41     0(0.00%)  |    3394     849   11247    2900  |    0.69    0.00
 GET /group                                                        37     3(8.11%)  |    1737     605    6094     930  |    0.62    0.05
 GET /harvest                                                      33     0(0.00%)  |    2252     662    7235    1300  |    0.55    0.00
 GET /organization                                                 36     1(2.78%)  |    2274     598    6929    1300  |    0.60    0.02
--------------------------------------------------------------------------------------------------------------------------------------------
 Aggregated                                                       147     4(2.72%)  |    2446     598   11247    1500  |    2.46    0.07

Response time percentiles (approximated)
 Type     Name                                                              50%    66%    75%    80%    90%    95%    98%    99%  99.9% 99.99%   100% # reqs
--------|------------------------------------------------------------|---------|------|------|------|------|------|------|------|------|------|------|------|
 GET      /                                                                2900   3300   4100   5500   6600   6900  11000  11000  11000  11000  11000     41
 GET      /group                                                            930   1300   1900   2500   4900   5900   6100   6100   6100   6100   6100     37
 GET      /harvest                                                         1300   1500   2400   4400   5600   7100   7200   7200   7200   7200   7200     33
 GET      /organization                                                    1400   1600   3200   4000   5900   6900   6900   6900   6900   6900   6900     36
--------|------------------------------------------------------------|---------|------|------|------|------|------|------|------|------|------|------|------|
 None     Aggregated                                                       1500   2500   3300   4400   5900   6900   7100   7200  11000  11000  11000    147

Error report
 # occurrences      Error                                                                                               
--------------------------------------------------------------------------------------------------------------------------------------------
 2                  GET /group: ConnectionError(ProtocolError('Connection aborted.', RemoteDisconnected('Remote end closed connection without response')))
 1                  GET /organization: ConnectionError(ProtocolError('Connection aborted.', RemoteDisconnected('Remote end closed connection without response')))
 1                  GET /group: HTTPError('502 Server Error: Proxy Error for url: https://catalog-next.data.gov/group') 
--------------------------------------------------------------------------------------------------------------------------------------------
```

## Run test from Apache logs

First get URLs from Apache logs file

```
python parse_apache_logs.py --apache_logs_path raw-apache.log
```

You will see the `results.txt` file with all the useful URLs to test.  
The run:  

```
locust --config from_apache.conf -H http://catalog-next.data.gov --csv=results
```

This will iterate over all URLs and write several CSV file with stats and failures details.  

