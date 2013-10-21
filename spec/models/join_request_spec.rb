require 'spec_helper'

describe JoinRequest do

  it "belongs to candidate"
  it "belongs to introducer"
  it "belongs to group"
  it "has one role"

  it { should validate_presence_of(:email) }
  it "validates format of email"

  it { should respond_to(:"processed=") }
  it "sets processed_at when the model is saved with processed==true"
  it "validates uniqueness of candidate_id"
  it "validates uniqueness of email"

  it "throws an error if the candidate is the introducer"

  describe "#processed?" do
    let(:target) { FactoryGirl.create(:join_request) }

    context "if processed_at is set" do
      before { target.update_attributes(:processed_at => Time.now.utc) }
      it { target.processed?.should be_true }
    end

    context "if processed_at is not set" do
      before { target.update_attributes(:processed_at => nil) }
      it { target.processed?.should be_false }
    end
  end

  describe "#recently_processed?" do
    let(:target) { FactoryGirl.create(:join_request) }

    context "if processed is set" do
      before { target.processed = Time.now.utc }
      it { target.recently_processed?.should be_true }
    end

    context "if processed_at is not set" do
      before { target.processed = nil }
      it { target.recently_processed?.should be_false }
    end
  end

  describe "#role" do
    it "returns the role associated with the join request"
  end

  describe "#event?" do
    context "if group is an Event" do
      let(:target) { FactoryGirl.create(:event_join_request) }
      it { target.event?.should be_true }
    end

    context "if group is not an Event" do
      let(:target) { FactoryGirl.create(:space_join_request) }
      it { target.event?.should be_false }
    end
  end

  describe "#space?" do
    context "if group is a Space" do
      let(:target) { FactoryGirl.create(:space_join_request) }
      it { target.space?.should be_true }
    end

    context "if group is not a Space" do
      let(:target) { FactoryGirl.create(:event_join_request) }
      it { target.space?.should be_false }
    end
  end

  # TODO: test abilities when the join request is for an Event
  describe "abilities", :abilities => true do
    subject { ability }
    let(:ability) { Abilities.ability_for(user) }
    let(:target) { FactoryGirl.create(:space_join_request) }

    context "when is an anonymous user" do
      let(:user) { User.new }

      context "in a public space" do
        before { target.group.update_attributes(:public => true) }
        it { should_not be_able_to_do_anything_to(target) }
      end

      context "in a private space" do
        before { target.group.update_attributes(:public => false) }
        it { should_not be_able_to_do_anything_to(target) }
      end
    end

    context "when is a registered user" do
      let(:user) { FactoryGirl.create(:user) }

      context "in a public space" do
        before { target.group.update_attributes(:public => true) }

        context "he is not a member of" do
          it { should_not be_able_to_do_anything_to(target).except(:create) }
        end

        context "he is a member of" do
          context "with the role 'Admin'" do
            before { target.group.add_member!(user, "Admin") }
            it { should_not be_able_to_do_anything_to(target).except(:destroy) }
          end

          context "with the role 'User'" do
            before { target.group.add_member!(user, "User") }
            it { should_not be_able_to_do_anything_to(target) }
          end
        end
      end

      context "in a private space" do
        before { target.group.update_attributes(:public => false) }

        context "he is not a member of" do
          it { should_not be_able_to_do_anything_to(target).except(:create) }
        end

        context "he is a member of" do
          context "with the role 'Admin'" do
            before { target.group.add_member!(user, "Admin") }
            it { should_not be_able_to_do_anything_to(target).except(:destroy) }
          end

          context "with the role 'User'" do
            before { target.group.add_member!(user, "User") }
            it { should_not be_able_to_do_anything_to(target) }
          end
        end
      end
    end

    context "when is a superuser" do
      let(:user) { FactoryGirl.create(:superuser) }

      context "in a public space" do
        before { target.group.update_attributes(:public => true) }
        it { should be_able_to(:manage, target) }
      end

      context "in a private space" do
        before { target.group.update_attributes(:public => false) }
        it { should be_able_to(:manage, target) }
      end
    end
  end

end
