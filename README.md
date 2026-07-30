# Healthcare Revenue Cycle & Claims Analytics Platform

## The problem
Where are operational and financial bottlenecks occurring across the hospital revenue cycle, why are they occurring, and how much revenue is delayed or lost as a result?

This project builds an end-to-end analytics engineering platform that ingests synthetic patient, encounter, claims, billing and denial data into Snowflake, transforms it through a dbt staging -> intermediate -> marts pipeline, and surfaces revenue-cycle bottlenecks, denial root causes and payer performance through Power BI.

## Stack
- **Source data:** California Hospital Q1 2025 synthetic dataset (Kaggle, CC0)
- - **Warehouse:** Snowflake
  - - **Transformation:** dbt (staging / intermediate / marts)
    - - **Ingestion:** Python (snowflake-connector-python)
      - - **BI:** Power BI
       
        - ## Architecture
        - ```
          Kaggle CSVs -> Python ingestion (PUT/COPY INTO) -> Snowflake RAW_HEALTHCARE
                      -> dbt staging -> dbt intermediate -> dbt marts (star schema)
                      -> Power BI semantic model -> executive dashboards
          ```

          ## Repository structure
          See `architecture/` for diagrams and `docs/` for the KPI glossary, current vs future state analysis, and insights log.

          ## Status
          - [x] Week 1-3: Snowflake setup, Python ingestion, dbt staging layer
          - [ ] - [ ] Week 4: dbt intermediate claim journey models
          - [ ] - [ ] Week 5: Dimensional marts (facts/dimensions)
          - [ ] - [ ] Week 6: Power BI semantic model
          - [ ] - [ ] Week 7: QA, testing, documentation
          - [ ] - [ ] Week 8: Executive insights & final writeup
         
          - [ ] ## Data note
          - [ ] This dataset is fully synthetic (CC0: Public Domain) and contains no real patient information (PHI). It is used strictly for portfolio/demonstration purposes.
          - [ ] 
