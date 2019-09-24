# frozen_string_literal: true

##
# Output HTML for an email input form field.
#
# The HTML generated is compatible with Bootstrap, and it prepends an envelope icon
# (from FontAwesome[http://fortawesome.github.io/Font-Awesome/]) before the input.
#
# This class is intended to be used from simple_form[https://github.com/plataformatec/simple_form] forms like this:
#
#   <%= simple_form_for user, wrapper: :prepend do %>
#     <%= f.input :email, as: :email_icon %>
#     ...
#   <% end %>

class EmailIconInput < SimpleForm::Inputs::Base
  def input(wrapper_options)
    input_html_options[:placeholder] ||= I18n.t 'simple_form.placeholders.user.email'
    "<span class=\"input-group-addon\"><i class=\"fa fa-fw fa-envelope\"></i></span>#{@builder.email_field(attribute_name, input_html_options)}".html_safe
  end
end