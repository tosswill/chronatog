require File.join( File.dirname(__FILE__), "spec_helper" )

describe "customers" do
  include_context "ey integration reset"

  context "with the service registered" do
    before do
      # Chronatog::EyIntegration.save_creds(@mock_backend.partner[:auth_id], @mock_backend.partner[:auth_key])
      base_url = "http://chronatog.local"
      @service = Chronatog::EyIntegration.register_service(@mock_backend.partner[:registration_url], base_url)
    end

    describe "with a customer" do
      before do
        @mock_backend.create_service_account
        @customer = @service.reload.customers.first
      end

      describe "when provisioned" do
        before do
          @mock_backend.create_provisioned_service
        end

        it "creates a scheduler" do
          @customer.schedulers.reload.size.should eq 1
          @scheduler = @customer.schedulers.reload.first

          @scheduler.should_not be_nil
          @scheduler.decomissioned_at.should be_nil
          #TODO: assert more on the scheduler
        end

        it "can handle a delete" do
          @mock_backend.destroy_provisioned_service
          @customer.reload

          @scheduler = @customer.schedulers.reload.first
          @scheduler.decomissioned_at.should_not be_nil
        end
      end
    end

  end

end