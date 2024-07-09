require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_number(phone_number)
  phone_number.to_s.gsub!(/[() -.+a-zA-Z]/, "")
  if phone_number.length < 10
    phone_number = "bad phone number"
  elsif phone_number.length == 11
    if phone_number[0] == "1"
      phone_number = phone_number.reverse.chop.reverse
    end
  end
  phone_number
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def find_average_time(array)
  i = 0
  array.each { |time| i += time }
  puts 'The average time is ' + (i / array.length).to_s + ':00'
end

def find_average_day(array)
  counts = Hash.new(0)

  array.each do |date|
    counts[date] += 1
  end

  max_count = counts.values.max
  most_frequent_dates = counts.select { |date, count| count == max_count }.keys

  puts "The average day of registration is #{most_frequent_dates.join(', ')}"
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
registration_times = []
registration_dates = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)
  registration_times << Time.strptime(row[:regdate], "%D %R").strftime('%H:%M:%S').to_i
  registration_dates << Time.strptime(row[:regdate], "%D %R").strftime('%A')

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end

find_average_time(registration_times)
find_average_day(registration_dates)