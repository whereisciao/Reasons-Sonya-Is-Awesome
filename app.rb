require 'rubygems'
require 'bundler'

Bundler.require

configure do
  VOICE = "woman"
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
      r.Sms reasonSonyaIsAwesome
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
  reasons = [
    'Alex: You hate the Giants.',
    'Alex: You can make a mean clafuti.',
    'Alex: You are an Excel master.',
    'Alex: You hate Apple.',
    'Alex: You are a beer snob.',
    'Alex: You are a great mother.',
    'Alex: You are a very smart woman.',
    'Alex: You are the neck of our family.',
    'Alex: You have a great waist.',
    'Kent: You are have very intelligent discussions.',
    'Kent: You have a great sense of humor.',
    'Ellen: Your brain is is awesome.',
    'Becca: You are a good listener and has a fantastic perspective.',
    'Becca: You accomplished everything you hoped to before 30.',
    'Becca: You were in every Las Vegas casino before she was 18.',
    'Becca: You can be counted on to be an emergency contact for '\
        'friends who don\'t have family in NYC.',
    'Becca: You were at bars in Williamsburg even when you were ' \
        'super pregnant.',
    'Becca: You like both opera and ska music.',
    'Rob: You are one of the most fiercely loyal people in New York.',
    'Rob: The scope of your intellect is matched only by the size ' \
            'of your heart',
    'Rob: You remember where you came from and are grateful for ' \
            'the journey.',
    'Rob: You and Alex form my ideal of matrimony.',
    'Rob: Your family comes first.',
    'Rob: You do not front.',
    'Bill: You speak Russian.  LOUD.',
    'Alex: You vote in every election.',
    'Bill: You are my best friend\'s hit wife.'
  ]
  return reasons[rand(reasons.size)]
end