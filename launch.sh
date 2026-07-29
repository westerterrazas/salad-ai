#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "================================="
echo " Salad AI Container"
echo "================================="


bash "$DIR/setup.sh"


bash "$DIR/start-vnc.sh"


echo ""
echo "================================="
echo " LISTO"
echo "================================="


tail -f /dev/null