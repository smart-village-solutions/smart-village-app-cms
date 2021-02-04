import { defaultNestedFormsOptions } from './_nested_forms';

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
        associations: 'lunch_offers' // needed to correctly increment ids of added sections
      });
    };

    $('#nested-lunches').nestedForm({
      forms: '.nested-lunch-form',
      adder: '#nested-add-lunch',
      remover: '.removeContent',
      postfixes: '',
      afterInitialize: function() {
        const $initialForms = $('.nested-lunch-form');

        $initialForms.each((index, form) => {
          initNestedLunchOffers($(form));
        });
      },
      beforeAddForm: function($container, $form) {
        // we only want one initialized lunch offer, so remove eventually created others
        $form.find('.nested-lunch-offer-form').each((index, form) => {
          if (index > 0) {
            $(form).remove();
          }
        });
      },
      afterAddForm: function($container, $form) {
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
