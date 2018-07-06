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
        response_page['questions'].each_with_index do |question, question_index|
          question_structure = survey_structure['pages'][page_index]['questions'].select do |q|
            q['id'] == question['id']
          end
          # Get question labels
          hash[:pages][page_index][:questions] << extract_question_title(question_structure, page_index)

          # Get all answer labels
          answers = []
          if question['answers']&.any?
            question['answers'].each do |answer|
              if answer['text']
                answers << { text: answer['text']}
              end
              if answer['row_id'] && answer['choice_id']
                answers << { text: "#{value_for('row_id', question_structure, answer)}: #{value_for('choice_id', question_structure, answer)}"}
              elsif answer['choice_id']
                answers << { text: value_for('choice_id', question_structure, answer)}
              end
            end
          end
          hash[:pages][page_index][:questions][question_index][:answers] = answers.flatten
        end
      end
      hash[:pages].reject! {|p| p[:questions].empty?}
      group_pages_by_title(hash)
      hash
    end

    private


    def value_for(name, question_structure, answer)
      case name
      when 'row_id'
        question_structure.first['answers']['rows'].select {|a| a['id'] == answer['row_id']}.first['text']
      when 'choice_id'
        question_structure.first['answers']['choices'].select {|a| a['id'] == answer['choice_id']}.first['text']
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
          pages_grouped_by_title.last[:questions] << page[:questions]
          pages_grouped_by_title.last[:questions].flatten!
        end
      end
      hash[:pages] = pages_grouped_by_title
    end

    def extract_page_title(survey_structure, page_index)
      id = survey_structure['pages'][page_index]['id']
      title = survey_structure['pages'][page_index]['title']
      { id: id,
        title: title,
        questions: [] }
    end

    def extract_question_title(question_structure, page_index)
      id = question_structure.first['id']
      title = question_structure.first['headings'].first['heading'].gsub(/<\/?[^>]*>/, "")
      { id: id,
        title: title,
        answers: [] }
    end

    def extract_metadata(response)
      { id: response['custom_variables'],
        date_created: response['date_created'],
        date_modified: response['date_modified'],
        response_status: response['response_status'],
        analyze_url: response['analyze_url'],
        total_time: response['total_time'].to_s }
    end

  end
end
