# frozen_string_literal: true

##
# Output HTML for a folder-title input form field.
#
# The HTML generated is compatible with Bootstrap, and it prepends an open-folder icon
# (from FontAwesome[http://fortawesome.github.io/Font-Awesome/]) before the input.
#
# This class is intended to be used from simple_form[https://github.com/plataformatec/simple_form] forms like this:
#
#   <%= simple_form_for user, wrapper: :prepend do %>
#     <%= f.input :title, as: :folder_icon %>
#     ...
#   <% end %>

class FolderIconInput < SimpleForm::Inputs::Base
  def input(wrapper_options)
    input_html_options[:placeholder] ||= I18n.t 'simple_form.placeholders.new_folder.title'
    "<span class=\"input-group-addon\"><i class=\"fa fa-fw fa-folder-open\"></i></span>#{@builder.text_field(attribute_name, input_html_options)}".html_safe
  end
end