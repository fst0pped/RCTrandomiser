require 'sinatra'
require 'csv'
require 'slim'

def randomise(memberlist, exclusionlist)
	pairings = []
	while memberlist.length > 1 # in case list length is odd
		# extract name from memberlist
		a = memberlist.sample
		memberlist = memberlist - [a]
		notexcluded = exclude(a,memberlist,exclusionlist)
		# set name from notexcluded, but remove from memberlist so it can't be reused
		b = notexcluded.sample
		memberlist = memberlist - [b]
		pairings << [a,b]
	end
	# Using a global for this is terrible practice and I am a bad person. But it works for now.
	if memberlist.length == 1
		$spare = memberlist
	else
		$spare = nil
	end
	return pairings
end


def exclude(name,memberlist,exclusionlist)
	toexclude = []
	exclusionlist.each do |item| 
		if [item[0]] == name
			toexclude << item[1]
		elsif [item[1]] == name
			toexclude << item[0]
		end
	end
	# remove names from the members array if they match any names on the toexclude array
	return memberlist.reject { |x| [toexclude].include?(x) }
end

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
		p $pairings
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
