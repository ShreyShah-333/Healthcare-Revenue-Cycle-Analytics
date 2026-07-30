-- Intermediate model: int_claim_payment_summary
-- Grain: one row per claim_id (billing_id)
-- Purpose: billed vs paid amounts and payment status per claim

with claims as (
    select
        claim_id,
        billing_id,
        patient_id,
        encounter_id,
        payer_name,
        payment_method,
        claim_billing_date,
        billed_amount,
        paid_amount,
        claim_status
    from {{ ref('stg_claims_billing') }}
),

calculated as (
    select
        *,
        coalesce(billed_amount, 0) - coalesce(paid_amount, 0) as outstanding_amount,
        case
            when billed_amount is null or billed_amount = 0 then null
            else round(paid_amount / billed_amount, 4)
        end as payment_rate,
        case
            when paid_amount is null or paid_amount = 0 then 'unpaid'
            when paid_amount >= billed_amount then 'fully_paid'
            else 'partially_paid'
        end as payment_bucket
    from claims
)

select * from calculated
