with source as (
    select * from {{ source('raw_healthcare', 'diagnoses') }}
),

renamed as (
    select
        trim(diagnosis_id)                     as diagnosis_id,
        trim(encounter_id)                      as encounter_id,
        upper(trim(diagnosis_code))             as diagnosis_code,
        trim(diagnosis_description)             as diagnosis_description,
        try_to_boolean(trim(primary_flag))      as is_primary_diagnosis,
        try_to_boolean(trim(chronic_flag))      as is_chronic,
        _source_file,
        _loaded_at
    from source
    qualify row_number() over (
        partition by diagnosis_id
        order by _loaded_at desc
    ) = 1
)

select * from renamed
