##
# Output HTML for a locale select form field.
#
# The HTML generated is compatible with Bootstrap, and it prepends a flag icon
# (from FontAwesome[http://fortawesome.github.io/Font-Awesome/]) before the input.
#
# This class is intended to be used from simple_form[https://github.com/plataformatec/simple_form] forms like this:
#
#   <%= simple_form_for user, wrapper: :prepend do %>
#     <%= f.input :email, as: :email_icon %>
#     ...
#   <% end %>

class LocaleInput < SimpleForm::Inputs::Base
  def input
    "<span class=\"input-group-addon\"><i class=\"icon-flag\"></i></span>#{@builder.input_field(attribute_name, collection: I18n.available_locales, label_method: lambda{|loc| locale_name loc}, selected: I18n.locale)}".html_safe
  end

  private

  def locale_name(locale)
    if locale == :en
      return 'English'
    elsif locale == :es
      return 'Español'
    end
  end
end