import { defaultNestedFormsOptions, initClassicEditor } from './_nested_forms';

$(function () {
  if ($('#nested-tour-stops').length) {
    const initNestedTextures = ($form) => {
      const timestamp = Date.now();

      $form.find('.nested-textures').addClass(`nested-textures-${timestamp}`);
      $form.find('.nested-texture-form').addClass(`nested-texture-form-${timestamp}`);
      $form.find('.nested-add-texture').addClass(`nested-add-texture-${timestamp}`);

      $form.find(`.nested-textures-${timestamp}`).nestedForm({
        forms: `.nested-texture-form-${timestamp}`,
        adder: `.nested-add-texture-${timestamp}`,
        ...defaultNestedFormsOptions,
        remover: '.removeTexture',
        associations: 'downloadable_uris', // needed to correctly increment ids of added sections
        startIndex: 3,
        afterAddForm: (_$container, $form) => {
          initNestedTextures($form);

          $form.find('input[id$="title"]').removeAttr('readonly');

          window.bindArFileUploadEvents();
        }
      });
    };

    const initNestedScenes = ($form) => {
      const timestamp = Date.now();

      $form.find('.nested-tour-stop-scenes').addClass(`nested-tour-stop-scenes-${timestamp}`);
      $form
        .find('.nested-tour-stop-scene-form')
        .addClass(`nested-tour-stop-scene-form-${timestamp}`);
      $form.find('.nested-add-tour-stop-scene').addClass(`nested-add-tour-stop-scene-${timestamp}`);

      $form.find(`.nested-tour-stop-scenes-${timestamp}`).nestedForm({
        forms: `.nested-tour-stop-scene-form-${timestamp}`,
        adder: `.nested-add-tour-stop-scene-${timestamp}`,
        ...defaultNestedFormsOptions,
        remover: '.removeScene',
        associations: 'scenes', // needed to correctly increment ids of added sections
        afterInitialize: () => {
          const $initialForms = $('.nested-tour-stop-scene-form');

          $initialForms.each((index, form) => {
            initNestedTextures($(form));
          });
        },
        beforeAddForm: ($container, $form) => {
          // we only want one initialized texture, so remove eventually created others
          $form.find('.nested-texture-form').each((index, form) => {
            if (index > 0) {
              $(form).remove();
            }
          });
        },
        afterAddForm: (_$container, $form) => {
          initNestedTextures($form);

          $form.find('input[id$="title"]').removeAttr('readonly');

          window.bindArFileUploadEvents();
        }
      });
    };

    $('#nested-tour-stops').nestedForm({
      forms: '.nested-tour-stop-form',
      adder: '#nested-add-tour-stop',
      ...defaultNestedFormsOptions,
      afterInitialize: () => {
        const $initialForms = $('.nested-tour-stop-form');

        $initialForms.each((index, form) => {
          initNestedScenes($(form));
        });
      },
      beforeAddForm: ($container, $form) => {
        $container.children('.nested-tour-stop-form').removeClass('d-none');

        // we only want one initialized scene, so remove eventually created others
        $form.find('.nested-tour-stop-scene-form').each((index, form) => {
          if (index > 0) {
            $(form).remove();
          }
        });

        // we do not want to initialize textures, so remove eventually created ones
        $form.find('.nested-texture-form').each((index, form) => {
          if (index > 0) {
            $(form).remove();
          }
        });
      },
      afterAddForm: (_$container, $form) => {
        initNestedScenes($form);

        $form.find('input[id$="title"]').removeAttr('readonly');

        // init html editors for name and description
        $form
          .get('0')
          .querySelectorAll('.html-editor')
          .forEach((htmlEditor) => initClassicEditor(htmlEditor));

        window.bindArFileUploadEvents();
      }
    });
  }
});
