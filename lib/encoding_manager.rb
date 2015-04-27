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
    fixed_text = fix_iso8859_1 fixed_text
    return fixed_text
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
  # If the passed string is not valid UTF-8, reencode it from ISO-8859-1 to UTF-8 replacing unknown characters with "?".
  # If the string is not ISO-8859-1 this method wil not work as expected.
  # Returns the string, reencoded if necessary.

  def self.fix_iso8859_1(text)
    fixed_text = text

    if !text.nil?
      if !text.valid_encoding?
        Rails.logger.debug "Text ###{text}## is not valid UTF-8, reencoding from ISO-8859-1 to UTF-8"
        fixed_text = text.encode('UTF-8', 'iso-8859-1', {:invalid => :replace, :undef => :replace, :replace => '?'})
      end
    end

    return fixed_text
  end
end