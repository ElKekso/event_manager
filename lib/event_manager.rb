require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,'0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def clean_phonenumber(number)
  number.delete!("-(). ")
  if number.length == 10
    number
  elsif number.length == 11 && number[0].to_s == "1"
    number[1..10]
  else
    'The entered number was bad'
  end
end

def convert_time(date)
  time = Time.strptime(date, "%D %R")
end

def average_time(times)
  total_minutes = times.reduce(0) {|sum, time| sum += time.hour * 60 + time.min}
  average_minutes = total_minutes / times.length
  "#{average_minutes / 60}:#{average_minutes.remainder(60)}"
end

def highest_day(days)
  i = 0
  days.each_with_index {|val, index| i = index if val > days[i] }
  Date::DAYNAMES[i  - 6]
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv', 
  headers: true,
  header_converters: :symbol 
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

times = Array.new
days = Array.new

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  phonenumber = clean_phonenumber(row[:homephone])

  time = convert_time(row[:regdate])

  times[id.to_i - 1] = time

  if days[time.wday].nil?
    days[time.wday] = 1
  else
    days[time.wday] += 1
  end

  puts time.day

  legislators = legislators_by_zipcode(zipcode)


  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)

end

puts highest_day(days)
puts average_time(times)
