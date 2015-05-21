##
# Class to manage changes in text encoding.

class EncodingManager

  ##
  # Fix problems with encoding in a string.
  # If the string is valid UTF-8, force it to UTF-8 encoding.
  # Otherwise, convert from ISO-8859-1 to UTF-8 if necessary.
  #
  # Receives as argument a string.

  def self.fix_encoding(text)
    fixed_text = text
    fixed_text = fix_utf8 fixed_text
    fixed_text = convert_to_utf8 fixed_text
    return fixed_text
  end

  ##
  # Check if the passed text is valid for its current encoding. If not, the passed encoding is forced.
  # This is intended for the case in which Feedjira is passed a non-utf8 string but the outputs are in
  # utf-8.

  def self.set_encoding(text, encoding)
    text_encoded = text
    unless text_encoded.nil?
      unless text_encoded.valid_encoding?
        text_encoded.force_encoding encoding
      end
    end
    return text_encoded
  end

  private

  ##
  # If the passed string is valid UTF-8, force UTF-8 encoding.
  # Returns string with encoding changed to UTF-8 if necessary.

  def self.fix_utf8(text)
    fixed_text = text

    if !text.nil?
      if text.encoding != Encoding::UTF_8
        utf8_text = text.dup
        utf8_text.force_encoding 'utf-8'
        if utf8_text.valid_encoding?
          Rails.logger.debug "Text ###{text}## is valid UTF-8 but does not have UTF-8 encoding. Changing encoding to UTF-8."
          fixed_text = utf8_text
        end
      end
    end

    return fixed_text
  end

  ##
  # Convert the passed string to UTF-8 replacing unknown characters with "?".
  # Returns the string, with the internal representation and encoding changed if necessary.

  def self.convert_to_utf8(text)
    converted_text = text

    unless text.nil?
      converted_text = text.encode 'UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'}
    end

    return converted_text
  end
end