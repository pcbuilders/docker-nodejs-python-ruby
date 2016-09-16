#!/bin/bash -l

rake unstreamed > /dev/console 2>&1 &
rake uncompleted > /dev/console 2>&1 &
rake unuploaded > /dev/console 2>&1 &
rake fetch_credentials > /dev/console 2>&1 &
