require 'rails_helper'

describe Entry, type: :model do

  before :each do
    @entry = FactoryBot.create :entry
  end

  context 'validations' do

    it 'always belongs to a feed' do
      entry = FactoryBot.build :entry, feed_id: nil
      expect(entry).not_to be_valid
    end

    it 'requires a URL' do
      entry_nil = FactoryBot.build :entry, url: nil
      expect(entry_nil).not_to be_valid
      entry_empty = FactoryBot.build :entry, url: ''
      expect(entry_empty).not_to be_valid
    end

    it 'accepts valid HTTP URLs' do
      entry = FactoryBot.build :entry, url: 'http://xkcd.com'
      expect(entry).to be_valid
    end

    it 'accepts valid HTTPS URLs' do
      entry = FactoryBot.build :entry, url: 'https://xkcd.com'
      expect(entry).to be_valid
    end

    it 'accepts valid protocol-relative URLs' do
      entry = FactoryBot.build :entry, url: '//xkcd.com'
      expect(entry).to be_valid
    end

    it 'converts relative URLs to absolute' do
      host = 'feed.server.com'
      feed = FactoryBot.create :feed, url: "http://#{host}"
      relative_url = '/entry.html'
      entry = FactoryBot.build :entry, feed_id: feed.id, url: relative_url
      feed.entries << entry
      expect(entry.url).to eq "http://#{host}#{relative_url}"
    end
  end

  context 'duplicate entries' do
    context 'duplicate guid' do
      it 'does not accept duplicate guids for the same feed' do
        entry_dupe = FactoryBot.build :entry, guid: @entry.guid, feed_id: @entry.feed.id
        expect(entry_dupe).not_to be_valid
      end

      it 'accepts duplicate guids for different feeds' do
        feed2 = FactoryBot.create :feed
        entry_dupe = FactoryBot.build :entry, guid: @entry.guid, feed_id: feed2.id
        expect(entry_dupe).to be_valid
      end

      it 'does not accept the same guid as a deleted entry from the same feed' do
        deleted_entry = FactoryBot.create :deleted_entry
        entry = FactoryBot.build :entry, guid: deleted_entry.guid, feed_id: deleted_entry.feed_id
        expect(entry).not_to be_valid
      end

      it 'accepts the same guid as a deleted entry from another feed' do
        feed2 = FactoryBot.create :feed
        deleted_entry = FactoryBot.create :deleted_entry
        entry = FactoryBot.build :entry, guid: deleted_entry.guid, feed_id: feed2.id
        expect(entry).to be_valid
      end
    end

    context 'duplicate content' do
      before :each do
        title = 'Qué es Daegon? I'
        url = 'https://www.daegon.net/portal/que_es_daegon_i'
        @content = '&lt;div class=&quot;field field-name-body field-type-text-with-summary field-label-hidden&quot;&gt;&lt;div class=&quot;field-items&quot;&gt;&lt;div class=&quot;field-item even&quot; property=&quot;content:encoded&quot;&gt;&lt;div style=&quot;text-align: justify;&quot;&gt;
