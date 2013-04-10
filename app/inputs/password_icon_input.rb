class PasswordIconInput < SimpleForm::Inputs::Base
  def input
    "<span class=\"add-on\"><i class=\"icon-key\"></i></span>#{@builder.password_field(attribute_name, input_html_options)}".html_safe
  end
end