require 'sinatra'
require 'csv'
require 'slim'

get '/' do
	$memberlist = nil
	slim :index
end

get '/pairings' do
	slim :pairings
end

get '/membernames' do
	if $membernames
		slim :membernames
	else
		$error = "You have not submitted any names yet"
		slim :index
	end
end

post '/' do
	if params[:memberlist]
		$memberlist = CSV.read(params[:memberlist][:tempfile])
		if params[:exclusionlist]
			$exclusionlist = CSV.read(params[:exclusionlist][:tempfile])
		end
	slim :pairings
	else slim :index
	end
end

post '/membernames' do
		if params[:newname]
			$memberlist << params[:newname]
		end
		slim :membernames
end

