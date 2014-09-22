require 'spec_helper'

describe StoryObserver, type: :model do

  subject { StoryObserver.instance }

  let(:story) do
    mock_model(Story, :changesets     => double('changesets'),
                      :state_changed?        => false,
                      :accepted_at_changed?  => false)
  end

  # FIXME - Better coverage needed
  describe '#after_save' do

    before do
      # Should always create a changeset
      expect(story.changesets).to receive(:create!)
    end

    context 'when story state changed' do

      let(:project) { mock_model(Project) }

      before do
        allow(project).to receive(:suppress_notifications).and_return(false)
        allow(story).to receive(:state_changed?).and_return(true)
        allow(story).to receive(:project).and_return(project)
      end

      context 'when project start date is not set' do

        before do
          allow(project).to receive(:state).and_return('started')
        end

        it 'sets the project start date' do
          expect(project).to receive(:update_attribute).with(:start_date, Date.today)
          subject.after_save(story)
        end

      end

      describe 'notifications' do

        let(:acting_user)   { mock_model(User) }
        let(:requested_by)  { mock_model(User, :email_delivery? => true) }
        let(:owned_by)      do
          mock_model(User, :email_acceptance? => true,
                           :email_rejection? => true)
        end
        let(:notifier)      { double('notifier') }

        before do
          allow(story).to receive(:acting_user).and_return(acting_user)
          allow(story).to receive(:requested_by).and_return(requested_by)
          allow(story).to receive(:owned_by).and_return(owned_by)
          allow(project).to receive(:start_date).and_return(true)
          expect(notifier).to receive(:deliver)
        end

        it "sends 'delivered' email notification" do
          allow(story).to receive(:state).and_return('delivered')
          expect(Notifications).to receive(:delivered).with(story, acting_user) {
            notifier
          }
          subject.after_save(story)
        end
        it "sends 'accepted' email notification" do
          allow(story).to receive(:state).and_return('accepted')
          expect(Notifications).to receive(:accepted).with(story, acting_user) {
            notifier
          }
          subject.after_save(story)
        end
        it "sends 'rejected' email notification" do
          allow(story).to receive(:state).and_return('rejected')
          expect(Notifications).to receive(:rejected).with(story, acting_user) {
            notifier
          }
          subject.after_save(story)
        end
      end

    end

  end

end
