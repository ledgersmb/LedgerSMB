
# Building the Javascript code

In order to build the Javascript code in this directory
into usable JS assets for the web application, please make
sure `make` and `npm` are installed on your development machine.

Then, run:

```bash
 make dojo
```

This will automatically install the dependencies in the
`./node_modules/` directory in working directory root. It will
also transpile the javascript code into files in `./UI/js/`
from where they can be used.
