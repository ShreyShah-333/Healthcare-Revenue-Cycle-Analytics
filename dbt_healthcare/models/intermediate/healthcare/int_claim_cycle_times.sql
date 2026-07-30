-- Intermediate model: int_claim_cycle_times
-- Grain: one row per claim_id
-- Purpose: elapsed time between clinical visit/discharge and claim billing

with claims as (
    select
        claim_id,
        billing_id,
        encounter_id,
        claim_billing_date
    from {{ ref('stg_claims_billing') }}
),

encounters as (
    select
        encounter_id,
        visit_date,
        discharge_date,
        length_of_stay_days
    from {{ ref('stg_encounters') }}
),

joined as (
    select
        c.claim_id,
        c.billing_id,
        c.encounter_id,
        e.visit_date,
        e.discharge_date,
        e.length_of_stay_days,
        c.claim_billing_date,
        datediff('day', e.visit_date, c.claim_billing_date) as days_visit_to_billing,
        datediff('day', e.discharge_date, c.claim_billing_date) as days_discharge_to_billing
    from claims c
    left join encounters e
        on c.encounter_id = e.encounter_id
)

select * from joined
