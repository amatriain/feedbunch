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
  end
end
