-- SC: Replaces the primary key of the tax table with a check for if the
--     combination of chart_id and validto is unique.  An index is added to
--     check for the case of multiple NULL validto values and fail if that would
--     result.

ALTER TABLE tax DROP CONSTRAINT tax_pkey;
ALTER TABLE tax ADD CONSTRAINT tax_unique UNIQUE (chart_id, validto);
COMMENT ON CONSTRAINT tax_unique ON tax IS
$$Checks on the base uniqueness of the chart_id, validto combination$$;

CREATE UNIQUE INDEX tax_null_validto_unique_idx ON tax(chart_id) WHERE validto IS NULL;
COMMENT ON INDEX tax_null_validto_unique_idx IS
$$Part of primary key emulation for the tax table, ensures at most one NULL validto for each chart_id$$;
