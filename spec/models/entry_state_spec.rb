require 'spec_helper'

describe EntryState do

  before :each do
    @entry_state = FactoryGirl.create :entry_state
  end

  context 'validations' do

    it 'does not accept empty user' do
      entry_state = FactoryGirl.build :entry_state, user_id: nil
      entry_state.valid?.should be_false
    end

    it 'does not accept empty entry' do
      entry_state = FactoryGirl.build :entry_state, entry_id: nil
      entry_state.valid?.should be_false
    end

    it 'does not accept empty state' do
      entry_state = FactoryGirl.build :entry_state, read: nil
      entry_state.valid?.should be_false
    end

    it 'does not accept multiple states for the same entry and user' do
      entry_state = FactoryGirl.create :entry_state
      entry_state_dupe = FactoryGirl.build :entry_state, entry_id: entry_state.entry.id, user_id: entry_state.user.id
      entry_state_dupe.should_not be_valid
    end

    it 'accepts multiple states for the same entry and different users' do
      user2 = FactoryGirl.create :user
      entry_state1 = FactoryGirl.create :entry_state
      entry_state2 = FactoryGirl.build :entry_state, entry_id: entry_state1.entry.id, user_id: user2.id
      entry_state2.should be_valid
    end

    it 'accepts multiple states for different entries and the same user' do
      entry2 = FactoryGirl.create :entry
      entry_state1 = FactoryGirl.create :entry_state
      entry_state2 = FactoryGirl.build :entry_state, entry_id: entry2.id, user_id: entry_state1.user.id
      entry_state2.should be_valid
    end
  end
end
