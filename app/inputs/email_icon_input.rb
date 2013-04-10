class EmailIconInput < SimpleForm::Inputs::Base
  def input
    "<span class=\"add-on\"><i class=\"icon-envelope\"></i></span>#{@builder.email_field(attribute_name, input_html_options)}".html_safe
  end
end