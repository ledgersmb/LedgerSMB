ALTER FUNCTION batch_post(int) SECURITY DEFINER;
REVOKE EXECUTE ON FUNCTION batch_post(int) FROM public;
\echo you will need to GRANT execute on function batch_post to lsmb_[dbname]__batch_post
