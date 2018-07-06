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
      hash[:metadata] = extract_metadata(response)
      hash[:pages] = []
      # Match responses to survey structure
      response['pages'].each_with_index do |response_page, page_index|
        hash[:pages] << extract_page_title(survey_structure, page_index)
        response_page['questions'].each_with_index do |response_question, question_index|
          question_structure = survey_structure['pages'][page_index]['questions'].select do |q|
            q['id'] == response_question['id']
          end
          # Get all question labels
          key =  question_structure.first['headings'].first['heading'].gsub(/<\/?[^>]*>/, "")

          # Get all answer labels
          answers = []

          if response_question['answers']&.any?

            response_question['answers'].each do |response_question_answer|
              if response_question_answer['text']
                answers << response_question_answer['text']
              end

              if response_question_answer['row_id'] && response_question_answer['choice_id']
                answers << "#{value_for('row_id', question_structure, response_question_answer)}: #{value_for('choice_id', question_structure, response_question_answer)}"
              elsif response_question_answer['choice_id']
                answers << value_for('choice_id', question_structure, response_question_answer)
              end
            end
          end
          hash[:pages][page_index][:responses] << { "#{key}": answers }
        end
      end
      hash[:pages].reject! {|p| p[:responses].empty?}
      group_pages_by_title(hash)
      hash
    end

    private


    def value_for(name, question_structure, response_question_answer)
      case name
      when 'row_id'
        question_structure.first['answers']['rows'].select {|a| a['id'] == response_question_answer['row_id']}.first['text']
      when 'choice_id'
        question_structure.first['answers']['choices'].select {|a| a['id'] == response_question_answer['choice_id']}.first['text']
      end
    end

    def group_pages_by_title(hash)
      page_title = nil
      pages_grouped_by_title = []
      hash[:pages].each do |page|
        if page[:title] != page_title
          pages_grouped_by_title << page
          page_title = page[:title]
        else
          pages_grouped_by_title.last[:responses] << page[:responses]
        end
      end
      hash[:pages] = pages_grouped_by_title
    end

    def extract_page_title(survey_structure, page_index)
      title = survey_structure['pages'][page_index]['title']
      { title: title,
        responses: [] }
    end

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
