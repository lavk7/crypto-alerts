import base64
import json
print('Loading function')


def lambda_handler(event, context):
    output = []

    for record in event['records']:
        payload = json.loads(base64.b64decode(record['data']))
        print (payload)
        # Do custom processing on the payload here

        output_record = {
            'recordId': record['recordId'],
            'result': 'Ok',
            'data': base64.b64encode((json.dumps(payload)+'\n').encode('utf8')).decode('utf8')
        }
        output.append(output_record)

    print('Successfully processed {} records.'.format(len(event['records'])))

    return {'records': output}
