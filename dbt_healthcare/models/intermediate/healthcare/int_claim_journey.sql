-- Intermediate model: int_claim_journey
-- Grain: one row per encounter_id
-- Purpose: narrative view of a patient encounter — primary diagnosis,
--          procedures performed, and the resulting claim outcome

with encounters as (
    select
        encounter_id,
        patient_id,
        provider_id,
        visit_date,
        visit_type,
        department,
        reason_for_visit,
        primary_diagnosis_code,
        admission_type,
        discharge_date,
        length_of_stay_days,
        encounter_status,
        is_readmitted
    from {{ ref('stg_encounters') }}
),

primary_diagnosis as (
    select
        encounter_id,
        diagnosis_code,
        diagnosis_description
    from {{ ref('stg_diagnoses') }}
    where is_primary_diagnosis
    qualify row_number() over (partition by encounter_id order by diagnosis_id) = 1
),

procedure_agg as (
    select
        encounter_id,
        count(*) as procedure_count,
        sum(procedure_cost) as total_procedure_cost
    from {{ ref('stg_procedures') }}
    group by encounter_id
),

claims as (
    select
        encounter_id,
        claim_id,
        claim_status,
        billed_amount,
        paid_amount
    from {{ ref('stg_claims_billing') }}
),

joined as (
    select
        e.encounter_id,
        e.patient_id,
        e.provider_id,
        e.visit_date,
        e.visit_type,
        e.department,
        e.reason_for_visit,
        e.admission_type,
        e.discharge_date,
        e.length_of_stay_days,
        e.encounter_status,
        e.is_readmitted,
        coalesce(pd.diagnosis_code, e.primary_diagnosis_code) as primary_diagnosis_code,
        pd.diagnosis_description as primary_diagnosis_description,
        coalesce(pr.procedure_count, 0) as procedure_count,
        coalesce(pr.total_procedure_cost, 0) as total_procedure_cost,
        cl.claim_id,
        cl.claim_status,
        cl.billed_amount,
        cl.paid_amount
    from encounters e
    left join primary_diagnosis pd on e.encounter_id = pd.encounter_id
    left join procedure_agg pr on e.encounter_id = pr.encounter_id
    left join claims cl on e.encounter_id = cl.encounter_id
)

select * from joined