&lt;center&gt;&lt;span class=&quot;flickr-wrap&quot; style=&quot;width:640px;&quot;&gt;&lt;span class=&quot;flickr-image&quot;&gt;&lt;a href=&quot;https://www.flickr.com/photos/42971039@N00/9020155328&quot; title=&quot;daegon_v002 - 6 años ago ago by Javi. - &quot; class=&quot; flickr-img-wrap&quot; rel=&quot;&quot; target=&quot;_blank&quot;&gt;&lt;img class=&quot;flickr-photo-img&quot; typeof=&quot;foaf:Image&quot; src=&quot;https://live.staticflickr.com/3744/9020155328_78dbfea59f_z.jpg&quot; alt=&quot;Mar, 06/11/2013 - 14:04 - daegon_v002&quot; title=&quot;Mar, 06/11/2013 - 14:04 - daegon_v002&quot; /&gt;&lt;/a&gt; &lt;span class=&quot;flickr-copyright&quot;&gt;&lt;a href=&quot;https://en.wikipedia.org/wiki/Copyright&quot; title=&quot;All Rights Reserved&quot; target=&quot;_blank&quot;&gt;©&lt;/a&gt;&lt;/span&gt;&lt;/span&gt;&lt;span class=&quot;flickr-credit&quot;&gt;&lt;a href=&quot;https://www.flickr.com/photos/42971039@N00/9020155328&quot; title=&quot;View on Flickr. To enlarge click image.&quot; target=&quot;_blank&quot;&gt;&lt;span class=&quot;flickr-title&quot;&gt;daegon_v002&lt;/span&gt;&lt;br /&gt;&lt;/a&gt;&lt;span class=&quot;flickr-metadata&quot;&gt;&lt;a title=&quot;Martes, Junio 11, 2013 - 14:04&quot;&gt;6 años ago&lt;/a&gt; ago by &lt;a href=&quot;https://www.flickr.com/people/42971039@N00/&quot; title=&quot;View user on Flickr.&quot; target=&quot;_blank&quot;&gt;Javi&lt;/a&gt;.&lt;/span&gt;&lt;/span&gt;&lt;/span&gt;&lt;/center&gt;&lt;br /&gt;
Daegon es una suma. El cúmulo de una sucesión incontable de instantes y situaciones, un punto indeterminado dentro de una espiral finita.
&lt;p&gt;Tras tu viaje a través de los textos que preceden a este, a buen seguro aún te seguirás preguntando ¿Qué es Daegon?&lt;br /&gt;
Y esa es una muy buena pregunta. Una que trataremos de comenzar a responder a continuación, pero cuya resolución no es sencilla.&lt;/p&gt;
Este será al que más espacio se dedique en los distintos textos que componen este portal y, en gran medida, la escala para la que está pensado su reglamento.
&lt;/p&gt;&lt;/div&gt;
&lt;/div&gt;&lt;/div&gt;&lt;/div&gt;  &lt;div id=&quot;book-navigation-114&quot; class=&quot;book-navigation&quot;&gt;

        &lt;div class=&quot;page-links clearfix&quot;&gt;
              &lt;a href=&quot;/portal/que_es_un_juego_de_rol&quot; class=&quot;page-previous&quot; title=&quot;Ir a la página anterior&quot;&gt;‹ ¿Qué es un juego de rol?&lt;/a&gt;
                    &lt;a href=&quot;/portal/introduccion&quot; class=&quot;page-up&quot; title=&quot;Ir a la página madre&quot;&gt;arriba&lt;/a&gt;
                    &lt;a href=&quot;/portal/que_es_daegon_ii&quot; class=&quot;page-next&quot; title=&quot;Ir a la página siguiente&quot;&gt;¿Qué es Daegon? II: El Hoy ›&lt;/a&gt;
          &lt;/div&gt;

  &lt;/div&gt;'
        guid_orig = '1 at https://www.daegon.net/portal'
        @guid_another = '1 at http://www.daegon.net/portal'

        @entry.title = title
        @entry.url = url
        @entry.content = @content
        @entry.guid = guid_orig
        @entry.save
      end

      it 'does not accept duplicate entry contents for the same feed' do
        entry_dupe = FactoryBot.build :entry, guid: @guid_another, feed_id: @entry.feed.id, content: @content
        expect(entry_dupe).not_to be_valid
      end

      it 'accepts duplicate entry contents for different feeds' do
        feed2 = FactoryBot.create :feed
        entry_dupe = FactoryBot.build :entry, guid: @guid_another, feed_id: feed2.id, content: @content
        expect(entry_dupe).to be_valid
      end

      it 'does not accept the same entry content as a deleted entry from the same feed'

      it 'accepts the same entry content as a deleted entry from another feed'
    end
  end

  context 'default values' do

    before :each do
      @url = 'http://some.feed.com/'
    end

    it 'defaults guid to url attribute' do
      entry1 = FactoryBot.create :entry, url: @url, guid: nil
      expect(entry1.guid).to eq @url

      entry1.destroy

      entry2 = FactoryBot.create :entry, url: @url, guid: ''
      expect(entry2.guid).to eq @url
    end

    it 'defaults title to url attribute' do
      entry1 = FactoryBot.create :entry, url: @url, title: nil
      expect(entry1.title).to eq @url

      entry2 = FactoryBot.create :entry, url: @url, title: ''
      expect(entry2.title).to eq @url
    end

    it 'does not use default value if guid has value' do
      guid = '123456789a'
      entry = FactoryBot.create :entry, url: @url, guid: guid
      expect(entry.guid).to eq guid
    end

    it 'does not use default value if title has value' do
      title = 'entry_title'
      entry = FactoryBot.create :entry, url: @url, title: title
      expect(entry.title).to eq title
    end

    it 'defaults url to guid if url is not a valid HTTP URL' do
      entry = FactoryBot.create :entry, url: 'not a valid url', guid: @url
      expect(entry.guid).to eq @url
      expect(entry.url).to eq @url
    end

    it 'defaults published date to current date' do
      published = Time.zone.parse '2000-01-01'
      allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return published
      entry = FactoryBot.create :entry, published: nil
      expect(entry.published).to eq published
    end

    it 'does not use default value if published date has value' do
      published = Time.zone.parse '2000-01-01'
      entry = FactoryBot.create :entry, published: published
      expect(entry.published).to eq published
    end

    it 'calculates md5 hash of content' do
      content = '<p>some entry content</p>'
      hash = Digest::MD5.hexdigest content
      entry = FactoryBot.create :entry, content: content
      expect(entry.content_hash).to eq hash
    end

    it 'does not calculate md5 hash of content if entry has no content' do
      entry = FactoryBot.create :entry, content: nil
      expect(entry.content_hash).to be_nil
    end
  end

  context 'sanitization' do

    it 'sanitizes title' do
      unsanitized_title = '<script>alert("pwned!");</script>title'
      sanitized_title = 'title'
      entry = FactoryBot.create :entry, title: unsanitized_title
      expect(entry.title).to eq sanitized_title
    end

    it 'sanitizes url' do
      unsanitized_url = 'http://xkcd.com/<script>alert("pwned!");</script>'
      sanitized_url = 'http://xkcd.com/'
      entry = FactoryBot.create :entry, url: unsanitized_url
      expect(entry.url).to eq sanitized_url
    end

    it 'sanitizes author' do
      unsanitized_author = '<script>alert("pwned!");</script>author'
      sanitized_author = 'author'
      entry = FactoryBot.create :entry, author: unsanitized_author
      expect(entry.author).to eq sanitized_author
    end

    it 'sanitizes content' do
      unsanitized_content = '<script>alert("pwned!");</script>content'
      sanitized_content = '<p>content</p>'
      entry = FactoryBot.create :entry, content: unsanitized_content
      expect(entry.content).to eq sanitized_content
    end

    it 'sanitizes summary' do
      unsanitized_summary = '<script>alert("pwned!");</script><p>summary</p>'
      sanitized_summary = '<p>summary</p>'
      entry = FactoryBot.create :entry, summary: unsanitized_summary
      expect(entry.summary).to eq sanitized_summary
    end

    it 'sanitizes content with mismatched style tags' do
      unsanitized_content = '<p><style>div{background-color: #e1f5fe;}</p><p>div.none {hyphens: none;}</style></p>content'
      sanitized_content = '<p></p>content'
      entry = FactoryBot.create :entry, content: unsanitized_content
      expect(entry.content).to eq sanitized_content
    end

    it 'sanitizes summary with mismatched style tags' do
      unsanitized_summary = '<p><style>div{background-color: #e1f5fe;}</p><p>div.none {hyphens: none;}</style></p>content'
      sanitized_summary = '<p></p>content'
      entry = FactoryBot.create :entry, summary: unsanitized_summary
      expect(entry.summary).to eq sanitized_summary
    end

    it 'sanitizes guid' do
      unsanitized_guid = '<script>alert("pwned!");</script>guid'
      sanitized_guid = 'guid'
      entry = FactoryBot.create :entry, guid: unsanitized_guid
      expect(entry.guid).to eq sanitized_guid
    end
  end

  context 'trimming' do

    it 'trims title' do
      untrimmed_title = "\n      title"
      trimmed_title = 'title'
      entry = FactoryBot.create :entry, title: untrimmed_title
      expect(entry.title).to eq trimmed_title
    end

    it 'trims url' do
      untrimmed_url = "\n    http://xkcd.com/"
      trimmed_url = 'http://xkcd.com/'
      entry = FactoryBot.create :entry, url: untrimmed_url
      expect(entry.url).to eq trimmed_url
    end

    it 'trims author' do
      untrimmed_author = "\n    author"
      trimmed_author = 'author'
      entry = FactoryBot.create :entry, author: untrimmed_author
      expect(entry.author).to eq trimmed_author
    end

    it 'trims content' do
      untrimmed_content = "\n    content"
      trimmed_content = '<p>content</p>'
      entry = FactoryBot.create :entry, content: untrimmed_content
      expect(entry.content).to eq trimmed_content
    end

    it 'trims summary' do
      untrimmed_summary = "\n    <p>summary</p>"
      trimmed_summary = '<p>summary</p>'
      entry = FactoryBot.create :entry, summary: untrimmed_summary
      expect(entry.summary).to eq trimmed_summary
    end

    it 'trims guid' do
      untrimmed_guid = "\n       guid"
      trimmed_guid = 'guid'
      entry = FactoryBot.create :entry, guid: untrimmed_guid
      expect(entry.guid).to eq trimmed_guid
    end
  end

  context 'fix encoding' do

    context 'fix missing utf-8 encoding' do

      it 'converts title' do
        # \xE2\x80\x93 is a unicode escape sequence
        not_utf8_title = "Senior Front End \xE2\x80\x93 EasyPost (YC S13) Hiring"
        utf8_title = 'Senior Front End – EasyPost (YC S13) Hiring'
        not_utf8_title.force_encoding 'ascii-8bit'
        entry = FactoryBot.create :entry, title: not_utf8_title
        expect(entry.title).to eq utf8_title
      end
    end

    context 'convert to utf-8' do
      it 'converts title' do
        # 0xE8 is a valid character in ISO-8859-1, invalid in UTF-8
        not_utf8_title = "\xE8 title"
        not_utf8_title.force_encoding 'iso-8859-1'
        utf8_title = 'è title'
        entry = FactoryBot.create :entry, title: not_utf8_title
        expect(entry.title).to eq utf8_title
      end

      it 'converts url' do
        # 0xE8 is a valid character in ISO-8859-1, invalid in UTF-8
        not_utf8_url = "http://xkcd.com/\xE8"
        not_utf8_url.force_encoding 'iso-8859-1'
        utf8_url = 'http://xkcd.com/%C3%A8'
        entry = FactoryBot.create :entry, url: not_utf8_url
        expect(entry.url).to eq utf8_url
      end

      it 'converts author' do
        # 0xE8 is a valid character in ISO-8859-1, invalid in UTF-8
        not_utf8_author = "\xE8 author"
        not_utf8_author.force_encoding 'iso-8859-1'
        utf8_author = 'è author'
        entry = FactoryBot.create :entry, author: not_utf8_author
        expect(entry.author).to eq utf8_author
      end

      it 'converts content' do
        # 0xE8 is a valid character in ISO-8859-1, invalid in UTF-8
        not_utf8_content = "<p>\xE8 content</p>"
        not_utf8_content.force_encoding 'iso-8859-1'
        utf8_content = '<p>è content</p>'
        entry = FactoryBot.create :entry, content: not_utf8_content
        expect(entry.content).to eq utf8_content
      end

      it 'converts summary' do
        # 0xE8 is a valid character in ISO-8859-1, invalid in UTF-8
        not_utf8_summary = "<p>\xE8 summary</p>"
        not_utf8_summary.force_encoding 'iso-8859-1'
        utf8_summary = '<p>è summary</p>'
        entry = FactoryBot.create :entry, summary: not_utf8_summary
        expect(entry.summary).to eq utf8_summary
      end

      it 'converts guid' do
        # 0xE8 is a valid character in ISO-8859-1, invalid in UTF-8
        not_utf8_guid = "\xE8 guid"
        not_utf8_guid.force_encoding 'iso-8859-1'
        utf8_guid = 'è guid'
        entry = FactoryBot.create :entry, guid: not_utf8_guid
        expect(entry.guid).to eq utf8_guid
      end
    end

  end

  context 'markup manipulation' do

    context 'summary' do

      it 'opens summary links in a new tab' do
        unmodified_summary = '<a href="http://some.link">Click here to read full story</a>'
        modified_summary = '<a href="http://some.link" target="_blank">Click here to read full story</a>'
        entry = FactoryBot.create :entry, summary: unmodified_summary
        expect(entry.summary).to eq modified_summary
      end

      it 'modifies images' do
        unmodified_summary = '<img width="1000" height="337" alt="20131029" class="attachment-full wp-post-image" src="http://www.leasticoulddo.com/wp-content/uploads/2013/10/20131029.gif">'
        modified_summary = '<img alt="20131029" src="/images/Ajax-loader.gif" data-src="http://www.leasticoulddo.com/wp-content/uploads/2013/10/20131029.gif">'
        entry = FactoryBot.create :entry, summary: unmodified_summary
        expect(entry.summary).to eq modified_summary
      end

      it 'prepares images from internationalized URLs' do
        unmodified_summary = '<img src="http://www.gewürzrevolver.de/image.gif">'
        modified_summary = '<img src="/images/Ajax-loader.gif" data-src="http://www.xn--gewrzrevolver-yob.de/image.gif">'
        entry = FactoryBot.create :entry, summary: unmodified_summary
        expect(entry.summary).to eq modified_summary
      end

      it 'does not change images with relative scheme' do
        unmodified_summary = '<img src="//feeds.feedburner.com/some/image.gif">'
        modified_summary = '<img src="/images/Ajax-loader.gif" data-src="//feeds.feedburner.com/some/image.gif">'
        entry = FactoryBot.create :entry, summary: unmodified_summary
        expect(entry.summary).to eq modified_summary
      end

      it 'does not change images with data-uri src' do
        unmodified_summary = '<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==">'
        modified_summary = '<img src="/images/Ajax-loader.gif" data-src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==">'
        entry = FactoryBot.create :entry, summary: unmodified_summary
        expect(entry.summary).to eq modified_summary
      end

      it 'removes blob object-URLs from images' do
        unmodified_summary = '<img src="blob:https%3A//mail.google.com/02a6b9f2-6474-4bab-bbf8-72e91e25e157">'
        modified_summary = '<img src="/images/Ajax-loader.gif" data-src="">'
        entry = FactoryBot.create :entry, summary: unmodified_summary
        expect(entry.summary).to eq modified_summary
      end

      it 'removes scheme-only URLs from images' do
        unmodified_summary = '<img src="http://">'
        modified_summary = '<img src="/images/Ajax-loader.gif" data-src="">'
        entry = FactoryBot.create :entry, summary: unmodified_summary
        expect(entry.summary).to eq modified_summary
      end

      it 'removes html comments' do
        unmodified_summary = '<p><!--This is a comment-->This is some text</p>'
        modified_summary = '<p>This is some text</p>'
        entry = FactoryBot.create :entry, summary: unmodified_summary
        expect(entry.summary).to eq modified_summary
      end
    end

    context 'content' do

      it 'opens content links in a new tab' do
        unmodified_content = '<a href="http://some.link">Click here to read full story</a>'
        modified_content = '<a href="http://some.link" target="_blank">Click here to read full story</a>'
        entry = FactoryBot.create :entry, content: unmodified_content
        expect(entry.content).to eq modified_content
      end

      it 'modifies images' do
        unmodified_content = '<img width="1000" height="337" alt="20131029" class="attachment-full wp-post-image" src="http://www.leasticoulddo.com/wp-content/uploads/2013/10/20131029.gif">'
        modified_content = '<img alt="20131029" src="/images/Ajax-loader.gif" data-src="http://www.leasticoulddo.com/wp-content/uploads/2013/10/20131029.gif">'
        entry = FactoryBot.create :entry, content: unmodified_content
        expect(entry.content).to eq modified_content
      end

      it 'prepares images from internationalized URLs' do
        unmodified_content = '<img src="http://www.gewürzrevolver.de/image.gif">'
        modified_content = '<img src="/images/Ajax-loader.gif" data-src="http://www.xn--gewrzrevolver-yob.de/image.gif">'
        entry = FactoryBot.create :entry, content: unmodified_content
        expect(entry.content).to eq modified_content
      end

      it 'does not change images with relative scheme' do
        unmodified_content = '<img src="//feeds.feedburner.com/some/image.gif">'
        modified_content = '<img src="/images/Ajax-loader.gif" data-src="//feeds.feedburner.com/some/image.gif">'
        entry = FactoryBot.create :entry, content: unmodified_content
        expect(entry.content).to eq modified_content
      end

      it 'does not change images with data-uri src' do
        unmodified_content = '<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==">'
        modified_content = '<img src="/images/Ajax-loader.gif" data-src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==">'
        entry = FactoryBot.create :entry, content: unmodified_content
        expect(entry.content).to eq modified_content
      end

      it 'removes blob object-URLs from images' do
        unmodified_content = '<img src="blob:https%3A//mail.google.com/02a6b9f2-6474-4bab-bbf8-72e91e25e157">'
        modified_content = '<img src="/images/Ajax-loader.gif" data-src="">'
        entry = FactoryBot.create :entry, content: unmodified_content
        expect(entry.content).to eq modified_content
      end

      it 'removes scheme-only URLs from images' do
        unmodified_content = '<img src="http://">'
        modified_content = '<img src="/images/Ajax-loader.gif" data-src="">'
        entry = FactoryBot.create :entry, content: unmodified_content
        expect(entry.content).to eq modified_content
      end

      it 'removes html comments' do
        unmodified_content = '<p><!--This is a comment-->This is some text</p>'
        modified_content = '<p>This is some text</p>'
        entry = FactoryBot.create :entry, content: unmodified_content
        expect(entry.content).to eq modified_content
      end
    end

  end

  context 'read/unread state' do

    it 'stores the read/unread states of an entry for subscribed users' do
      feed = FactoryBot.create :feed
      entry = FactoryBot.build :entry, feed_id: feed.id
      feed.entries << entry
      user1 = FactoryBot.create :user
      user2 = FactoryBot.create :user
      user1.subscribe feed.fetch_url
      user2.subscribe feed.fetch_url

      expect(entry.entry_states.count).to eq 2
      expect(entry.entry_states.where(user_id: user1.id).count).to eq 1
      expect(entry.entry_states.where(user_id: user2.id).count).to eq 1
    end

    it 'deletes entry states when deleting an entry' do
      feed = FactoryBot.create :feed
      entry = FactoryBot.build :entry, feed_id: feed.id
      feed.entries << entry
      user = FactoryBot.create :user
      user.subscribe feed.fetch_url

      expect(EntryState.where(entry_id: entry.id).count).to eq 1

      entry.destroy
      expect(EntryState.where(entry_id: entry.id).count).to eq 0
    end

    it 'marks an entry as unread for all subscribed users when first saving it' do
      feed = FactoryBot.create :feed
      user1 = FactoryBot.create :user
      user2 = FactoryBot.create :user
      user1.subscribe feed.fetch_url
      user2.subscribe feed.fetch_url

      entry = FactoryBot.build :entry, feed_id: feed.id
      entry.save!

      expect(user1.entry_states.count).to eq 1
      expect(user1.entry_states.where(entry_id: entry.id, read: false)).to be_present
      expect(user2.entry_states.count).to eq 1
      expect(user2.entry_states.where(entry_id: entry.id, read: false)).to be_present
    end

    it 'does not change read/unread state when updating an already saved entry' do
      feed = FactoryBot.create :feed
      entry = FactoryBot.create :entry, feed_id: feed.id
      user1 = FactoryBot.create :user
      user2 = FactoryBot.create :user
      user1.subscribe feed.fetch_url
      user2.subscribe feed.fetch_url

      expect(user1.entry_states.count).to eq 1
      expect(user2.entry_states.count).to eq 1

      entry.summary = "changed summary"
      entry.save!

      expect(user1.entry_states.count).to eq 1
      expect(user2.entry_states.count).to eq 1
    end

    it 'does not save read/unread information for unsubscribed users' do
      feed = FactoryBot.create :feed
      user1 = FactoryBot.create :user
      user2 = FactoryBot.create :user
      user1.subscribe feed.fetch_url

      entry = FactoryBot.build :entry, feed_id: feed.id
      entry.save!

      expect(user1.entry_states.count).to eq 1
      expect(user1.entry_states.where(entry_id: entry.id, read: false)).to be_present
      expect(user2.entry_states.count).to eq 0
    end

    it 'retrieves state for a read entry' do
      feed = FactoryBot.create :feed
      user = FactoryBot.create :user
      user.subscribe feed.fetch_url
      entry = FactoryBot.build :entry, feed_id: feed.id
      feed.entries << entry

      entry_state = EntryState.find_by user_id: user.id, entry_id: entry.id
      entry_state.read = true
      entry_state.save

      expect(entry.read_by?(user)).to be true
    end

    it 'retrieves state for an unread entry' do
      feed = FactoryBot.create :feed
      user = FactoryBot.create :user
      user.subscribe feed.fetch_url
      entry = FactoryBot.build :entry, feed_id: feed.id
      feed.entries << entry

      entry_state = EntryState.find_by user_id: user.id, entry_id: entry.id
      entry_state.read = false
      entry_state.save

      expect(entry.read_by?(user)).to be false
    end

    it 'raises error trying to get state for an entry from an unsubscribed feed' do
      feed = FactoryBot.create :feed
      user = FactoryBot.create :user
      entry = FactoryBot.build :entry, feed_id: feed.id
      feed.entries << entry

      expect {entry.read_by? user}.to raise_error NotSubscribedError
    end
  end

  context 'special feeds' do

    before :each do
      @special_feed_url = 'www.demonoid.pw'

      Rails.application.config.special_feeds_fetchers = {}
      Rails.application.config.special_feeds_handlers = {}
      Rails.application.config.special_feeds_handlers[@special_feed_url] = DemonoidFeedHandler
    end

    context 'feeds that do not match list of special feeds' do
      before :each do
        @feed = FactoryBot.create :feed
        @entry = FactoryBot.build :entry, feed_id: @feed.id
      end

      it 'does not pass entries to a handler' do
        expect(DemonoidFeedHandler).not_to receive :handle_entry
        @feed.entries << @entry
      end

      it 'does not change entry guid before saving' do
        guid_before = @entry.guid

        @feed.entries << @entry
        @entry.reload

        expect(@entry.guid).to eq guid_before
      end
    end

    context 'url matches list of special feeds' do
      before :each do
        @guid_unchanged = 'http://www.demonoid.pw/files/details/3400534/0687950652/'
        @guid_changed = 'http://www.demonoid.pw/files/details/3400534/'
        @feed = FactoryBot.create :feed, url: @special_feed_url
        @entry = FactoryBot.build :entry, feed_id: @feed.id, guid: @guid_unchanged
      end

      it 'passes entries from special feeds to the right handler' do
        expect(DemonoidFeedHandler).to receive(:handle_entry).with @entry
        @feed.entries << @entry
      end

      it 'changes entry guid before saving' do
        expect(@entry.guid).to eq @guid_unchanged
        @feed.entries << @entry
        @entry.reload
        expect(@entry.guid).to eq @guid_changed
      end
    end
  end
end
