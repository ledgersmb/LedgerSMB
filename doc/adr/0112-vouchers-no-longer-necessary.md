# 0112 Vouchers are no longer necessary

Date: 2026-08-08

## Status

Draft

## Summary

Vouchers and batches offer the same solution: vouchers can be removed
without removing functionality from the application.

## Context

Vouchers link `acc_trans` lines or `transactions` to batches. This made
sense at the time invoice and payment lines were combined in a single
`ar` transaction: by linking the journal lines, payments (batches) could be
approved separate from the invoice. At the same time, vouchers were
problematic, as they performed the function of identifying payment lines on
invoices from batch payments where the same function was performed by
`payment_links` for single payments.

As payments are now first-order transactions - i.e. no longer lumped into
`ar`/`ap` transactions - they can be approved on a transaction basis:
vouchers are no longer required to identify transaction journal sub-groups.

## Decision

1. Batches will be groups of transactions
2. Vouchers lost their function of grouping journal lines

## Consequences

1. Transactions will carry a new `batch_id` field which references the
   `batch.id` of the batch they belong to -- or be null if the transaction
   does not belong to a batch
2. Vouchers will be decommissioned as soon as payments have migrated to be
   first-order transactions

## Annotations

See [ADR 0111](./0111-payment-overpayment-terminology.md) for context on
payment and overpayment changes.
