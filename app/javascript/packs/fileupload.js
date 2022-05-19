const axios = require('axios')

async function getSignedUrl(filename) {
  let response = await axios.get('/minio/signed_url.json?filename=' + filename);
  return response.data.signedUrl;
}

async function upload(file, signedUrl, formIndex) {

  $('.upload-progress-' + formIndex).show('slow');

  await axios.put(signedUrl, file, {
    headers: {
      'Content-Type': file.type
    },
    onUploadProgress: (e) => {
      let percentCompleted = Math.round((e.loaded * 100) / e.total);
      $('.upload-progress-bar-' + formIndex)
        .attr('aria-valuenow', percentCompleted)
        .css('width', percentCompleted + '%');
    },
  });
}

async function handleFileChange(e) {
  try {
    // Get upload URL
    const file = e.target.files[0];
    // There might be multiple forms on the page
    const formIndex = e.target.dataset.index;
    const signedUrl = await getSignedUrl(file.name);
    const fileUrl = signedUrl.split('?')[0];

    // Upload the file
    await upload(file, signedUrl, formIndex);

    $('.image-preview-' + formIndex).attr('src', fileUrl);
    $('.image-preview-wrapper-' + formIndex).show('slow');

    // Put the url of the uploaded file into the url input make it readonly
    $(e.target).closest('.nested-medium-form').find('.media-content-url')
      .val(fileUrl)
      .attr('readonly', true);
  } catch (e) {
    console.log(e);
  }
}

// Saving this globally, because we need to rebind events
// when a new nested form is added
window.bindFileUploadEvents = () => {
  $('.upload-toggle').off().on('click', (e) => {
    const formIndex = e.target.dataset.index;
    $('.file-input-' + formIndex).click();
  });
  $('.file-input').off().on('change', handleFileChange);
}

$(() => {
  window.bindFileUploadEvents();
});
