#!/bin/bash -l

cd /app

rake unstreamed > /dev/console 2>&1 &
rake uncompleted > /dev/console 2>&1 &
rake unuploaded > /dev/console 2>&1 &
