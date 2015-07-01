require 'sinatra'
require 'csv'
require 'slim'

get '/' do
	slim :index
end

get '/membernames' do
		slim :membernames
end

post '/' do
	if params[:memberlist]
		@memberlist = CSV.read(params[:memberlist][:tempfile])
		if params[:exclusionlist]
			@exclusionlist = CSV.read(params[:exclusionlist][:tempfile])
		end
	slim :membernames
	else slim :index
	end
end

post '/membernames' do
		if params[:newname]
			@memberlist << params[:newname]
		end
		slim :membernames
end

