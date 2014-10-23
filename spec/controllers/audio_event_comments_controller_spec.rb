# require 'spec_helper'
#
# # This spec was generated by rspec-rails when you ran the scaffold generator.
# # It demonstrates how one might use RSpec to specify the controller code that
# # was generated by Rails when you ran the scaffold generator.
# #
# # It assumes that the implementation code is generated by the rails scaffold
# # generator.  If you are using any extension libraries to generate different
# # controller code, this generated spec may or may not pass.
# #
# # It only uses APIs available in rails and/or rspec-rails.  There are a number
# # of tools you can use to make these specs even more expressive, but we're
# # sticking to rails and rspec-rails APIs to keep things simple and stable.
# #
# # Compared to earlier versions of this generator, there is very limited use of
# # stubs and message expectations in this spec.  Stubs are only used when there
# # is no simpler way to get a handle on the object needed for the example.
# # Message expectations are only used when there is no simpler way to specify
# # that an instance is receiving a specific message.
#
# describe AudioEventCommentsController do
#
#   # This should return the minimal set of attributes required to create a valid
#   # AudioEventComment. As you add validations to AudioEventComment, be sure to
#   # adjust the attributes here as well.
#   let(:valid_attributes) { { comment: 'my comment', audio_event_id: 1 } }
#
#   # This should return the minimal set of values that should be in the session
#   # in order to pass any filters (e.g. authentication) defined in
#   # AudioEventCommentsController. Be sure to keep this updated too.
#   let(:valid_session) { {} }
#
#   describe "GET index" do
#     it "assigns all audio_event_comments as @audio_event_comments" do
#       audio_event_comment = AudioEventComment.create! valid_attributes
#       get :index, {}, valid_session
#       assigns(:audio_event_comments).should eq([audio_event_comment])
#     end
#   end
#
#   describe "GET show" do
#     it "assigns the requested audio_event_comment as @audio_event_comment" do
#       audio_event_comment = AudioEventComment.create! valid_attributes
#       get :show, {:id => audio_event_comment.to_param}, valid_session
#       assigns(:audio_event_comment).should eq(audio_event_comment)
#     end
#   end
#
#   describe "GET new" do
#     it "assigns a new audio_event_comment as @audio_event_comment" do
#       get :new, {}, valid_session
#       assigns(:audio_event_comment).should be_a_new(AudioEventComment)
#     end
#   end
#
#   describe "GET edit" do
#     it "assigns the requested audio_event_comment as @audio_event_comment" do
#       audio_event_comment = AudioEventComment.create! valid_attributes
#       get :edit, {:id => audio_event_comment.to_param}, valid_session
#       assigns(:audio_event_comment).should eq(audio_event_comment)
#     end
#   end
#
#   describe "POST create" do
#     describe "with valid params" do
#       it "creates a new AudioEventComment" do
#         expect {
#           post :create, {:audio_event_comment => valid_attributes}, valid_session
#         }.to change(AudioEventComment, :count).by(1)
#       end
#
#       it "assigns a newly created audio_event_comment as @audio_event_comment" do
#         post :create, {:audio_event_comment => valid_attributes}, valid_session
#         assigns(:audio_event_comment).should be_a(AudioEventComment)
#         assigns(:audio_event_comment).should be_persisted
#       end
#
#       it "redirects to the created audio_event_comment" do
#         post :create, {:audio_event_comment => valid_attributes}, valid_session
#         response.should redirect_to(AudioEventComment.last)
#       end
#     end
#
#     describe "with invalid params" do
#       it "assigns a newly created but unsaved audio_event_comment as @audio_event_comment" do
#         # Trigger the behavior that occurs when invalid params are submitted
#         AudioEventComment.any_instance.stub(:save).and_return(false)
#         post :create, {:audio_event_comment => {  }}, valid_session
#         assigns(:audio_event_comment).should be_a_new(AudioEventComment)
#       end
#
#       it "re-renders the 'new' template" do
#         # Trigger the behavior that occurs when invalid params are submitted
#         AudioEventComment.any_instance.stub(:save).and_return(false)
#         post :create, {:audio_event_comment => {  }}, valid_session
#         response.should render_template("new")
#       end
#     end
#   end
#
#   describe "PUT update" do
#     describe "with valid params" do
#       it "updates the requested audio_event_comment" do
#         audio_event_comment = AudioEventComment.create! valid_attributes
#         # Assuming there are no other audio_event_comments in the database, this
#         # specifies that the AudioEventComment created on the previous line
#         # receives the :update_attributes message with whatever params are
#         # submitted in the request.
#         AudioEventComment.any_instance.should_receive(:update_attributes).with({ "these" => "params" })
#         put :update, {:id => audio_event_comment.to_param, :audio_event_comment => { "these" => "params" }}, valid_session
#       end
#
#       it "assigns the requested audio_event_comment as @audio_event_comment" do
#         audio_event_comment = AudioEventComment.create! valid_attributes
#         put :update, {:id => audio_event_comment.to_param, :audio_event_comment => valid_attributes}, valid_session
#         assigns(:audio_event_comment).should eq(audio_event_comment)
#       end
#
#       it "redirects to the audio_event_comment" do
#         audio_event_comment = AudioEventComment.create! valid_attributes
#         put :update, {:id => audio_event_comment.to_param, :audio_event_comment => valid_attributes}, valid_session
#         response.should redirect_to(audio_event_comment)
#       end
#     end
#
#     describe "with invalid params" do
#       it "assigns the audio_event_comment as @audio_event_comment" do
#         audio_event_comment = AudioEventComment.create! valid_attributes
#         # Trigger the behavior that occurs when invalid params are submitted
#         AudioEventComment.any_instance.stub(:save).and_return(false)
#         put :update, {:id => audio_event_comment.to_param, :audio_event_comment => {  }}, valid_session
#         assigns(:audio_event_comment).should eq(audio_event_comment)
#       end
#
#       it "re-renders the 'edit' template" do
#         audio_event_comment = AudioEventComment.create! valid_attributes
#         # Trigger the behavior that occurs when invalid params are submitted
#         AudioEventComment.any_instance.stub(:save).and_return(false)
#         put :update, {:id => audio_event_comment.to_param, :audio_event_comment => {  }}, valid_session
#         response.should render_template("edit")
#       end
#     end
#   end
#
#   describe "DELETE destroy" do
#     it "destroys the requested audio_event_comment" do
#       audio_event_comment = AudioEventComment.create! valid_attributes
#       expect {
#         delete :destroy, {:id => audio_event_comment.to_param}, valid_session
#       }.to change(AudioEventComment, :count).by(-1)
#     end
#
#     it "redirects to the audio_event_comments list" do
#       audio_event_comment = AudioEventComment.create! valid_attributes
#       delete :destroy, {:id => audio_event_comment.to_param}, valid_session
#       response.should redirect_to(audio_event_comments_url)
#     end
#   end
#
# end
