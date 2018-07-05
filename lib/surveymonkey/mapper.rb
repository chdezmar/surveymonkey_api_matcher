require 'pry-byebug'

module Surveymonkey
  # Map answers to content
  class Mapper
    def survey_response(survey_id, response_id)
      hash = {}
      # Get survey structure and response
      survey_structure = Surveymonkey::Client.new.survey_details(survey_id)
      response = Surveymonkey::Client.new.survey_response(survey_id, response_id)
      # Create json structrure to return
      hash['metadata'] = extract_metadata(response)
      hash['responses'] = []
      # Match responses to survey structure
      response['pages'].each_with_index do |response_page, page_index|
        response_page['questions'].each_with_index do |response_question, question_index|
          question_structure = survey_structure['pages'][page_index]['questions'].select do |q|
            q['id'] == response_question['id']
          end
          # Get all question labels
          key =  question_structure.first['headings'].first['heading'].gsub(/<\/?[^>]*>/, "")

          # Get all answer labels
          answers = []

          if response_question['answers']&.any?

            response_question['answers'].each do |question_response_answer|
              if question_response_answer['text']
                answers << question_response_answer['text']
              end

              if question_response_answer['row_id'] && question_response_answer['choice_id']
                answers << "#{question_structure.first['answers']['rows'].select {|a| a['id'] == question_response_answer['row_id']}.first['text']}: #{question_structure.first['answers']['choices'].select {|a| a['id'] == question_response_answer['choice_id']}.first['text']}"
              elsif question_response_answer['choice_id']
                answers << question_structure.first['answers']['choices'].select {|a| a['id'] == question_response_answer['choice_id']}.first['text']
              end
            end

          end
          hash['responses'] << { "#{key}": answers }
        end
      end
      hash
    end

    private

    def extract_metadata(response)
      { inquiry_id: response['custom_variables']['id'].gsub(/\[|\]/, ''),
        date_created: response['date_created'],
        date_modified: response['date_modified'],
        response_status: response['response_status'],
        analyze_url: response['analyze_url'],
        total_time: response['total_time'].to_s }
    end

  end
end
