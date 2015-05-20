##
# This class has methods to convert keycodes to a string representation suitable for displaying to a user.

class KeycodeToStringConverter

  ##
  # Convert a keycode to a string representation suitable to be displayed to the user.
  #
  # If the code passed corresponds to an alphanumeric key (1..0, a..z) a string with the character
  # is returned.
  # If the code corresponds to a special key (enter, spacebar, directional arrows...) a localized
  # string describing the key is returned.
  #
  # Receives as arguments:
  # - numeric key code
  # - locale symbol. It is used to localize the string representation of special keys (enter, etc).
  # It must be one of the locales supported by the application, the fallback locale is used otherwise
  #
  # Returns the string representation of the passed code.

  def self.convert(code, locale)
    if code.chr =~ /^[[:alnum:]]$/
      str = code.chr
    else
      unless I18n.available_locales.include? locale
        Rails.logger.info "Attempting to convert keycode #{code} to string with unavailable locale #{locale}. Defaulting to locale 'en' instead"
        locale = 'en'
      end

      case code
        when 8
          str = I18n.t 'keys.backspace'
        when 9
          str = I18n.t 'keys.tab'
        when 13
          str = I18n.t 'keys.enter'
        when 16
          str = I18n.t 'keys.shift'
        when 17
          str = I18n.t 'keys.ctrl'
        when 18
          str = I18n.t 'keys.alt'
        when 20
          str = I18n.t 'keys.capslock'
        when 27
          str = I18n.t 'keys.escape'
        when 32
          str = I18n.t 'keys.spacebar'
        when 33
          str = I18n.t 'keys.pageup'
        when 34
          str = I18n.t 'keys.pagedown'
        when 35
          str = I18n.t 'keys.end'
        when 36
          str = I18n.t 'keys.home'
        when 37
          str = I18n.t 'keys.arrow_left'
        when 38
          str = I18n.t 'keys.arrow_up'
        when 39
          str = I18n.t 'keys.arrow_right'
        when 40
          str = I18n.t 'keys.arrow_down'
        when 45
          str = I18n.t 'keys.insert'
        when 46
          str = I18n.t 'keys.delete'
        else
          str = '???'
      end
    end

    return str
  end
end