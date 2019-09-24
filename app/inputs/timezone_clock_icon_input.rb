# frozen_string_literal: true

##
# Output HTML for a timezone select form field.
#
# The HTML generated is compatible with Bootstrap, and it prepends a time icon
# (from FontAwesome[http://fortawesome.github.io/Font-Awesome/]) before the input.
#
# This class is intended to be used from simple_form[https://github.com/plataformatec/simple_form] forms like this:
#
#   <%= simple_form_for user, wrapper: :prepend do %>
#     <%= f.input :timezone, as: :timezone_clock_icon %>
#     ...
#   <% end %>

class TimezoneClockIconInput < SimpleForm::Inputs::Base
  def input(wrapper_options)
    "<span class=\"input-group-addon\"><i class=\"fa fa-fw fa-clock-o\"></i></span>#{@builder.input_field(attribute_name, as: :time_zone, priority: /UTC/)}".html_safe
  end
end