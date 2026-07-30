with source as (
    select * from {{ source('raw_healthcare', 'patients') }}
),

renamed as (
    select
        trim(patient_id)                                as patient_id,
        trim(first_name)                                 as first_name,
        trim(last_name)                                  as last_name,
        try_to_date(trim(dob), 'DD-MM-YYYY')              as date_of_birth,
        try_to_number(trim(age))                          as age,
        upper(trim(gender))                               as gender,
        upper(trim(ethnicity))                            as ethnicity,
        upper(trim(insurance_type))                       as insurance_type,
        upper(trim(marital_status))                       as marital_status,
        trim(address)                                     as address,
        trim(city)                                        as city,
        upper(trim(state))                                as state,
        trim(zip)                                         as zip_code,
        trim(phone)                                       as phone,
        lower(trim(email))                                as email,
        try_to_date(trim(registration_date), 'DD-MM-YYYY') as registration_date,
        _source_file,
        _loaded_at
    from source
    qualify row_number() over (
        partition by patient_id
        order by _loaded_at desc
    ) = 1
)

select * from renamed
