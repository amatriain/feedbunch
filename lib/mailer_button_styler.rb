##
# This class has methods that help composing emails.

class MailerButtonStyler

  ##
  # Returns a CSS style that styles a link element as a Bootstrap button.
  # This should be used as an inline style in emails, because a lot of email clients do not support
  # linked CSS stylesheets nor style tags.

  def self.button_style
    button_style = <<STYLE
        background-image: linear-gradient(to bottom, #428bca 0px, #2d6ca2 100%);
        background-repeat: repeat-x;
        border-color: #2b669a;
        box-shadow: 0 1px 0 rgba(255, 255, 255, 0.15) inset, 0 1px 1px rgba(0, 0, 0, 0.075);
        text-shadow: 0 -1px 0 rgba(0, 0, 0, 0.2);
        border-radius: 6px;
        padding: 10px 16px;
        background-color:#428bca;
        color: #fff;
        cursor: pointer;
        display: inline-block;
        text-decoration: none;
        vertical-align: middle;
STYLE

    return button_style
  end
end