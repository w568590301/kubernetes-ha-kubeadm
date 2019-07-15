#!/bin/sh

netstat -ntlp|grep 6443 || exit 1

