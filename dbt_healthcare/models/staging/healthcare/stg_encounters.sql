with source as (
    select * from {{ source('raw_healthcare', 'encounters') }}
),

renamed as (
    select
        trim(encounter_id)                                  as encounter_id,
        trim(patient_id)                                     as patient_id,
        trim(provider_id)                                    as provider_id,
        try_to_date(trim(visit_date), 'DD-MM-YYYY')           as visit_date,
        upper(trim(visit_type))                               as visit_type,
        trim(department)                                     as department,
        trim(reason_for_visit)                               as reason_for_visit,
        trim(diagnosis_code)                                  as primary_diagnosis_code,
        upper(trim(admission_type))                           as admission_type,
        try_to_date(trim(discharge_date), 'DD-MM-YYYY')       as discharge_date,
        try_to_number(trim(length_of_stay))                   as length_of_stay_days,
        upper(trim(status))                                   as encounter_status,
        try_to_boolean(trim(readmitted_flag))                 as is_readmitted,
        _source_file,
        _loaded_at
    from source
    qualify row_number() over (
        partition by encounter_id
        order by _loaded_at desc
    ) = 1
)

select * from renamed
