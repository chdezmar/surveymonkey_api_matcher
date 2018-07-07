# Surveymonkey

Easily access SurveyMonkey API V3 and avoid matching answers and questions texts.
Working on a different approach.

## Installation

Build gem locally and install it.

## Usage

Access endpoints:

```ruby
Surveymonkey::Client.new.surveys
```
```ruby
Surveymonkey::Client.new.survey_folders
```
```ruby
Surveymonkey::Client.new.survey_details(survey_id)
```
```ruby
Surveymonkey::Client.new.survey_responses(survey_id)
```
```ruby
Surveymonkey::Client.new.survey_response(survey_id, response_id)
```

Matchers:

```ruby
Surveymonkey::Mapper.new.survey_response(survey_id, response_id)
```

Optional query strings available: https://developer.surveymonkey.com/api/v3/#surveys

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/chdezmar/surveymonkey_api.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
