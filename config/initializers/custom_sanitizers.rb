# Custom sanitizers, saved in config during initialization to avoid rebuilding them every time they are needed.
# - relaxed sanitizer: lets safe markup pass. Use it for html fragments (e.g. entry contents)
# - restricted sanitizer: more strict, use it for untrusted content that should not contain html (e.g. feed titles)
#
# The content of any tags stripped by the sanitizer is also removed.

require 'sanitize'

# RELAXED SANITIZER

# Deep copy of the elements hash, otherwise it cannot be modified (Sanitize freezes the original hash)
elements = Sanitize::Config::RELAXED[:elements]
elements = elements.deep_dup

# Style element is not allowed
elements.delete 'style'

# Deep copy of the attributes hash, otherwise it cannot be modified (Sanitize freezes the original hash)
attributes = Sanitize::Config::RELAXED[:attributes]
attributes = attributes.deep_dup

# "style", "class", "hidden" attributes are not allowed for any element
attributes[:all].delete('style').delete('class').delete 'hidden'

# "align", "border", "height", "width" attributes are not allowed for images
attributes['img'].delete('align').delete('border').delete('height').delete 'width'

# "width" attribute not allowed for "col" elements
attributes['col'].delete 'width'

# "width" attribute not allowed for "colgroup" elements
attributes['colgroup'].delete 'width'

# "width" attribute not allowed for tables
attributes['table'].delete 'width'

# "width" attribute not allowed for table cells
attributes['td'].delete 'width'

# "width" attribute not allowed for table headers
attributes['th'].delete 'width'

# "data-src" attribute allowed for "img" elements
attributes = attributes.merge({'img' => ['data-src']}) {|key, oldval, newval| oldval + newval}

# "target" attribute allowed for "a" elements
attributes = attributes.merge({'a' => ['target']}) {|key, oldval, newval| oldval + newval}

Feedbunch::Application.config.relaxed_sanitizer = Sanitize::Config.merge Sanitize::Config::RELAXED,
                                        remove_contents: true,
                                        elements: elements,
                                        attributes: attributes

# RESTRICTED SANITIZER

Feedbunch::Application.config.restricted_sanitizer = Sanitize::Config.merge Sanitize::Config::RESTRICTED,
                                           :remove_contents => true