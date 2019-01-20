require 'rails_helper'

describe Api::EntriesController, type: :controller do

  before :each do
    @user = FactoryBot.create :user
    login_user_for_unit @user
  end

  context 'PUT update' do

    before :each do
      @feed = FactoryBot.create :feed
      @user.subscribe @feed.fetch_url
      @entry = FactoryBot.build :entry, feed_id: @feed.id
      @feed.entries << @entry
    end

    it 'assigns the correct entry' do
      put :update, params: {entry: {id: @entry.id, state: 'read'}}, format: :json
      expect(assigns(:entry)).to eq @entry
    end

    it 'returns success' do
      put :update, params: {entry: {id: @entry.id, state: 'read', update_older: 'false'}}, format: :json
      expect(response).to be_successful
    end

    it 'returns 404 if the entry does not exist' do
      put :update, params: {entry: {id: 1234567890, state: 'read'}}, format: :json
      expect(response.status).to eq 404
    end

    it 'returns 404 if the user is not subscribed to the entries feed' do
      entry2 = FactoryBot.create :entry
      put :update, params: {entry: {id: entry2.id, state: 'read'}}, format: :json
      expect(response.status).to eq 404
    end

    it 'returns 500 if there is a problem changing the entry state' do
      allow_any_instance_of(User).to receive(:change_entries_state).and_raise StandardError.new
      put :update, params: {entry: {id: @entry.id, state: 'read'}}, format: :json
      expect(response.status).to eq 500
    end
  end

  context 'GET index' do

    context 'feed entries' do

      before :each do
        @feed = FactoryBot.create :feed
        @entry_1_1 = FactoryBot.build :entry, feed_id: @feed.id
        @entry_1_2 = FactoryBot.build :entry, feed_id: @feed.id
        @feed.entries << @entry_1_1 << @entry_1_2
        @user.subscribe @feed.fetch_url
      end

      it 'assigns to @feed the correct feed' do
        get :index, params: {feed_id: @feed.id}, format: :json
        expect(assigns(:feed)).to eq @feed
      end

      it 'assigns to @entries the entries for a single feed' do
        get :index, params: {feed_id: @feed.id}, format: :json
        expect(assigns(:entries).count).to eq 2
        expect(assigns(:entries)).to include @entry_1_1
        expect(assigns(:entries)).to include @entry_1_2
      end

      it 'returns a 404 for a feed the user is not suscribed to' do
        feed2 = FactoryBot.create :feed
        get :index, params: {feed_id: feed2.id}, format: :json
        expect(response.status).to eq 404
      end

      it 'returns a 404 for a non-existing feed' do
        get :index, params: {feed_id: 1234567890}, format: :json
        expect(response.status).to eq 404
      end

      it 'does not fetch new entries in the feed' do
        expect(FeedClient).not_to receive(:fetch).with @feed
        get :index, params: {feed_id: @feed.id}, format: :json
      end

      it 'assigns to @entries only unread entries by default' do
        @user.change_entries_state @entry_1_1, 'read'

        get :index, params: {feed_id: @feed.id}, format: :json
        expect(assigns(:entries).count).to eq 1
        expect(assigns(:entries)).to include @entry_1_2
      end

      it 'assigns to @entries all entries' do
        @user.change_entries_state @entry_1_1, 'read'

        get :index, params: {feed_id: @feed.id, include_read: 'true'}, format: :json
        expect(assigns(:entries).count).to eq 2
        expect(assigns(:entries)).to include @entry_1_1
        expect(assigns(:entries)).to include @entry_1_2
      end

      context 'pagination' do

        before :each do
          @entries = []
          # Ensure there are exactly 26 unread entries and 4 read entries
          Entry.all.each {|e| e.destroy}
          (0..29).each do |i|
            e = FactoryBot.build :entry, feed_id: @feed.id, published: Date.new(2001, 01, 30-i)
            @feed.entries << e
            @entries << e
          end
          (26..29).each do |i|
            @user.change_entries_state @entries[i], 'read'
          end
        end

        context 'unread entries' do

          it 'returns the first page of entries' do
            get :index, params: {feed_id: @feed.id, page: 1}, format: :json
            expect(assigns(:entries).count).to eq 25
            assigns(:entries).each_with_index do |entry, index|
              expect(entry).to eq @entries[index]
            end
          end

          it 'returns the last page of entries' do
            get :index, params: {feed_id: @feed.id, page: 2}, format: :json
            expect(assigns(:entries).count).to eq 1
            expect(assigns(:entries)[0]).to eq @entries[25]
          end

        end

        context 'all entries' do

          it 'returns the first page of entries' do
            get :index, params: {feed_id: @feed.id, include_read: 'true', page: 1}, format: :json
            expect(assigns(:entries).count).to eq 25
            assigns(:entries).each_with_index do |entry, index|
              expect(entry).to eq @entries[index]
            end
          end

          it 'returns the last page of entries' do
            get :index, params: {feed_id: @feed.id, include_read: 'true', page: 2}, format: :json
            expect(assigns(:entries).count).to eq 5
            assigns(:entries).each_with_index do |entry, index|
              expect(entry).to eq @entries[25 + index]
            end
          end

        end

      end
    end

    context 'folder entries' do
      
      before :each do
        @folder1 = FactoryBot.build :folder, user_id: @user.id
        
        @feed1 = FactoryBot.create :feed
        @feed2 = FactoryBot.create :feed
        @feed3 = FactoryBot.create :feed
  
        @user.subscribe @feed1.fetch_url
        @user.subscribe @feed2.fetch_url
        @user.subscribe @feed3.fetch_url
  
        @entry1_1 = FactoryBot.build :entry, feed_id: @feed1.id
        @entry1_2 = FactoryBot.build :entry, feed_id: @feed1.id
        @feed1.entries << @entry1_1 << @entry1_2
  
        @entry2_1 = FactoryBot.build :entry, feed_id: @feed2.id
        @entry2_2 = FactoryBot.build :entry, feed_id: @feed2.id
        @feed2.entries << @entry2_1 << @entry2_2
  
        @entry3_1 = FactoryBot.build :entry, feed_id: @feed3.id
        @entry3_2 = FactoryBot.build :entry, feed_id: @feed3.id
        @feed3.entries << @entry3_1 << @entry3_2
  
        @user.folders << @folder1
        @folder1.feeds << @feed1 << @feed2
      end

      it 'assigns to @entries the entries for all feeds in a single folder' do
        get :index, params: {folder_id: @folder1.id}
        expect(assigns(:entries).count).to eq 4
        expect(assigns(:entries)).to include @entry1_1
        expect(assigns(:entries)).to include @entry1_2
        expect(assigns(:entries)).to include @entry2_1
        expect(assigns(:entries)).to include @entry2_2
      end

      it 'assigns to @entries the entries for all subscribed feeds' do
        get :index, params: {folder_id: 'all'}
        expect(assigns(:entries).count).to eq 6
        expect(assigns(:entries)).to include @entry1_1
        expect(assigns(:entries)).to include @entry1_2
        expect(assigns(:entries)).to include @entry2_1
        expect(assigns(:entries)).to include @entry2_2
        expect(assigns(:entries)).to include @entry3_1
        expect(assigns(:entries)).to include @entry3_2
      end

      it 'returns a 404 for a folder that does not belong to the user' do
        folder2 = FactoryBot.create :folder
        get :index, params: {folder_id: folder2.id}
        expect(response.status).to eq 404
      end

      it 'returns a 404 for a non-existing folder' do
        get :index, params: {folder_id: 1234567890}
        expect(response.status).to eq 404
      end

      it 'does not fetch new entries for any feed' do
        expect(FeedClient).not_to receive(:fetch).with @feed1
        get :index, params: {folder_id: @folder1.id}
      end

      it 'assigns to @entries only unread folder entries by default' do
        @user.change_entries_state @entry1_1, 'read'

        get :index, params: {folder_id: @folder1.id}, format: :json
        expect(assigns(:entries).count).to eq 3
        expect(assigns(:entries)).to include @entry1_2
        expect(assigns(:entries)).to include @entry2_1
        expect(assigns(:entries)).to include @entry2_2
      end

      it 'assigns to @entries all folder entries' do
        @user.change_entries_state @entry1_1, 'read'

        get :index, params: {folder_id: @folder1.id, include_read: 'true'}, format: :json
        expect(assigns(:entries).count).to eq 4
        expect(assigns(:entries)).to include @entry1_1
        expect(assigns(:entries)).to include @entry1_2
        expect(assigns(:entries)).to include @entry2_1
        expect(assigns(:entries)).to include @entry2_2
      end

      it 'assigns to @entries only all unread entries by default' do
        @user.change_entries_state @entry1_1, 'read'

        get :index, params: {folder_id: 'all'}, format: :json
        expect(assigns(:entries).count).to eq 5
        expect(assigns(:entries)).to include @entry1_2
        expect(assigns(:entries)).to include @entry2_1
        expect(assigns(:entries)).to include @entry2_2
        expect(assigns(:entries)).to include @entry3_1
        expect(assigns(:entries)).to include @entry3_2
      end

      it 'assigns to @entries all entries' do
        @user.change_entries_state @entry1_1, 'read'

        get :index, params: {folder_id: 'all', include_read: 'true'}, format: :json
        expect(assigns(:entries).count).to eq 6
        expect(assigns(:entries)).to include @entry1_1
        expect(assigns(:entries)).to include @entry1_2
        expect(assigns(:entries)).to include @entry2_1
        expect(assigns(:entries)).to include @entry2_2
        expect(assigns(:entries)).to include @entry3_1
        expect(assigns(:entries)).to include @entry3_2
      end

      context 'pagination' do

        before :each do
          @entries = []

          # Ensure there are exactly 26 unread and 4 read entries in @folder1
          Entry.all.each {|e| e.destroy}
          (0..29).each do |i|
            e = FactoryBot.build :entry, feed_id: @feed1.id, published: Date.new(2001, 03, 30-i)
            @feed1.entries << e
            @entries << e
          end
          (26..29).each do |i|
            @user.change_entries_state @entries[i], 'read'
          end

          #Also there are 1 unread and 1 read entries in @feed3. which is not in any folder
          (30..31).each do |i|
            e = FactoryBot.build :entry, feed_id: @feed3.id, published: Date.new(2001, 01, 55-i)
            @feed3.entries << e
            @entries << e
          end
          @user.change_entries_state @entries[31], 'read'
        end

        context 'all feeds' do

          context 'unread entries' do

            it 'returns the first page of entries' do
              get :index, params: {folder_id: 'all', page: 1}, format: :json
              expect(assigns(:entries).count).to eq 25
              assigns(:entries).each_with_index do |entry, index|
                expect(entry).to eq @entries[index]
              end
            end

            it 'returns the last page of entries' do
              get :index, params: {folder_id: 'all', page: 2}, format: :json
              expect(assigns(:entries).count).to eq 2
              # In the second page of entries only one entry from @feed1 and one from @feed3 should appear
              expect(assigns(:entries)[0]).to eq @entries[25]
              expect(assigns(:entries)[1]).to eq @entries[30]
            end
          end

          context 'all entries' do

            it 'returns the first page of entries' do
              get :index, params: {folder_id: 'all', include_read: 'true', page: 1}, format: :json
              expect(assigns(:entries).count).to eq 25
              assigns(:entries).each_with_index do |entry, index|
                expect(entry).to eq @entries[index]
              end
            end

            it 'returns the last page of entries' do
              get :index, params: {folder_id: 'all', include_read: 'true', page: 2}, format: :json
              expect(assigns(:entries).count).to eq 7
              assigns(:entries).each_with_index do |entry, index|
                expect(entry).to eq @entries[25+index]
              end
            end
          end

        end

        context 'single folder' do

          context 'unread entries' do

            it 'returns the first page of entries' do
              get :index, params: {folder_id: @folder1.id, page: 1}, format: :json
              expect(assigns(:entries).count).to eq 25
              assigns(:entries).each_with_index do |entry, index|
                expect(entry).to eq @entries[index]
              end
            end

            it 'returns the last page of entries' do
              get :index, params: {folder_id: @folder1.id, page: 2}, format: :json
              expect(assigns(:entries).count).to eq 1
              expect(assigns(:entries)[0]).to eq @entries[25]
            end
          end

          context 'all entries' do

            it 'returns the first page of entries' do
              get :index, params: {folder_id: @folder1.id, include_read: 'true', page: 1}, format: :json
              expect(assigns(:entries).count).to eq 25
              assigns(:entries).each_with_index do |entry, index|
                expect(entry).to eq @entries[index]
              end
            end

            it 'returns the last page of entries' do
              get :index, params: {folder_id: @folder1.id, include_read: 'true', page: 2}, format: :json
              expect(assigns(:entries).count).to eq 5
              assigns(:entries).each_with_index do |entry, index|
                expect(entry).to eq @entries[25+index]
              end
            end
          end

        end

      end
    end
  end
end