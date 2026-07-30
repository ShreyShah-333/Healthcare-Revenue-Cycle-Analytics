with source as (
    select * from {{ source('raw_healthcare', 'denials') }}
),

renamed as (
    select
        trim(claim_id)                                     as claim_id,
        trim(denial_id)                                    as denial_id,
        upper(trim(denial_reason_code))                    as denial_reason_code,
        trim(denial_reason_description)                    as denial_reason_description,
        try_to_number(trim(denied_amount), 18, 2)           as denied_amount,
        try_to_date(trim(denial_date), 'DD-MM-YYYY')        as denial_date,
        try_to_boolean(trim(appeal_filed))                  as is_appeal_filed,
        upper(trim(appeal_status))                          as appeal_status,
        try_to_date(trim(appeal_resolution_date), 'DD-MM-YYYY') as appeal_resolution_date,
        upper(trim(final_outcome))                          as final_outcome,
        _source_file,
        _loaded_at
    from source
    qualify row_number() over (
        partition by denial_id
        order by _loaded_at desc
    ) = 1
)

select * from renamed
