##
# Output HTML for a RSS input form field.
#
# The HTML generated is compatible with Bootstrap, and it prepends an rss icon
# (from FontAwesome[http://fortawesome.github.io/Font-Awesome/]) before the input.
#
# This class is intended to be used from simple_form[https://github.com/plataformatec/simple_form] forms like this:
#
#   <%= simple_form_for user, wrapper: :prepend do %>
#     <%= f.input :rss, as: :rss_icon %>
#     ...
#   <% end %>

class RssIconInput < SimpleForm::Inputs::Base
  def input
    input_html_options[:placeholder] ||= I18n.t 'simple_form.placeholders.subscription.rss'
    "<span class=\"input-group-addon\"><i class=\"fa fa-fw fa-rss\"></i></span>#{@builder.text_field(attribute_name, input_html_options)}".html_safe
  end
end