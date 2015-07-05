require 'sinatra'
require 'csv'
require 'slim'

def randomise(names)
	pairings = Array.new
	while names.length > 1
		a = names.sample
		names = names - [a]
		b = names.sample
		names = names - [b]
		pairings << [a,b]
	end
	if names.length == 1
		$spare = names
	else
		$spare = nil
	end
	return pairings
end

get '/' do
	$memberlist = nil
	slim :index
end

get '/pairings' do
	slim :pairings
end

get '/membernames' do
	if $memberlist
		slim :membernames
	else
		$error = "You have not submitted any names yet"
		slim :index
	end
end

get '/exclusions' do
	slim :exclusions
end

post '/' do
	if params[:memberlist]
		$memberlist = CSV.read(params[:memberlist][:tempfile])
		if params[:exclusionlist]
			$exclusionlist = CSV.read(params[:exclusionlist][:tempfile])
		end
#		$pairings = randomise($memberlist)
		slim :pairings
	else slim :index
	end
end

post '/pairings' do
	$pairings = randomise($memberlist)
	slim :pairings
end

post '/membernames' do
		if params[:newname]
			$memberlist << params[:newname]
		end
		slim :membernames
end

post '/exclusions' do
	if params[:exclusionA] && params[:exclusionB]
		$exclusionlist << [params[:exclusionA],params[:exclusionB]]
	end
	slim :exclusions
end
