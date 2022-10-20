const axios = require('axios');

async function getSignedUrl(filename) {
  const response = await axios.get('/minio/signed_url.json?filename=' + filename);

  return response.data.signedUrl;
}

async function upload(file, signedUrl, progressBarWrapper) {
  $(progressBarWrapper).show('slow');
  const $progressBar = $(progressBarWrapper).find('.upload-progress-bar');
  $progressBar.attr('aria-valuenow', 0).css('width', '0%');

  await axios.put(signedUrl, file, {
    headers: {
      'Content-Type': file.type
    },
    onUploadProgress: (e) => {
      const percentCompleted = Math.round((e.loaded * 100) / e.total);

      $progressBar.attr('aria-valuenow', percentCompleted).css('width', percentCompleted + '%');
    }
  });
}

async function handleImageChange(e) {
  try {
    // Get upload URL
    const file = e.target.files[0];
    const signedUrl = await getSignedUrl(file.name);
    const fileUrl = signedUrl.split('?')[0];
    const formIndex = e.target.dataset.index; // There might be multiple forms on the page

    // Upload the file
    await upload(file, signedUrl, e.target.nextElementSibling);

    $('.image-preview-' + formIndex).attr('src', fileUrl);
    $('.image-preview-wrapper-' + formIndex).show('slow');
    $('.image-preview-wrapper-' + formIndex + '> label').show();

    // Put the url of the uploaded file into the corresponding url input and make it readonly
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

async function handleArFileChange(e) {
  try {
    // Get upload URL
    const file = e.target.files[0];
    const signedUrl = await getSignedUrl(file.name);
    const fileUrl = signedUrl.split('?')[0];
    const fileName = file.name.split('.').slice(0, -1).join();
    const fileSize = file.size;

    // Upload the file
    await upload(file, signedUrl, e.target.nextElementSibling);

    // Put the url of the uploaded file into the corresponding url input and make it readonly
    $(e.target.previousElementSibling.previousElementSibling).val(fileUrl).attr('readonly', true);

    const $closestRow = $(e.target).closest('.row');

    // Put the url of the uploaded file into the corresponding url input and make it readonly,
    // if it is a texture
    $closestRow
      .find('input[name*="[title]"]')
      .val(fileName)
      .attr('readonly', $closestRow.hasClass('texture'));

    // Store the file size in the corresponding input
    $closestRow.prev('input[name*="[size]"]').val(fileSize);
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

window.bindArFileUploadEvents = () => {
  $('.ar-file-upload-toggle')
    .off()
    .on('click', (e) => {
      e.target.nextElementSibling.click();
    });

  $('.ar-file-input').off().on('change', handleArFileChange);
};

$(() => {
  window.bindImageUploadEvents();
  window.bindArFileUploadEvents();
});
