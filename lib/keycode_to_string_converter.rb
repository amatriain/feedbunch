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
    str = code.chr
    if str =~ /^[[:alnum:]]$/
      return str
    else
      # TODO
    end
  end
end