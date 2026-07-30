-- Intermediate model: int_payer_performance
-- Grain: one row per payer_name
-- Purpose: claim volume, payment and denial performance rolled up by payer.
-- Note: the source dataset has no separate payers dimension table, so
--       payer_name from stg_claims_billing is used directly as the payer key.

with financials as (
    select
        payer_name,
        claim_id,
        billed_amount,
        paid_amount,
        outstanding_amount,
        payment_rate,
        is_denied,
        days_visit_to_billing
    from {{ ref('int_claim_financials') }}
),

agg as (
    select
        payer_name,
        count(distinct claim_id) as claim_count,
        sum(billed_amount) as total_billed,
        sum(paid_amount) as total_paid,
        sum(outstanding_amount) as total_outstanding,
        avg(payment_rate) as avg_payment_rate,
        sum(case when is_denied then 1 else 0 end) as denied_claim_count,
        avg(days_visit_to_billing) as avg_days_visit_to_billing
    from financials
    group by payer_name
)

select
    payer_name,
    claim_count,
    total_billed,
    total_paid,
    total_outstanding,
    round(avg_payment_rate, 4) as avg_payment_rate,
    denied_claim_count,
    case
        when claim_count = 0 then null
        else round(denied_claim_count / claim_count, 4)
    end as denial_rate,
    round(avg_days_visit_to_billing, 2) as avg_days_visit_to_billing
from agg
