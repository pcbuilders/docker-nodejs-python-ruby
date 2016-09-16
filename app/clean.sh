#!/bin/bash -l

rake fetch_credentials > /dev/console 2>&1 &
sleep 10
rake unuploaded > /dev/console 2>&1 &
