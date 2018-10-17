#!/bin/sh

docker exec -it crypto-alert /bin/sh -c "cd data; terraform destroy -auto-approve"