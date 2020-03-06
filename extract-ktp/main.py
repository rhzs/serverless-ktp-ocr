import re

def extract_ktp(data, context):
    """Background Cloud Function to be triggered by Pub/Sub.
    Args:
         data (dict): The dictionary with data specific to this type of event.
         context (google.cloud.functions.Context): The Cloud Functions event
         metadata.
    """
    import base64
    import json
    import urllib.parse
    import urllib.request

    if 'data' in data:
        strjson = base64.b64decode(data['data']).decode('utf-8')
        text = json.loads(strjson)
        text = text['data']['results'][0]['description']

        lines = text.split("\n")
        res = []
        for line in lines:
            line = re.sub('gol. darah|nik|kewarganegaraan|nama|status perkawinan|berlaku hingga|alamat|agama|tempat/tgl lahir|jenis kelamin|gol darah|rt/rw|kel|desa|kecamatan', '', line, flags=re.IGNORECASE)
            line = line.replace(":","").strip()
            if line != "":
                res.append(line)
                    
        p = {
            "province": res[0],
            "city": res[1],
            "id": res[2],
            "name": res[3],
            "birthdate": res[4],
        }

        print('Information extracted:{}'.format(p))
