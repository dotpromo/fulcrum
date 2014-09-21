require 'spec_helper'

describe Notifications, :type => :mailer do

  let(:requested_by) { mock_model(User) }
  let(:owned_by) { mock_model(User) }
  let(:project) { mock_model(Project, :name => 'Test Project') }
  let(:story) do
    mock_model(Story, :title => 'Test story', :requested_by => requested_by,
                      :owned_by => owned_by, :project => project)
  end

  describe "#delivered" do

    let(:delivered_by) { mock_model(User, :name => 'Deliverer') }

    subject  { Notifications.delivered(story, delivered_by) }

    describe '#subject' do
      subject { super().subject }
      it { is_expected.to eq("[Test Project] Your story 'Test story' has been delivered for acceptance.") }
    end

    describe '#to' do
      subject { super().to }
      it { [requested_by.email] }
    end

    describe '#from' do
      subject { super().from }
      it { [delivered_by.email] }
    end

    specify { expect(subject.body.encoded).to match("Deliverer has delivered your story 'Test story'.") }
    specify { expect(subject.body.encoded).to match("You can now review the story, and either accept or reject it.") }
    specify { expect(subject.body.encoded).to match(project_url(project)) }

  end

  describe "#accepted" do

    let(:accepted_by) { mock_model(User, :name => 'Accepter') }

    subject  { Notifications.accepted(story, accepted_by) }

    describe '#subject' do
      subject { super().subject }
      it { is_expected.to eq("[Test Project] Accepter ACCEPTED your story 'Test story'.") }
    end

    describe '#to' do
      subject { super().to }
      it { [owned_by.email] }
    end

    describe '#from' do
      subject { super().from }
      it { [accepted_by.email] }
    end

    specify { expect(subject.body.encoded).to match("Accepter has accepted the story 'Test story'.") }
    specify { expect(subject.body.encoded).to match(project_url(project)) }

  end

  describe "#rejected" do

    let(:rejected_by) { mock_model(User, :name => 'Rejecter') }

    subject  { Notifications.rejected(story, rejected_by) }

    describe '#subject' do
      subject { super().subject }
      it { is_expected.to eq("[Test Project] Rejecter REJECTED your story 'Test story'.") }
    end

    describe '#to' do
      subject { super().to }
      it { [owned_by.email] }
    end

    describe '#from' do
      subject { super().from }
      it { [rejected_by.email] }
    end

    specify { expect(subject.body.encoded).to match("Rejecter has rejected the story 'Test story'.") }
    specify { expect(subject.body.encoded).to match(project_url(project)) }

  end

  describe "#new_note" do

    let(:notify_users)  { [mock_model(User, :email => 'foo@example.com')] }
    let(:user)          { mock_model(User, :name => 'Note User') }
    let(:note)          { mock_model(Note, :story => story, :user => user) }

    subject { Notifications.new_note(note, notify_users) }

    describe '#subject' do
      subject { super().subject }
      it { is_expected.to eq("[Test Project] New comment on 'Test story'") }
    end

    describe '#to' do
      subject { super().to }
      it { ['foo@example.com'] }
    end

    describe '#from' do
      subject { super().from }
      it { [user.email] }
    end

    specify { expect(subject.body.encoded).to match("Note User added the following comment to the story") }
  end
end
