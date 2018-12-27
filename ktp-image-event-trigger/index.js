
//Start of Image Text Extractor
const vision = require('@google-cloud/vision');
const { PubSub } = require(`@google-cloud/pubsub`);

const client = new vision.ImageAnnotatorClient();
const pubsub = new PubSub();

exports.processImageFromGCSEvent = (event, callback) => {
  const file = event.data;
  const topicName = 'ektp-text-extracted';

  console.log('event info: ', event)
  if (file.resourceState === 'not_exists') {
    console.log(`File ${file.name} deleted.`);
    callback();
  } else if (file.metageneration === '1') {
    console.log(`File ${file.name} uploaded.`);
    const gcsPath = `gs://${file.bucket}/${file.name}`

    var fileNameArr =  file.name.split("/");  //{user_id}/{operation_id}.*
    var fileName = fileNameArr[fileNameArr.length - 1];
    var operationId = fileName.split(".")[0];

    client
      .textDetection(gcsPath)
      .then(results => {
        const detections = results[0].textAnnotations;
        const data = JSON.stringify({
          event_type: 'text.recognized',
          data: {
            results: results[0].textAnnotations,
            image_path: gcsPath,
            operation_id: operationId
          }
        });
        console.log(data)
        const dataBuffer = Buffer.from(data);
        return pubsub
        .topic(topicName)
        .publisher()
        .publish(dataBuffer)
      })
      .then(messageId => {
        console.log("message published")
        callback(null, `Message ${messageId} published.`);
      })
      .catch(err => {
        console.log(err)
        callback(err);
      });
  } else {
    console.log(`File ${file.name} metadata updated.`);
    callback();
  }
};
