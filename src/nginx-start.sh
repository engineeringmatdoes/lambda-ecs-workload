#!/bin/bash

echo "Validating Nginx configuration..."
/usr/sbin/nginx -t

echo "Starting Nginx..."
/usr/sbin/nginx -g 'daemon off;'
