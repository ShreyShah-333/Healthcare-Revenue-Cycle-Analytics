-- Intermediate model: int_ar_ageing
-- Grain: one row per claim_id where outstanding_amount > 0
-- Purpose: accounts-receivable ageing buckets for unpaid/partially paid claims.
-- Note: this is a static historical dataset (Q1 2025), so ageing is measured
--       relative to the dataset's own latest claim_billing_date rather than
--       the wall-clock current_date, which would otherwise produce meaningless
--       multi-year ageing figures.

with financials as (
    select
        claim_id,
        billing_id,
        patient_id,
        payer_name,
        claim_status,
        billed_amount,
        paid_amount,
        outstanding_amount,
        claim_billing_date
    from {{ ref('int_claim_financials') }}
    where outstanding_amount > 0
),

as_of as (
    select max(claim_billing_date) as as_of_date
    from {{ ref('stg_claims_billing') }}
),

aged as (
    select
        f.*,
        a.as_of_date,
        datediff('day', f.claim_billing_date, a.as_of_date) as days_outstanding
    from financials f
    cross join as_of a
),

bucketed as (
    select
        *,
        case
            when days_outstanding <= 30 then '0-30'
            when days_outstanding <= 60 then '31-60'
            when days_outstanding <= 90 then '61-90'
            else '90+'
        end as ageing_bucket
    from aged
)

select * from bucketed
-- Intermediate model: int_ar_ageing
-- Grain: one row per claim_id where outstanding_amount > 0
-- Purpose: accounts-receivable ageing buckets for unpaid/partially paid claims.
-- Note: this is a static historical dataset (Q1 2025), so ageing is measured
--       relative to the dataset's own latest claim_billing_date rather than
--       the wall-clock current_date, which would otherwise produce meaningless
--       multi-year ageing figures.

with financials as (
    select
        claim_id,
        billing_id,
        patient_id,
        payer_name,
        claim_status,
        billed_amount,
        paid_amount,
        outstanding_amount,
        claim_billing_date
    from {{ ref('int_claim_financials') }}
    where outstanding_amount > 0
),

as_of as (
    select max(claim_billing_date) as as_of_date
    from {{ ref('stg_claims_billing') }}
),

aged as (
    select
        f.*,
        a.as_of_date,
        datediff('day', f.claim_billing_date, a.as_of_date) as days_outstanding
    from financials f
    cross join as_of a
),

bucketed as (
    select
        *,
        case
            when days_outstanding <= 30 then '0-30'
            when days_outstanding <= 60 then '31-60'
            when days_outstanding <= 90 then '61-90'
            else '90+'
        end as ageing_bucket
    from aged
)

select * from bucketed
