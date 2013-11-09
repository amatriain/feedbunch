##
# Output HTML for a password input form field.
#
# The HTML generated is compatible with Bootstrap, and it prepends a key icon
# (from FontAwesome[http://fortawesome.github.io/Font-Awesome/]) before the input.
#
# This class is intended to be used from simple_form[https://github.com/plataformatec/simple_form] forms like this:
#
#   <%= simple_form_for user, wrapper: :prepend do %>
#     <%= f.input :password, as: :password_icon %>
#     ...
#   <% end %>

class PasswordIconInput < SimpleForm::Inputs::Base
  def input
    input_html_options[:placeholder] ||= I18n.t 'simple_form.placeholders.user.password'
    "<span class=\"input-group-addon\"><i class=\"fa fa-key\"></i></span>#{@builder.password_field(attribute_name, input_html_options)}".html_safe
  end
end