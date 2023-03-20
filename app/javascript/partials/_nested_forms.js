export const defaultNestedFormsOptions = {
  remover: '.remove',
  postfixes: '',
  afterRemoveForm: ($form) => {
    $form.remove();
  }
};

export const initClassicEditor = (htmlEditor) => {
  ClassicEditor.create(htmlEditor, {
    toolbar: [
      'heading',
      '|',
      'bulletedList',
      'numberedList',
      'link',
      'bold',
      'italic',
      '|',
      'undo',
      'redo'
    ]
  })
    .then((editor) => {
      // console.log(Array.from(editor.ui.componentFactory.names()));
    })
    .catch((error) => {
      console.error(error);
    });
};

$(function () {
  $('#nested-categories').nestedForm({
    forms: '.nested-category-form',
    adder: '#nested-add-category',
    ...defaultNestedFormsOptions,
    beforeAddForm: ($container) => {
      $container.children('.nested-category-form').removeClass('d-none');
    }
  });

  $('#nested-dates').nestedForm({
    forms: '.nested-date-form',
    adder: '#nested-add-dates',
    ...defaultNestedFormsOptions,
    beforeAddForm: ($container) => {
      $container.children('.nested-date-form').removeClass('d-none');
    }
  });

  $('#nested-contacts').nestedForm({
    forms: '.nested-contact-form',
    adder: '#nested-add-contacts',
    ...defaultNestedFormsOptions,
    beforeAddForm: ($container) => {
      $container.children('.nested-contact-form').removeClass('d-none');
    }
  });

  $('#nested-price_informations').nestedForm({
    forms: '.nested-price_information-form',
    adder: '#nested-add-price_information',
    ...defaultNestedFormsOptions,
    beforeAddForm: ($container) => {
      $container.children('.nested-price_information-form').removeClass('d-none');
    }
  });

  $('#nested-restrictions').nestedForm({
    forms: '.nested-restriction-form',
    adder: '#nested-add-restriction',
    ...defaultNestedFormsOptions,
    beforeAddForm: ($container) => {
      $container.children('.nested-restriction-form').removeClass('d-none');
    }
  });

  $('#nested-push-notifications').nestedForm({
    forms: '.nested-push-notification-form',
    adder: '#nested-add-push-notification',
    ...defaultNestedFormsOptions,
    beforeAddForm: ($container) => {
      $container.children('.nested-push-notification-form').removeClass('d-none');
    },
    afterAddForm: (_, $form) => {
      // clear date and time inputs because normally just texts and textareas are cleared
      $form.find('input[type="time"], input[type="datetime-local"]').val('');
      // adjust initial visible fields to have `once_at` visible
      $form.find('.collapse').addClass('show');
    }
  });

  $('#nested-web-urls').nestedForm({
    forms: '.nested-web-url-form',
    adder: '#nested-add-web-urls',
    ...defaultNestedFormsOptions,
    beforeAddForm: ($container) => {
      $container.children('.nested-web-url-form').removeClass('d-none');
    },
    associations: 'urls' // needed to correctly increment ids of added sections
  });

  $('#nested-opening-hours').nestedForm({
    forms: '.nested-opening-hour-form',
    adder: '#nested-add-opening-hour',
    ...defaultNestedFormsOptions,
    beforeAddForm: ($container) => {
      $container.children('.nested-opening-hour-form').removeClass('d-none');
    },
    afterAddForm: (_$container, $form) => {
      $form.find('[id$="open"]').prop('checked', true);
    }
  });

  // We need to know the amount of forms at DOM load to know which classes we have to fix,
  // see in `incrementIndexesOfImageUploadElements`
  const nestedMediaFormElementsCountAtDomLoad = $('.nested-medium-form').length;

  const incrementIndexesOfImageUploadElements = ($container, $form, elementsCountAtDomLoad) => {
    const oldFormIndex = elementsCountAtDomLoad - 1;
    const newFormIndex = $container.children().length - 1;
    const classNamesToFix = [
      'image-input',
      'upload-progress',
      'upload-progress-bar',
      'image-preview-wrapper',
      'image-preview'
    ];

    $form.find('[data-index]').attr('data-index', newFormIndex);

    classNamesToFix.forEach((className) => {
      const $el = $form.find('.' + className);
      $el.removeClass(className + '-' + oldFormIndex);
      $el.addClass(className + '-' + newFormIndex);
    });

    window.bindImageUploadEvents();
  };

  // media not nested in a content block, for example in events.
  // everything with classes here, because in content blocks nested-media will appear multiple times
  $('.nested-media').nestedForm({
    forms: '.nested-medium-form',
    adder: '.nested-add-medium',
    ...defaultNestedFormsOptions,
    beforeAddForm: ($container) => {
      $container.children('.nested-medium-form').removeClass('d-none');
    },
    afterAddForm: ($container, $form) => {
      incrementIndexesOfImageUploadElements(
        $container,
        $form,
        nestedMediaFormElementsCountAtDomLoad
      );

      // reset image preview
      $form.find('.image-preview-wrapper > label').css('display', 'none');
      $form.find('.image-preview-wrapper > .image-preview').attr('src', '');
    }
  });
});
