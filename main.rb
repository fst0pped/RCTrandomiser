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
  
  def self.removedisabled(list)
    return list.reject { |member| member[1] == "D" }
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
    @pair_and_spare = PairingsList.randomise(members,exclusions)
  end
  
  def self.randomise(members, exclusions)
    pairings = []
    while members.length > 1 # in case list length is odd
      # extract name from members
      a = members.sample
      members = members - [a]
      # if no exclusion list exists, skip over that logic
      if exclusions
        notexcluded = PairingsList.exclude(a,members,exclusions)
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
  
  def self.exclude(name,members,exclusions)
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
  
end

#-----------------------------------------------------------------------
#Functions
#-----------------------------------------------------------------------

#def checkforname(list,name)
#  list.include?(name)
#end

def checkforname(list,name)
  names_only = []
  list.each do |item|
    names_only << item[0]
  end
  names_only.include?(name)
end

def checkforpair(list,pair)
  p list
  list.each do |item|
    p item
    item_reverse = [item[1],item[0]]
    p item_reverse
    if item == pair || item_reverse == pair
      pair_exists = true
      break
    end
  end
  if pair_exists == true
    return true
  else
    return false
  end
end

def timestamp(time)
  timestamp = "#{time.year}-#{time.month}-#{time.day}-#{time.hour}:#{time.min}"
  return timestamp
end

#-----------------------------------------------------------------------
#Controllers
#-----------------------------------------------------------------------

#
#Get
#

get '/' do
  session.clear
  slim :index
end

get '/index' do
  session.clear
  slim :index
end

get '/about' do
  slim :about
end

get '/upload' do
  slim :upload
end

get '/pairings' do
  unless session[:pairings]
    @pairing_error = "No members have been added yet"
  end
  slim :pairings
end

get '/membernames' do
  unless session[:members]
    @membername_error = "No members have been added yet"
  end
  slim :membernames
end

get '/exclusions' do
  unless session[:exclusions]
    @exclusion_error = "No excluded pairs have been added yet."
  end
  slim :exclusions
end

get '/download' do
  unless session[:members] || session[:exclusions]
    @download_error = "No lists are available for download yet."
  end
  slim :download
end

get '/csv/pdownload' do
  timestamp = timestamp(Time.new)
  
  pairings = session[:pairings]
  
  content_type 'application/csv'
  attachment "RCT_pairings_#{timestamp}.csv"
  csv_string = CSV.generate do |csv|
    pairings.each do |pair|
      csv << [pair[0][0], pair[1][0]]
    end
  end
end
  
get '/csv/mdownload' do
  timestamp = timestamp(Time.new)
    
  members = session[:members].members
  
  content_type 'application/csv'
  attachment "RCT_members_#{timestamp}.csv"
  csv_string = CSV.generate do |csv|
    members.each do |member|
      csv << [member[0], member[1]]
    end
  end     
end

get '/csv/edownload' do
  timestamp = timestamp(Time.new)
    
  exclusions = session[:exclusions].exclusions
  
  content_type 'application/csv'
  attachment "RCT_exclusionlist_#{timestamp}.csv"
  csv_string = CSV.generate do |csv|
    exclusions.each do |excluded|
      csv << [excluded[0], excluded[1]]
    end
  end     
end

#
#Post
#

post '/clearsession' do
  session.clear
  slim :index
end

post '/upload' do
  if params[:memberlist]
    session[:members] = MemberList.new(CSV.read(params[:memberlist][:tempfile]))
    if params[:exclusionlist]
      session[:exclusions] = ExclusionList.new(CSV.read(params[:exclusionlist][:tempfile]))
    end
  else @upload_error = "Cannot submit unless there is a list of members attached."
  end
  slim :membernames
end

post '/pairings' do
  if session[:members]
    members = session[:members].members
    if session[:exclusions]
      exclusions = session[:exclusions].exclusions
    end
    
    active_members = MemberList.removedisabled(members)
    
    pair_and_spare = session[:pair_and_spare] = PairingsList.new(active_members,exclusions)
    
    pairings = session[:pairings] = pair_and_spare.pair_and_spare[0]
    # if member list is even, sometimes a pair ends up with only one name and throws an error
    # think this might be where the only pairing left is on the exclusion list
    # shouldn't appear in the wild with large/changing lists, but needs fixing
    # the below is a bit hacky, but allows the app to fail gracefully while I think of a solution
    pairings.each do |pair|
      pair.each do |name|
        if name == nil
          @pairings_error = "There has been an error while generating pairings. Please try again."
          pairings = session[:pairings] = nil
        end
      end
    end
    unless @error
      spare_member = session[:spare_member] = pair_and_spare.pair_and_spare[1]
    end
    
    end
  slim :pairings
end

post '/membernames' do
  newname = params[:newname].collect { |name| name.strip }
  
  if newname[0] == ""
    @membernames_error = "Name field cannot be blank"
  elsif !session[:members]
    session[:members] = MemberList.new([newname])
  elsif session[:members]
    member_test = checkforname(session[:members].members,newname[0])
    member_test ? @membernames_error = "The name '#{newname[0]}' is already on the member list" : session[:members].members << newname
  else @membernames_error = "Unforseen error. Please contact program author with details of what you were trying to do"
  end
    slim :membernames
end

post '/disablemember' do
  member_name = params[:disable]
  session[:members].members.each do |name|
    if [name[0]] == member_name
      name.insert(1,"D")
    end
  end
  slim :membernames
end

post '/enablemember' do
  member_name = params[:enable]
  session[:members].members.each do |name|
    if [name[0]] == member_name
      name.delete("D")
    end
  end
  slim :membernames
end

post '/deletemember' do
  member_name = params[:delete]
  # deletes member from the overall members list
  session[:members].members.reject! { |name| [name[0]] == member_name }
  # if exclusion list exists, also deletes all pairs that include the member's name
  if session[:exclusions]
    session[:exclusions].exclusions.reject! { |names| [names[0]] == member_name || [names[1]] == member_name }
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

  exclusionA = params[:exclusionA].strip
  exclusionB = params[:exclusionB].strip
  
  if exclusionA == "" || exclusionB == ""
    @exclusion_error = "Name field(s) cannot be blank"
  elsif exclusionA == exclusionB
    @exclusion_error = "You can't exclude someone from meeting themselves"
  elsif exclusionA != "" && exclusionB != ""

    exclusionA_test = checkforname(members,exclusionA)
    exclusionB_test = checkforname(members,exclusionB)
    exclusion_pair_test = checkforpair(exclusions, [exclusionA,exclusionB])
    p exclusion_pair_test
        
    exclusionA_test ? @errorA = nil : @errorA = "Name '#{exclusionA}' is not on the member list"
    exclusionB_test ? @errorB = nil : @errorB = "Name '#{exclusionB}' is not on the member list"
    if exclusionA_test && exclusionB_test
      exclusion_pair_test ? @error_pair = "This pair is already excluded" : @error_pair = nil
    end
      
    if exclusionA_test && exclusionB_test && !exclusion_pair_test && session[:exclusions]
      exclusions << [exclusionA,exclusionB]
    elsif exclusionA_test && exclusionB_test && !session[:exclusions]
      session[:exclusions] = ExclusionList.new([[exclusionA,exclusionB]])
    end
  
  else @error = "Unforseen error. Please contact program author with details of what you were trying to do"
  
  end
  slim :exclusions
end

post '/deleteexclusion' do
  excluded_pair = params[:delete]
  p excluded_pair
  session[:exclusions].exclusions.reject! { |pair| "#{pair[0]}, #{pair[1]}" == excluded_pair }
  slim :exclusions
end
