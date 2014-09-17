require 'rails_helper'

describe 'application tours', type: :feature do

  before :each do
    @user = FactoryGirl.create :user
  end

  context 'main application tour' do

    context 'first time users' do

      before :each do
        @user.update show_main_tour: true
        login_user_for_feature @user
      end

      it 'shows the tour', js: true do
        tour_should_be_visible 'Start'
      end

      it 'does not show the tour after completing it', js: true do
        while page.has_css? '.hopscotch-next'
          find('.hopscotch-next').click
        end
        tour_should_not_be_visible

        visit read_path
        # wait for client code to initialize
        sleep 1
        tour_should_not_be_visible
      end

      it 'does not show the tour after closing it', js: true do
        tour_should_be_visible
        find('.hopscotch-close').click
        tour_should_not_be_visible

        visit read_path
        # wait for client code to initialize
        sleep 1
        tour_should_not_be_visible
      end

      it 'shows an alert if it cannot load the tour from the server', js: true do
        allow_any_instance_of(Api::TourI18nsController).to receive(:render).and_raise StandardError.new

        visit read_path
        should_show_alert 'problem-loading-tour'
      end

      it 'shows an alert if an error happens when telling the server that the tour completed', js: true do
        pending
        allow_any_instance_of(User).to receive(:update).and_raise ActiveRecord::RecordNotFound.new

        while page.has_css? '.hopscotch-next'
          find('.hopscotch-next').click
        end
        tour_should_not_be_visible
        should_show_alert 'problem-show-tour-change'
      end

      it 'shows an alert if an error happens when telling the server that the tour has been closed'

    end

    context 'returning users' do

      it 'does not show the tour'

      it 'starts the tour again'
    end
  end
end