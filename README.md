## Serverless Indonesia KTP OCR with GCP

This is reproducible work from [Ekstraksi Informasi e-KTP dengan Google Cloud Function dan Cloud Vision API](https://medium.com/@imrenagi/ekstraksi-informasi-e-ktp-dengan-google-cloud-function-dan-cloud-vision-api-4655db21d084). It also contains code fix to match with ES6 compliant module usages.

### Prerequisites

1. Google Cloud Account
2. `gcloud` CLI
3. New project
4. Enable Google Cloud Functions
5. Enable Google Cloud Storage, bucket name `uploaded_ktp`
6. Enable Google Cloud PubSub, topic name `ektp-text-extracted`
7. Enable Google Cloud Vision

### How to deploy

1. Deploy HTTP

```shell
$ cd http-ktp
$ npm i
$ gcloud functions deploy http-ktp --entry-point uploadKtp --trigger-http
```

2. Deploy KTP Image Event Trigger

```shell
$ cd ktp-iamge-event-trigger
$ npm i
$ gcloud functions deploy processImageFromGCSEvent --trigger-resource uploaded_ektp --trigger-event google.storage.object.finalize
```

3. Deploy Extraction Data

```shell
$ gcloud functions deploy extract_ktp --runtime python37 --trigger-topic ektp-text-extracted
```

### Results

View Stackdriver logs from `extract-ktp` function.
