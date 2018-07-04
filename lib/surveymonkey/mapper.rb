require 'pry-byebug'

module Surveymonkey
  # Map answers to content
  class Mapper
    def survey_response(survey_id, response_id)
      hash = []
      survey_structure = Surveymonkey::Client.new.survey_details(survey_id)
      response = Surveymonkey::Client.new.survey_response(survey_id, response_id)
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
          hash << { "#{key}": answers }
        end
      end
      hash
    end
  end
end
