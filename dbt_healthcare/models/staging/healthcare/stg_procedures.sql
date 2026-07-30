with source as (
    select * from {{ source('raw_healthcare', 'procedures') }}
),

renamed as (
    select
        trim(procedure_id)                                 as procedure_id,
        trim(encounter_id)                                  as encounter_id,
        trim(procedure_code)                                as procedure_code,
        trim(procedure_description)                         as procedure_description,
        try_to_date(trim(procedure_date), 'DD-MM-YYYY')      as procedure_date,
        trim(provider_id)                                   as provider_id,
        try_to_number(trim(procedure_cost), 18, 2)           as procedure_cost,
        _source_file,
        _loaded_at
    from source
    qualify row_number() over (
        partition by procedure_id
        order by _loaded_at desc
    ) = 1
)

select * from renamed
