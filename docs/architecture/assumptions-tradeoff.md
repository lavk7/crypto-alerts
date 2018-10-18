# Assumptions
- The ingestion is executed manually over completed data present at the source
- Assumed to be one time operation
- The data will be small and the analysis scripts will not be complex


# Tradeoffs
- Redshift : Achieve greater performance by giving up fault tolerance, zero downtime and automated scalabilty
- Redshift : Achieve greater performance for more cost
- Data Ingestion Module: Achieve high availability and cost cutting by giving up reliabilty ( Lambda )
- Data Analysis: Achieve scalability and reduced cost by giving up Reliabilty ( Lambda )


