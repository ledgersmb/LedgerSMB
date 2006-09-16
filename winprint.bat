IF X%1==X GOTO printdefault
GOTO printname
:printname
gsprint -name %1 - > NUL
GOTO end
:printdefault
gspring -noprinter - > NUL 
:end
