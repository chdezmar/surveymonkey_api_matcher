module Surveymonkey
  class Client
    module Survey

      def surveys(options = {})
        # Return an array of all surveys
        surveys = []
        response = self.class.get("/surveys", { query: options })
        if response['total'] > response['per_page']
          surveys << get_all_pages(response['links'])
        else
          surveys << response['data']
        end
        surveys.flatten
      end

      def survey_details(id, options = {})
        # Return survey details response
        self.class.get("/surveys/#{id}/details", { query: options })
      end

    end
  end
end