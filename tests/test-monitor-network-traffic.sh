#!/bin/bash

sudo nc -lvp 22 &
LISTENER_PID=$!

sleep 2

nc 127.0.0.1 22

kill $LISTENER_PID
