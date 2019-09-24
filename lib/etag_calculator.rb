# frozen_string_literal: true

##
# This class has methods to calculate etags based on time.

class EtagCalculator

  ##
  # Calculate an etag, given a Time instance.
  #
  # The etag is calculated the following way:
  # - convert the Time instance to the floating point number of seconds since Epoch
  # - convert this floating point number to a string
  # - Using the OpenSSL module, calculate the MD5 hash of that string as an hexadecimal string. This string is the
  # returned Etag.
  #
  # Using floating point precision for the fractional number of seconds since Epoch guarantees that any two different
  # Time instances will have different Etags, no matter how close they are in time, as long as they are not the same Time.
  #
  # Receives as argument the Time instance based on which the etag will be calculated.
  #
  # Returns the calculated etag.

  def self.etag(time)
    etag = OpenSSL::Digest::MD5.new.hexdigest time.to_f.to_s
    return etag
  end
end