require 'sinatra'
require 'csv'
require 'slim'

use Rack::Session::Pool

#-----------------------------------------------------------------------
<<<<<<< HEAD
#Classes
#-----------------------------------------------------------------------

class MemberList
  attr_accessor :members
  def initialize(list)
    @members = list
  end
end

class ExclusionList
  attr_accessor :exclusions
  def initialize(list)
    @exclusions = list
  end
end

class PairingsList
  attr_accessor :pair_and_spare
    def initialize(members,exclusions)
      @pair_and_spare = randomise(members,exclusions)
    end
end

#-----------------------------------------------------------------------
#Functions
#-----------------------------------------------------------------------

def randomise(members, exclusions)
  pairings = []
  while members.length > 1 # in case list length is odd
    # extract name from members
    a = members.sample
    members = members - [a]
    # if no exclusion list exists, skip over that logic
    if exclusions
      notexcluded = exclude(a,members,exclusions)
      # set name from notexcluded, but remove from members so it can't be reused
      b = notexcluded.sample
    else
      b = members.sample
    end
    members = members - [b]
    pairings << [a,b]
  end
  # If there are an odd number of members, also return the unpaired spare
  if members.length == 1
    spare = members
  else
    spare = nil
  end
  return pairings,spare
end


def exclude(name,members,exclusions)
  toexclude = []
  exclusions.each do |item| 
    if [item[0]] == name
      toexclude << [item[1]]
    elsif [item[1]] == name
      toexclude << [item[0]]
    end
  end
  # remove names from the members array if they match any names on the toexclude array
  return members.reject { |x| toexclude.include?(x) }
=======
#Functions
#-----------------------------------------------------------------------

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
>>>>>>> acd40405c545c33aca49a09ba482d39e3a57a2c0
end


def checkforname(list,name)
	list.include? [name]
end

#-----------------------------------------------------------------------
#Controllers
#-----------------------------------------------------------------------

#
#Get
#

get '/' do
<<<<<<< HEAD
  slim :index
end

get '/pairings' do
  unless session[:pairings]
    @error = "No members have been added yet"
  end
  slim :pairings
end

get '/membernames' do
  unless session[:members]
    @error = "No members have been added yet"
  end
  slim :membernames
end

get '/exclusions' do
  unless session[:exclusions]
    @error = "No excluded pairs have been added yet."
  end
  slim :exclusions
=======
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
>>>>>>> acd40405c545c33aca49a09ba482d39e3a57a2c0
end

get '/download' do
	slim :download
end

#
#Post
#

post '/' do
<<<<<<< HEAD
  if params[:memberlist]
    session[:members] = MemberList.new(CSV.read(params[:memberlist][:tempfile]))
    if params[:exclusionlist]
      session[:exclusions] = ExclusionList.new(CSV.read(params[:exclusionlist][:tempfile]))
    end
    slim :pairings
  end
end

post '/pairings' do
  if session[:members]
    members = session[:members].members
    exclusions = session[:exclusions].exclusions
    
    pair_and_spare = session[:pair_and_spare] = PairingsList.new(members,exclusions)
    
    pairings = session[:pairings] = pair_and_spare.pair_and_spare[0]
    # if member list is even, sometimes a name ends up in the spare pile and throws an error
    # think this might be where the only pairing left is on the exclusion list
    # shouldn't appear in the wild with large/changing lists, but needs fixing
    spare_member = session[:spare_member] = pair_and_spare.pair_and_spare[1]
    end
  slim :pairings
end

post '/membernames' do
  if params[:newname]
    session[:members].members << params[:newname]
    end
    slim :membernames
end

post '/exclusions' do
  if session[:members]
    members = session[:members].members
  end
  if session[:exclusions]
    exclusions = session[:exclusions].exclusions
  end
  
  if params[:exclusionA] == "" || params[:exclusionB] == ""
    @error = "Name field(s) cannot be blank"
  elsif params[:exclusionA] == params[:exclusionB]
    @error = "You can't exclude someone from meeting themselves"
  elsif params[:exclusionA] != "" && params[:exclusionB] != ""

    exclusionA = checkforname(members,params[:exclusionA])
    exclusionB = checkforname(members,params[:exclusionB])
        
    exclusionA ? @errorA = nil : @errorA = "Name '#{params[:exclusionA]}' is not on the member list"
    exclusionB ? @errorB = nil : @errorB = "Name '#{params[:exclusionB]}' is not on the member list"
      
    if exclusionA && exclusionB
      exclusions << [params[:exclusionA],params[:exclusionB]]
    end
  end
  slim :exclusions
=======
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
>>>>>>> acd40405c545c33aca49a09ba482d39e3a57a2c0
end
