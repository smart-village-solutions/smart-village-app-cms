module I18nHelper
  # returns all entries inside `json` divided by html `<br />` to be rendered in a multiline way
  #   DE: asdasd
  #   PL: cvbcvbasdas
  def i18n_json_to_text(json)
    json.map { |key, value| "#{key.upcase}: #{value}" }.join("<br />").html_safe
  end
end
