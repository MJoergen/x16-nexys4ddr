# Top-level directory for source files #

This directory contains the VHDL source code for this project. The source code
is divided into two separate directories: One directory "vera" contains my
implementation of the VERA chip, and the other directory "main" contains
everything else.

The reason for this division is because the VERA chip has a considerable amount
of complexity, including multiple clock domains, and I prefer the
"divide-and-conquer" approach to manage the complexity of the project.

