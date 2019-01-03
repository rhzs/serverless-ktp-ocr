const path = require('path');
const os = require('os');
const fs = require('fs');

const Busboy = require('busboy');
const { Storage } = require('@google-cloud/storage');
const storage = new Storage();
const uuidv1 = require('uuid/v1');

exports.uploadKtp = (req, res) => {
  if (req.method === 'POST') {
    const busboy = new Busboy({ headers: req.headers });
    const tmpdir = os.tmpdir();
    const fields = {};
    const uploads = {};

    busboy.on('field', (fieldname, val) => {
      fields[fieldname] = val;
    });

    busboy.on('file', (fieldname, file, filename) => {
      if (fieldname === 'image') {
        console.log(`Processed file ${filename}`);
        const filepath = path.join(tmpdir, filename);
        uploads[fieldname] = filepath;
        file.pipe(fs.createWriteStream(filepath));
      }
    });

    busboy.on('error', (error) => {
      console.log(error)
    })

    busboy.on('finish', () => {

      const userId = fields["user_id"];
      const imageId = uuidv1();

      if (userId === undefined) {
        res.status(400);
        res.send({error: 'user_id is not provided'});
        console.log(new Error('user_id is not provided'))
      }

      // for (const name in uploads) {
      const file = uploads["image"];
      if (file === undefined) {
        res.status(400);
        res.send({error: 'image is not provided'});
        console.log(new Error('image is not provided'))
      }

      var fileExtensionArr = file.split(".");
      var fileExtension = fileExtensionArr[fileExtensionArr.length-1];

      const destination = `${userId}/${imageId}.${fileExtension}`;
      const options = {
        destination: destination
      };
      //uploading to cloud storage
      const bucketName = "uploaded_ektp"
      storage
      .bucket(bucketName)
      .upload(file, options)
      .then(() => {
        console.log(`${file} uploaded to gs://${bucketName}/${destination}`);
        fs.unlinkSync(file);
        const data = {
          operation_id: imageId,
          path: `gs://${bucketName}/${destination}`
        };
        res.send(data);
      })
      .catch(err => {
        console.error('ERROR:', err);
        res.status(500).send(err)
      });
    });

    busboy.end(req.rawBody)
    req.pipe(busboy);
  } else {
    res.status(405).end();
  }
};
