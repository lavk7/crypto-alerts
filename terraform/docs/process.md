# Architecture Design Process
## Design plan:
- Gather the requirements of the system
    - Crypto alert system
    - Alert user when the fluctuation >=0.5% 
- Analyze the desired system characterstics
    - Low latency
    - Highly available
    - Scalable
- Note down the modules
    - Data Ingestion : Responsible for ingesting the data, can be from MULTIPLE resources
    - Data Analysis  : Responsible for comparing the data, should be scalable
    - Notificatin module : Receive alert from Data Analysis module and send it to multiple consumers 
