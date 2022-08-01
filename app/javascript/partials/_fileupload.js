const axios = require('axios');

async function getSignedUrl(filename) {
  const response = await axios.get('/minio/signed_url.json?filename=' + filename);

  return response.data.signedUrl;
}

async function upload(file, signedUrl, formIndex) {
  $('.upload-progress-bar-' + formIndex)
    .attr('aria-valuenow', 0)
    .css('width', '0%');
  $('.upload-progress-' + formIndex).show('slow');

  await axios.put(signedUrl, file, {
    headers: {
      'Content-Type': file.type
    },
    onUploadProgress: (e) => {
      const percentCompleted = Math.round((e.loaded * 100) / e.total);

      $('.upload-progress-bar-' + formIndex)
        .attr('aria-valuenow', percentCompleted)
        .css('width', percentCompleted + '%');
    }
  });
}

async function handleImageChange(e) {
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
    $('.image-preview-wrapper-' + formIndex + '> label').show();

    // Put the url of the uploaded file into the url input make it readonly
    $(e.target)
      .closest('.image-upload-wrapper')
      .parent()
      .find('.image-upload-url')
      .val(fileUrl)
      .attr('readonly', true);
  } catch (e) {
    console.error(e);
  }
}

// Saving this globally, because we need to rebind events when a new nested form is added
window.bindImageUploadEvents = () => {
  $('.image-upload-toggle')
    .off()
    .on('click', (e) => {
      $('.image-input-' + e.target.dataset.index).click();
    });

  $('.image-input').off().on('change', handleImageChange);
};

$(() => {
  window.bindImageUploadEvents();
});
