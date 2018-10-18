# Errs

- Wrong assumptions
    - I assumed kinesis firehose support incoming record transformation one to many. 
    - Actually, it is one to one. One recordId can only transform to one record output.

