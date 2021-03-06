# frozen_string_literal: true

require 'rails_helper'

describe SurveysController do
  let!(:event) { create(:event, title: 'The Best Railsbridge') }
  let!(:user) { create(:user) }
  let!(:rsvp) { create(:volunteer_rsvp, user: user, event: event) }

  describe 'when signed in' do
    before do
      sign_in user
    end

    describe '#new' do
      it 'shows the survey form' do
        get :new, params: { event_id: event.id, rsvp_id: rsvp.id }
        expect(response).to render_template(:new)
        expect(assigns(:event)).to eq event
        expect(assigns(:rsvp)).to eq rsvp
      end

      it 'shows the survey form when only an event_id is provided' do
        get :new, params: { event_id: event.id }
        expect(response).to render_template(:new)
        expect(assigns(:event)).to eq event
        expect(assigns(:rsvp)).to eq rsvp
      end

      describe 'for an invalid RSVP' do
        let(:destroyed_rsvp_id) { rsvp.id }

        before do
          rsvp.destroy
        end

        it 'redirects to the event with an error' do
          get :new, params: { event_id: event.id, rsvp_id: destroyed_rsvp_id }
          expect(response).to redirect_to(event_path(event))
          expect(flash[:error]).to be_present
        end
      end

      context 'if the survey has already been taken' do
        before do
          Survey.create(rsvp_id: rsvp.id)
        end

        it 'shows a warning message' do
          get :new, params: { event_id: event.id, rsvp_id: rsvp.id }
          expect(flash[:error]).not_to be_nil
        end
      end

      context "if the user is try to take a survey that isn't theirs" do
        let(:other_rsvp) do
          other_user = create(:user)
          create(:rsvp, user: other_user)
        end

        it 'takes the survey for the logged-in user instead' do
          get :new, params: { event_id: event.id, rsvp_id: other_rsvp.id }
          expect(assigns(:rsvp).user).to eq(user)
        end
      end
    end

    describe '#create' do
      context 'with good params' do
        it 'makes the survey' do
          params = {
            event_id: event.id,
            rsvp_id: rsvp.id,
            survey: {
              good_things: 'Ruby',
              bad_things: 'Moar cake',
              other_comments: 'Superfun',
              recommendation_likelihood: '9'
            }
          }

          expect { put :create, params: params }.to change(Survey, :count).by(1)
        end
      end

      context "if the user is try to take a survey that isn't theirs" do
        let(:other_rsvp) do
          other_user = create(:user)
          create(:rsvp, user: other_user)
        end

        it 'creates a survey for the logged-in user' do
          params = {
            event_id: event.id,
            rsvp_id: other_rsvp.id,
            survey: {
              good_things: 'Ruby',
              bad_things: 'Moar cake',
              other_comments: 'Superfun',
              recommendation_likelihood: '9'
            }
          }
          expect { put :create, params: params }.to change(Survey, :count).by(1)
          expect(Survey.last.rsvp.user).to eq(user)
        end
      end
    end
  end

  describe '#index' do
    context 'as the organizer' do
      before do
        organizer = create(:user)
        event.organizers << organizer
        create(:survey, rsvp: rsvp)
        sign_in organizer
      end

      it 'shows the survey results' do
        get :index, params: { event_id: event.id }
        expect(response).to be_successful
        expect(assigns(:event)).to eq event
        expect(assigns(:event).volunteer_surveys.to_a).to eq [rsvp.survey]
      end
    end

    context 'as someone who is not the organizer' do
      before do
        sign_in user
      end

      it "doesn't show the survey results" do
        get :index, params: { event_id: event.id }
        expect(response.code).to eq '302'
      end
    end
  end
end
