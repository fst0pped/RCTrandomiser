require 'sinatra'
require 'csv'
require 'slim'

use Rack::Session::Pool

#-----------------------------------------------------------------------
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
  attr_accessor :pairings
  attr_accessor :spare_member
    def initialize(members,exclusions)
      @pairings = randomise(members,exclusions)[0]
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
  # Using a global for this is terrible practice and I am a bad person. But it works for now.
  if members.length == 1
    spare = members
  else
    spare = nil
  end
  return pairings
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
  $memberlist, $exclusionlist, $pairings, $spare = nil
  slim :index
end

get '/pairings' do
  slim :pairings
end

get '/membernames' do
  if session[:members]
    slim :membernames
  else
    $error = "You have not submitted any names yet"
    slim :index
  end
end

get '/exclusions' do
  slim :exclusions
end

get '/download' do
  slim :download
end

#
#Post
#

post '/' do
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
    pairings = session[:pairings] = PairingsList.new(members,exclusions)
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
