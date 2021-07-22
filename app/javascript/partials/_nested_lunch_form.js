import { defaultNestedFormsOptions } from './_nested_forms';

const initClassicEditor = (htmlEditor) => {
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

/* eslint-disable func-names */
$(function() {
  if ($('#nested-lunches').length) {
    const initNestedLunchOffers = ($form) => {
      const timestamp = Date.now();

      $form.find('.nested-lunch-offer').addClass(`nested-lunch-offer-${timestamp}`);
      $form.find('.nested-lunch-offer-form').addClass(`nested-lunch-offer-form-${timestamp}`);
      $form.find('.nested-add-lunch-offer').addClass(`nested-add-lunch-offer-${timestamp}`);

      $form.find(`.nested-lunch-offer-${timestamp}`).nestedForm({
        forms: `.nested-lunch-offer-form-${timestamp}`,
        adder: `.nested-add-lunch-offer-${timestamp}`,
        ...defaultNestedFormsOptions,
        beforeAddForm: ($container) => {
          $container.children(`.nested-lunch-offer-form-${timestamp}`).removeClass('d-none');
        },
        associations: 'lunch_offers' // needed to correctly increment ids of added sections
      });
    };

    $('#nested-lunches').nestedForm({
      forms: '.nested-lunch-form',
      adder: '#nested-add-lunch',
      remover: '.removeContent',
      postfixes: '',
      afterInitialize: () => {
        const $initialForms = $('.nested-lunch-form');

        $initialForms.each((index, form) => {
          initNestedLunchOffers($(form));
        });
      },
      beforeAddForm: ($container, $form) => {
        // we only want one initialized lunch offer, so remove eventually created others
        $form.find('.nested-lunch-offer-form').each((index, form) => {
          if (index > 0) {
            $(form).remove();
          }
        });
        $container.children('.nested-lunch-form').removeClass('d-none');
      },
      afterAddForm: (_$container, $form) => {
        initNestedLunchOffers($form);

        // init html editors for lunch field text
        $form
          .get('0')
          .querySelectorAll('.html-editor')
          .forEach((htmlEditor) => initClassicEditor(htmlEditor));
      }
    });
  }
});
/* eslint-enable func-names */
