module Chronatog
  module Server
    class Application < Sinatra::Base
      enable :raise_errors
      disable :dump_errors
      disable :show_exceptions

      ########################
      # Public Facing Web UI #
      ########################

      get "/" do
        "This is Chronatog, an example service."
      end

      get "/terms" do
        "Agree to our terms, or else..."
      end
      
      get '/customers' do
        @customers = Chronatog::Server::Customer.all
        haml :customer_list
      end
      
      get '/customers/:id' do
         @customer = Chronatog::Server::Customer.find(params[:id])
          haml :show
      end
      
      post '/customers/:id/bill' do
        
        @customer = Chronatog::Server::Customer.find(params[:id])
        if @customer
          
          line_item_description = params[:body] 
          amount = params[:amount]
        
          invoice = EY::ServicesAPI::Invoice.new(:total_amount_cents => amount,
                                               :line_item_description => line_item_description)
          
          Chronatog::EyIntegration.connection.send_invoice(@customer.invoices_url, invoice)
          
          @customer.last_billed_at = billing_at
          redirect_to '/customers/' + @customer.id
        end
      end
          
      
      get '/billit' do
         
            line_item_description = [
              "For service from #{last_billed_at.strftime('%Y/%m/%d')}",
              "to #{billing_at.strftime('%Y/%m/%d')}",
              "includes #{schedulers.size} schedulers", 
              "and #{total_jobs_ran} jobs run.",
            ].join(" ")

            
            

            self.last_billed_at = billing_at
      end

      get "/billall" do
        Chronatog::Server::Customer.all.each(&:bill!)
        
      end
      
      ##################
      # Actual Service #
      ##################

      post "/chronatogapi/1/jobs" do
        api_protected!
        job = jobs.create!(JSON.parse(request.body.read))
        status 201
        api_job(job).to_json
      end

      get "/chronatogapi/1/jobs" do
        api_protected!
        jobs.map{|j| api_job(j) }.to_json
      end

      get '/chronatogapi/1/jobs/:job_id' do |job_id|
        api_protected!
        api_job(jobs.find(job_id)).to_json
      end

      delete '/chronatogapi/1/jobs/:job_id' do |job_id|
        api_protected!
        jobs.find(job_id).destroy
      end

      ###################
      # Sinatra Helpers #
      ###################
      helpers do

        def api_job(job)
          {:callback_url => job.callback_url, :schedule => job.schedule, :url => "#{base_url}/chronatogapi/1/jobs/#{job.id}"}
        end

        def jobs
          @scheduler.jobs
        end

        def api_protected!
          unless api_authorized?
            response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
            throw(:halt, [401, "Not authorized\n"])
          end
        end

        def api_authorized?
          @auth ||=  Rack::Auth::Basic::Request.new(request.env)
          if @auth.provided? && @auth.basic? && @auth.credentials
            username, password = @auth.credentials
            if @scheduler = Scheduler.find_by_auth_username(username)
              @scheduler.auth_password == password
            end
          end
        end

        def base_url
          uri = URI.parse(request.url)
          uri.to_s.gsub(uri.request_uri, '')
        end

      end
    end
  end
end