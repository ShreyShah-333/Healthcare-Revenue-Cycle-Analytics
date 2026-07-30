-- Intermediate model: int_provider_performance
-- Grain: one row per provider_id
-- Purpose: encounter volume, readmission rate, and claim/denial performance
--          rolled up by attending provider. Procedures can be performed by a
--          different provider than the encounter's attending provider; this
--          model attributes performance to the attending (encounter) provider.

with providers as (
    select
        provider_id,
        provider_name,
        department,
        specialty,
        is_inhouse,
        location_state,
        years_experience
    from {{ ref('stg_providers') }}
),

encounters as (
    select
        provider_id,
        encounter_id,
        is_readmitted
    from {{ ref('stg_encounters') }}
),

encounter_agg as (
    select
        provider_id,
        count(*) as encounter_count,
        sum(case when is_readmitted then 1 else 0 end) as readmission_count
    from encounters
    group by provider_id
),

financials as (
    select
        e.provider_id,
        f.claim_id,
        f.billed_amount,
        f.paid_amount,
        f.outstanding_amount,
        f.is_denied
    from {{ ref('int_claim_financials') }} f
    inner join {{ ref('stg_encounters') }} e
        on f.encounter_id = e.encounter_id
),

financial_agg as (
    select
        provider_id,
        count(distinct claim_id) as claim_count,
        sum(billed_amount) as total_billed,
        sum(paid_amount) as total_paid,
        sum(outstanding_amount) as total_outstanding,
        sum(case when is_denied then 1 else 0 end) as denied_claim_count
    from financials
    group by provider_id
),

joined as (
    select
        p.provider_id,
        p.provider_name,
        p.department,
        p.specialty,
        p.is_inhouse,
        p.location_state,
        p.years_experience,
        coalesce(ea.encounter_count, 0) as encounter_count,
        coalesce(ea.readmission_count, 0) as readmission_count,
        case
            when coalesce(ea.encounter_count, 0) = 0 then null
            else round(ea.readmission_count / ea.encounter_count, 4)
        end as readmission_rate,
        coalesce(fa.claim_count, 0) as claim_count,
        coalesce(fa.total_billed, 0) as total_billed,
        coalesce(fa.total_paid, 0) as total_paid,
        coalesce(fa.total_outstanding, 0) as total_outstanding,
        coalesce(fa.denied_claim_count, 0) as denied_claim_count,
        case
            when coalesce(fa.claim_count, 0) = 0 then null
            else round(fa.denied_claim_count / fa.claim_count, 4)
        end as denial_rate
    from providers p
    left join encounter_agg ea on p.provider_id = ea.provider_id
    left join financial_agg fa on p.provider_id = fa.provider_id
)

select * from joined
