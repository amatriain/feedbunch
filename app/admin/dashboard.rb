ActiveAdmin.register_page "Dashboard" do

  menu :priority => 1, :label => proc{ I18n.t('active_admin.dashboard') }

  content :title => proc{ I18n.t('active_admin.dashboard') } do

    columns do
      column do
        panel 'General info' do
          ul do
            li "#{User.count} users"
            li "#{Feed.count} feeds"
            li "#{Entry.count} entries"
            li "#{Folder.count} folders"
          end
        end
      end
      column do
        panel 'Failing feeds info' do
          ul do
            li "#{Feed.where(available: true).where.not(failing_since: nil).count} feeds currently failing"
            li "#{Feed.where(available: false).count} permanently unavailable feeds"
          end
        end
      end
    end

    columns do
      column do
        panel 'Recently failing feeds' do
          ul do
            Feed.where(available: true).where.not(failing_since: nil).order('failing_since DESC').limit(10).map do |feed|
              li link_to("#{feed.title} (since  #{feed.failing_since})", admin_feed_path(feed))
            end
          end
        end
      end
      column do
        panel 'Recent permanently unavailable feeds' do
          ul do
            Feed.where(available: false).order('updated_at DESC').limit(10).map do |feed|
              li link_to("#{feed.title} (since #{feed.updated_at})", admin_feed_path(feed))
            end
          end
        end
      end
    end

    columns do
      column do
        panel 'Recent confirmed users' do
          ul do
            User.where('confirmed_at is not null').order('created_at DESC').limit(10).map do |user|
              li link_to("#{user.name} (#{user.email})", admin_user_path(user))
            end
          end
        end
      end
      column do
        panel 'Recently added feeds' do
          ul do
            Feed.order('created_at DESC').limit(10).map do |feed|
              li link_to("#{feed.title} (#{feed.fetch_url})", admin_feed_path(feed))
            end
          end
        end
      end
    end

    columns do
      column do
       panel 'Recent signed up unconfirmed users' do
         ul do
           User.where('confirmed_at is null AND invitation_created_at is null').order('created_at DESC').limit(10).map do |user|
             li link_to("#{user.name} (#{user.email})", admin_user_path(user))
           end
         end
       end
      end
      column do
        panel 'Recent invited unconfirmed users' do
          ul do
            User.where('confirmed_at is null AND invitation_created_at is not null').order('created_at DESC').limit(10).map do |user|
              li link_to("#{user.name} (#{user.email})", admin_user_path(user))
            end
          end
        end
      end
    end

  end
end
