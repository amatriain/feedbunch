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
        within 'div.hopscotch-bubble' do
          page.should have_text 'My header'
        end
      end

      it 'does not show the tour after finishing it'

      it 'does not show the tour after forcibly closing it'

    end

    context 'returning users' do


      it 'does not show the tour'

      it 'starts the tour again'
    end
  end
end