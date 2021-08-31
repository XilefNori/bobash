lib = ./source
clear = sed "s~^\#include~include~"

Dockerfile.php: $(lib)/Dockerfile.php.in $(lib)/*.docker
	$(clear) $(lib)/Dockerfile.php.in | m4 -I $(lib) > Dockerfile.php

Dockerfile.bash: $(lib)/Dockerfile.bash.in $(lib)/*.docker
	$(clear) $(lib)/Dockerfile.bash.in | m4 -I $(lib) > Dockerfile.bash

