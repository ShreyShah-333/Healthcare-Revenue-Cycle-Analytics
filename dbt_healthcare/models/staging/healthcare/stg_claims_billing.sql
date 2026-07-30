-- Note: the source dataset combines billing + claim + payment fields into a single
-- claims_and_billing.csv file (there is no separate payments table). This model is
-- therefore the single source of truth for claim/billing grain; a dedicated
-- int_claim_payment_summary model will be built from this in the intermediate layer.
with source as (
    select * from {{ source('raw_healthcare', 'claims_and_billing') }}
),

renamed as (
    select
        trim(billing_id)                                        as billing_id,
        trim(patient_id)                                        as patient_id,
        trim(encounter_id)                                      as encounter_id,
        upper(trim(insurance_provider))                         as payer_name,
        upper(trim(payment_method))                             as payment_method,
        trim(claim_id)                                          as claim_id,
        try_to_date(trim(claim_billing_date), 'DD-MM-YYYY')      as claim_billing_date,
        try_to_number(trim(billed_amount), 18, 2)                as billed_amount,
        try_to_number(trim(paid_amount), 18, 2)                  as paid_amount,
        upper(trim(claim_status))                               as claim_status,
        trim(denial_reason)                                     as denial_reason,
        _source_file,
        _loaded_at
    from source
    qualify row_number() over (
        partition by billing_id
        order by _loaded_at desc
    ) = 1
)

select * from renamed
