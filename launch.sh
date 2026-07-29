#!/bin/bash
set -e


echo "================================="
echo " Salad AI Container"
echo "================================="


bash ./setup.sh


bash ./start-vnc.sh


echo ""
echo "================================="
echo " LISTO"
echo "================================="


tail -f /dev/null