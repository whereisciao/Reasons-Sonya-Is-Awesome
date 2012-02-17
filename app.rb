require 'rubygems'
require 'bundler'
require 'yaml'

Bundler.require

configure do
  VOICE = "woman"
  REASONS = YAML::load(File.open(File.dirname(__FILE__) + "/reasons.yml"))
  MAX_SMS_LIMIT = 160
  SMS_LIMIT = 120
end

def segment_sms(message, sms_limit = 120)
  space = 1
  
  message.split(" ").inject({:len => 0, :part => [[]]}) do |collection, token|
    next_token = token.size + space
    if(collection[:len] + next_token < sms_limit)
      collection[:len] += next_token
      collection[:part].last << token
    else
      collection[:len] = next_token
      collection[:part] << [token]
    end
    collection
  end
end

get '/' do
  @reason = reasonSonyaIsAwesome
  erb :index
end

post '/sms' do    
  response = Twilio::TwiML::Response.new do |r|
    r.To "+1#{params["From"]}"
    r.From "+1#{params["To"]}"
    if params["Body"].upcase =~ /HELP/
      r.Sms "Welcome to the Reasons Sonya Is Awesome Hotline.  Text GIMME " +
        "to get one random reason Sonya is awesome."
    else
      reason = reasonSonyaIsAwesome

      if(reason.size <= MAX_SMS_LIMIT)
        r.Sms reason
      else
        segments = segment_sms(reason, SMS_LIMIT)
        total_parts = segments[:part].size
        segments[:part].each_with_index do |segment, idx|
          r.Sms segment.join(" ") + " (#{idx + 1}/#{total_parts})"
        end
      end

    end
  end
  
  response.text
end

post '/voice' do
  response = Twilio::TwiML::Response.new do |r|
    r.Say 'Hello Sonya.  Here is a reason why you are awesome.', :voice => VOICE
    reason = reasonSonyaIsAwesome
    reason.sub(':', '.')
    reason = "This one is from #{reason}"
    r.Say reason, :voice => VOICE
        
    r.Gather(:action => '/gather', :numDigits=>'1') do |g|
      g.Say 'Press 1 if you would like to hear another reason.  Press 2 or ' +
      'hangup if you are finished.', :voice => VOICE
    end
    
    r.Pause
    r.Redirect '/voice'
  end

  response.text
end

post '/gather' do
  response = Twilio::TwiML::Response.new do |r|
    if params["Digits"] == '1'
      reason = reasonSonyaIsAwesome
      reason.sub(':', '.')
      reason = "This one is from #{reason}"
      r.Say reason, :voice => VOICE
    elsif params['Digits'] == '2'
      r.Say 'By Sonya!', :voice => VOICE
      r.Hangup
    else
      r.Say 'I did not understand your input.', :voice => VOICE
    end
    
    r.Gather(:action => '/gather', :numDigits=>'1') do |g|
      g.Say 'Press 1 if you would like to hear another reason.  Press 2 or ' +
      'hangup if you are finished.', :voice => VOICE
    end
    
    r.Pause
    r.Redirect '/voice'
  end

  response.text
end

def reasonSonyaIsAwesome
  return REASONS[rand(REASONS.size)]
end