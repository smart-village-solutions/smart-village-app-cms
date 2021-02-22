export const defaultNestedFormsOptions = {
  remover: '.remove',
  postfixes: '',
  afterRemoveForm: ($form) => {
    $form.remove();
  }
};

/* eslint-disable func-names */
$(function() {
  $('#nested-categories').nestedForm({
    forms: '.nested-category-form',
    adder: '#nested-add-category',
    ...defaultNestedFormsOptions
  });

  $('#nested-dates').nestedForm({
    forms: '.nested-date-form',
    adder: '#nested-add-dates',
    ...defaultNestedFormsOptions
  });

  $('#nested-event-contacts').nestedForm({
    forms: '.nested-event-contact-form',
    adder: '#nested-add-event-contacts',
    ...defaultNestedFormsOptions
  });

  $('#nested-price_informations').nestedForm({
    forms: '.nested-price_information-form',
    adder: '#nested-add-price_information',
    ...defaultNestedFormsOptions
  });

  $('#nested-web-urls').nestedForm({
    forms: '.nested-web-url-form',
    adder: '#nested-add-web-urls',
    ...defaultNestedFormsOptions,
    associations: 'urls' // needed to correctly increment ids of added sections
  });

  $('#nested-opening-hours').nestedForm({
    forms: '.nested-opening-hour-form',
    adder: '#nested-add-opening-hour',
    ...defaultNestedFormsOptions
  });

  // media not nested in a content block, for example in events.
  // everything with classes here, because in content blocks nested-media will appear multiple times
  $('.nested-media').nestedForm({
    forms: '.nested-medium-form',
    adder: '.nested-add-medium',
    ...defaultNestedFormsOptions
  });
});
/* eslint-enable func-names */
