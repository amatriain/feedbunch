##
# Class to manage changes in text encoding.

class EncodingManager

  ##
  # Fix problems with encoding in a string.
  # Specifically, convert from ISO-8859-1 to UTF-8 if necessary.
  #
  # Receives as argument a string.

  def self.fix_encoding(text)
    fixed_attribute = text
    if !text.nil?
      if !text.valid_encoding?
        fixed_attribute = text.encode('UTF-8', 'iso-8859-1', {:invalid => :replace, :undef => :replace, :replace => '?'})
      end
    end
    return fixed_attribute
  end
end