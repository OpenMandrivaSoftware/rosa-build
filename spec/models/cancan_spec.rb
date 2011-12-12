require 'spec_helper'
require "cancan/matchers"

def admin_create
	@admin = Factory(:admin)
  @ability = Ability.new(@admin)
end

def user_create
	@user = Factory(:user)
  @ability = Ability.new(@user)
end

def guest_create
  @ability = Ability.new(User.new)
end

describe CanCan do

	let(:personal_platform) { Factory(:platform, :platform_type => 'personal') }
	let(:personal_repository) { Factory(:personal_repository) }
	let(:open_platform) { Factory(:platform, :visibility => 'open') }
	let(:hidden_platform) { Factory(:platform, :visibility => 'hidden') }

  before(:each) do
    stub_rsync_methods
  end

	context 'Site admin' do
		before(:each) do
			admin_create
		end
		
		it 'should manage all' do
			#(@ability.can? :manage, :all).should be_true
			@ability.should be_able_to(:manage, :all)
		end

		it 'should not be able to destroy personal platforms' do
			@ability.should_not be_able_to(:destroy, personal_platform)
		end

		it 'should not be able to destroy personal repositories' do
			@ability.should_not be_able_to(:destroy, personal_repository)
		end
	end

	context 'Site guest' do
		before(:each) do
			guest_create
		end

		it 'should be able to read open platform' do
			@ability.should be_able_to(:read, open_platform)
		end

		it 'should not be able to read hidden platform' do
			@ability.should_not be_able_to(:read, hidden_platform)
		end

		it 'should be able to auto build projects' do
			@ability.should be_able_to(:auto_build, Project)
		end

		[:status_build, :pre_build, :post_build, :circle_build, :new_bbdt].each do |action|
			it "should be able to #{ action } build list" do
				@ability.should be_able_to(action, BuildList)
			end
		end

		it 'should be able to register new user' do
			@ability.should be_able_to(:create, User)
		end
	end

  context 'Site user' do
    before(:each) do
      user_create
    end

    [Platform, User, Repository].each do |model_name|
      it "should not be able to create #{ model_name.to_s }" do
        @ability.should be_able_to(:read, model_name)
      end
    end

    it "shoud be able to read another user object" do
      admin_create
      @ability.should be_able_to(:read, @admin)
    end

    it "shoud be able to read index AutoBuildList" do
      @ability.should be_able_to(:index, AutoBuildList)
    end

    it "shoud be able to read open projects" do
      @project = Factory(:project, :visibility => 'open')
      @ability.should be_able_to(:read, @project)
    end

    it "shoud be able to create project" do
      @ability.should be_able_to(:create, Project)
    end

    context "private users relations" do
      before(:each) do
        @private_user = Factory(:private_user)
        @private_user.platform.update_attribute(:owner, @user)
      end

      [:read, :create].each do |action|
        it "should be able to #{ action } PrivateUser" do
          @ability.should be_able_to(action, @private_user) 
        end
      end
    end

    context 'as project collaborator' do
      before(:each) do
        @project = Factory(:project)
      end

      context 'with read rights' do
        before(:each) do
          @project.relations.create!(:object_id => @user.id, :object_type => 'User', :role => 'reader')
        end

        it 'should be able to read project' do
          @ability.should be_able_to(:read, @project)
        end
        
        it 'should be able to read project' do
          @ability.should be_able_to(:read, open_platform)
        end
      end
      
      context 'with write rights' do
        before(:each) do
          @project.relations.create!(:object_id => @user.id, :object_type => 'User', :role => 'writer')
        end

        [:read, :update, :process_build, :build].each do |action|
          it "should be able to #{ action } project" do
            @ability.should be_able_to(action, @project)
          end
        end
      end

      context 'with admin rights' do
        before(:each) do
          @project.relations.create!(:object_id => @user.id, :object_type => 'User', :role => 'admin')
        end

        [:read, :update, :process_build, :build].each do |action|
          it "should be able to #{ action } project" do
            @ability.should be_able_to(action, @project)
          end
        end

        it "should be able to manage collaborators of project" do
          @ability.should be_able_to(:manage_collaborators, @project)
        end
      end

      context 'with owner rights' do
        before(:each) do
          @project.update_attribute(:owner, @user)
        end

        [:read, :update, :process_build, :build, :destroy].each do |action|
          it "should be able to #{ action } project" do
            @ability.should be_able_to(action, @project)
          end
        end
      end

    end

    context 'platform relations' do
      before(:each) do
        @platform = Factory(:platform)
      end

      context 'with owner rights' do
        before(:each) do
          @platform.update_attribute(:owner, @user)
        end

        it 'should be able to manage platform' do
          @ability.should be_able_to(:manage, @platform)
        end
      end

      context 'with read rights' do
        before(:each) do
          @platform.relations.create!(:object_id => @user.id, :object_type => 'User', :role => 'reader')
        end

        it "should be able to read platform" do
          @ability.should be_able_to(:read, @platform)
        end
      end
    end

    context 'repository relations' do
      before(:each) do
        @repository = Factory(:repository)
      end

      context 'with owner rights' do
        before(:each) do
          @repository.update_attribute(:owner, @user)
        end

        [:manage, :add_project, :remove_project, :change_visibility, :settings].each do |action|
          it 'should be able to #{ action } repository' do
            @ability.should be_able_to(action, @repository)
          end
        end
      end

      context 'with read rights' do
        before(:each) do
          @repository.relations.create!(:object_id => @user.id, :object_type => 'User', :role => 'reader')
        end

        it "should be able to read repository" do
          @ability.should be_able_to(:read, @repository)
        end
      end
    end

    context 'build list relations' do
      before(:each) do
        @project = Factory(:project)
        @project.relations.create!(:object_id => @user.id, :object_type => 'User', :role => 'reader')
        @build_list = Factory(:build_list, :project => @project)
      end

      it 'should be able to publish build list with SUCCESS status' do
        @build_list.status = BuildServer::SUCCESS
        @ability.should be_able_to(:publish, @build_list)
      end

      it 'should not be able to publish build list with another status' do
        @build_list.status = BuildServer::BUILD_ERROR
        @ability.should_not be_able_to(:publish, @build_list)
      end
    end
  end


end
