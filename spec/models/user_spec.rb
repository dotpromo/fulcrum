require 'spec_helper'

describe User, type: :model do

  describe 'validations' do
    it 'requires a name' do
      subject.name = ''
      subject.valid?
      expect(subject.errors[:name].size).to eq(1)
    end

    it 'requires initials' do
      subject.initials = ''
      subject.valid?
      expect(subject.errors[:initials].size).to eq(1)
    end

  end

  describe '#to_s' do

    subject do
      FactoryGirl.build(:user, name: 'Dummy User', initials: 'DU',
                                    email: 'dummy@example.com')
    end

    describe '#to_s' do
      subject { super().to_s }
      it { is_expected.to eq('Dummy User (DU) <dummy@example.com>') }
    end

  end

  describe '#as_json' do

    before do
      subject.id = 42
    end

    specify do
      expect(subject.as_json['user'].keys.sort).to eq(%w(      email id initials name      ))
    end

  end

end
