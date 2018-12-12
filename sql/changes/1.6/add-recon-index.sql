

CREATE INDEX acc_trans_recon_idx ON acc_trans (chart_id, entry_id)
    WHERE not cleared;

COMMENT ON INDEX acc_trans_recon_idx IS
$$This index serves to optimize finding the minimum entry_id
of uncleared journal lines for a given account.$$;
