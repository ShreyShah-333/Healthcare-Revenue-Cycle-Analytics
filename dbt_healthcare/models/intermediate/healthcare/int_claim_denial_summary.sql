-- Intermediate model: int_claim_denial_summary
-- Grain: one row per claim_id
-- Purpose: attach denial and appeal details to each claim

with claims as (
    select
        claim_id,
        billing_id,
        patient_id,
        encounter_id,
        payer_name,
        billed_amount,
        claim_status,
        denial_reason as claim_denial_reason
    from {{ ref('stg_claims_billing') }}
),

denials as (
    select
        claim_id,
        denial_id,
        denial_reason_code,
        denial_reason_description,
        denied_amount,
        denial_date,
        is_appeal_filed,
        appeal_status,
        appeal_resolution_date,
        final_outcome
    from {{ ref('stg_denials') }}
),

joined as (
    select
        c.claim_id,
        c.billing_id,
        c.patient_id,
        c.encounter_id,
        c.payer_name,
        c.billed_amount,
        c.claim_status,
        c.claim_denial_reason,
        d.denial_id,
        d.denial_reason_code,
        d.denial_reason_description,
        d.denied_amount,
        d.denial_date,
        d.is_appeal_filed,
        d.appeal_status,
        d.appeal_resolution_date,
        d.final_outcome,
        case when d.denial_id is not null then true else false end as is_denied,
        case when d.appeal_resolution_date is not null then true else false end as has_appeal_resolution
    from claims c
    left join denials d
        on c.claim_id = d.claim_id
)

select * from joined
