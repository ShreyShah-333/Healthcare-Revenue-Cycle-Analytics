with source as (
    select * from {{ source('raw_healthcare', 'providers') }}
),

renamed as (
    select
        trim(provider_id)                          as provider_id,
        trim(name)                                  as provider_name,
        trim(department)                            as department,
        trim(specialty)                              as specialty,
        trim(npi)                                    as npi,
        try_to_boolean(trim(inhouse))                as is_inhouse,
        upper(trim(location))                        as location_state,
        try_to_number(trim(years_experience))        as years_experience,
        trim(contact_info)                           as contact_info,
        lower(trim(email))                           as email,
        _source_file,
        _loaded_at
    from source
    qualify row_number() over (
        partition by provider_id
        order by _loaded_at desc
    ) = 1
)

select * from renamed
