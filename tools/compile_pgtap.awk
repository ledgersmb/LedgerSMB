# Prologue
BEGIN{
    file = ARGV[1];
    gsub("\.sql","",file);
    gsub("\./?","_",file);
    printf("CREATE OR REPLACE FUNCTION lsmb_pgtap.%s()\n",file);
    printf("RETURNS SETOF TEXT AS $$\nBEGIN\n");
}

# Skip plan/finish
/^SELECT plan\([0-9]+\);/     { next }
/^SELECT \* FROM finish\(\);/ { next }
/^(BEGIN|ROLLBACK);/          { next }

# Skip config settings
/client_encoding|client_min_messages|CREATE EXTENSION/ { next }

# Comment bugged statement
/col_default_is.+\(''.+''/    { printf("--%s",$0)}

# Convert for runtests
{
    sub("^SELECT","RETURN NEXT",$0);
    print
}

# Epilogue
END{
    printf("END;\n$$ LANGUAGE plpgsql;");
}
