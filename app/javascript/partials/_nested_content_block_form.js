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

$(function () {
  if ($('#nested-content-blocks').length) {
    const initNestedMediaContents = ($form) => {
      const timestamp = Date.now();

      $form.find('.nested-media-content-block').addClass(`nested-media-content-block-${timestamp}`);
      $form.find('.nested-medium-form').addClass(`nested-medium-form-${timestamp}`);
      $form.find('.nested-add-medium').addClass(`nested-add-medium-${timestamp}`);

      $form.find(`.nested-media-content-block-${timestamp}`).nestedForm({
        forms: `.nested-medium-form-${timestamp}`,
        adder: `.nested-add-medium-${timestamp}`,
        ...defaultNestedFormsOptions,
        beforeAddForm: ($container) => {
          $container.children(`.nested-medium-form-${timestamp}`).removeClass('d-none');
        },
        associations: 'media_contents' // needed to correctly increment ids of added sections
      });
    };

    $('#nested-content-blocks').nestedForm({
      forms: '.nested-content-block-form',
      adder: '#nested-add-content-block',
      remover: '.removeContent',
      postfixes: '',
      afterInitialize: () => {
        const $initialForms = $('.nested-content-block-form');

        $initialForms.each((index, form) => {
          initNestedMediaContents($(form));
        });
      },
      beforeAddForm: (_$container, $form) => {
        // we only want one initialized media content, so remove eventually created others
        $form.find('.nested-medium-form').each((index, form) => {
          if (index > 0) {
            $(form).remove();
          }
        });
      },
      afterAddForm: (_$container, $form) => {
        initNestedMediaContents($form);

        // init html editors for content block fields body and intro
        $form
          .get('0')
          .querySelectorAll('.html-editor')
          .forEach((htmlEditor) => initClassicEditor(htmlEditor));
      }
    });
  }
});
