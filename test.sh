#!/bin/bash

shopt -s expand_aliases
cat > /home/dsavage/.bash_aliases <<EOF
alias se=sudoedit
EOF

source /home/dsavage/.bash_aliases
if [ $? = 0 ]; then
	/usr/bin/echo "Install was a success!"
fi

