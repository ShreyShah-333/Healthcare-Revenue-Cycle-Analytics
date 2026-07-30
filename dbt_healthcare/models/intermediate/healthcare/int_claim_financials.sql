-- Intermediate model: int_claim_financials
-- Grain: one row per claim_id
-- Purpose: single wide claim-grain table combining payment, denial and cycle-time
--          facts. This is the primary building block for marts.

with payment as (
    select * from {{ ref('int_claim_payment_summary') }}
),

denial as (
    select
        claim_id,
        is_denied,
        denial_reason_code,
        denial_reason_description,
        denied_amount,
        denial_date,
        is_appeal_filed,
        appeal_status,
        appeal_resolution_date,
        final_outcome
    from {{ ref('int_claim_denial_summary') }}
),

cycle as (
    select
        claim_id,
        visit_date,
        discharge_date,
        claim_billing_date,
        days_visit_to_billing,
        days_discharge_to_billing
    from {{ ref('int_claim_cycle_times') }}
),

joined as (
    select
        p.claim_id,
        p.billing_id,
        p.patient_id,
        p.encounter_id,
        p.payer_name,
        p.payment_method,
        p.claim_status,
        p.billed_amount,
        p.paid_amount,
        p.outstanding_amount,
        p.payment_rate,
        p.payment_bucket,
        d.is_denied,
        d.denial_reason_code,
        d.denial_reason_description,
        d.denied_amount,
        d.denial_date,
        d.is_appeal_filed,
        d.appeal_status,
        d.appeal_resolution_date,
        d.final_outcome,
        c.visit_date,
        c.discharge_date,
        c.claim_billing_date,
        c.days_visit_to_billing,
        c.days_discharge_to_billing
    from payment p
    left join denial d on p.claim_id = d.claim_id
    left join cycle c on p.claim_id = c.claim_id
)

select * from joined
