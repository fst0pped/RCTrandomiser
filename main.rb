require 'sinatra'
require 'csv'
require 'slim'

def excludeprevious(name,members,excludes)
	notexcluded = members.delete_if { |x| excludes.include?(name.last) or excludes.include?(name.fist) }
	return notexcluded
end

def randomise(names, excludes)
	pairings = Array.new
	while names.length > 1
		a = names.sample.slice!(0)
#		names = names - [a]
		notexcluded = excludeprevious(a,names,excludes)
		b = notexcluded.sample
		names = names - [b]
		
		pairings << [a,b]
	end
	# Using a global for this is terrible practice and I am a bad person. But it works for now.
	if names.length == 1
		$spare = names
	else
		$spare = nil
	end
	return pairings
end

#def randomise(names)
#	pairings = Array.new
#	while names.length > 1
#		a = names.sample
#		names = names - [a]
#		b = names.sample
#		names = names - [b]
#		pairings << [a,b]
#	end
#	# Using a global for this is terrible practice and I am a bad person. But it works for now.
#	if names.length == 1
#		$spare = names
#	else
#		$spare = nil
#	end
#	return pairings
#end

def checkforname(list,name)
	list.include? [name]
end

get '/' do
	$memberlist, $exclusionlist, $pairings, $spare = nil
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
		slim :pairings
	else slim :index
	end
end

post '/pairings' do
	if $memberlist
		$pairings = randomise($memberlist,$exclusionlist)
		end
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

		exclusionA = checkforname($memberlist,params[:exclusionA])
		exclusionB = checkforname($memberlist,params[:exclusionB])
				
		exclusionA ? @errorA = nil : @errorA = "Name '#{params[:exclusionA]}' is not on the member list"
		exclusionB ? @errorB = nil : @errorB = "Name '#{params[:exclusionB]}' is not on the member list"
			
		if exclusionB && exclusionA
			$exclusionlist << [params[:exclusionA],params[:exclusionB]]
		end
	end
	slim :exclusions
end
