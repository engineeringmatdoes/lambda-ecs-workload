#!/bin/bash

DATE_STRING=$(date +%Y-%m-%d-%H-%M-%S)

k6 run aws.js --out csv=test-results-${DATE_STRING}.csv

gzip test-results-${DATE_STRING}.csv

aws s3 cp test-results-${DATE_STRING}.csv.gz s3://${TEST_BUCKET_NAME}
