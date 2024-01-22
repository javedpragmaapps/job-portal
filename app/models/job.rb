class Job < ApplicationRecord
    belongs_to :category
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    # # Job.__elasticsearch__.create_index!
    # Job.__elasticsearch__.create_index!(force: true)
    # # Job.import
    
    # Your model logic here
    settings index: { number_of_shards: 1 } do

      mappings dynamic: 'false' do
        indexes :approved_at, index: :false
        indexes :title
        indexes :city
        indexes :state
        indexes :category_id
        indexes :company_id
        indexes :emp_type
        indexes :date
        indexes :experience
        indexes :salary
        indexes :cpa
        indexes :verified
        indexes :description
        indexes :skills
        indexes :critical_resp
        indexes :qualification
        indexes :created_at
        indexes :updated_at
        indexes :updated_by
        indexes :approved_by
        indexes :approved_at
        indexes :allocated_to
      end
    end

    def as_indexed_json(options = {})
      self.as_json(
        only: [:title, :city, :verified, :category_id, :emp_type, :cpa, :date],
        include: {
          category: {
            only: [:id, :title, :created_at]
          }
        }
        # Add other fields you want to index
      )
    end


    def self.search(query, city = false, category = false, empType = false, cpaRange = false, createdDate = false)

      # validate the required value is present or not
      # if present availbale for the elastciSearch query and get the result
      shouldFilter = []
      rangeFilter = []
      if(query)
        shouldFilter.push({ "match_phrase": { "title": query }})
      end
      if(city)
        city_values = city.split
        shouldFilter.push({ "match_phrase": { "city": city_values[0] }})
      end
      if(category)
        shouldFilter.push({ "match_phrase": { "category_id": category }})
      end
      if(empType)
        shouldFilter.push({ "match_phrase": { "emp_type": empType }})
      end
      if(cpaRange)
        cpaRange_values = cpaRange.split("-")
        rangeFilter.push({ "range": { "cpa": {"gt": cpaRange_values[0], "lt": cpaRange_values[1]} }})
      end
      if(createdDate)
        # rangeFilter.push({ "range": { "date": {"gt": "2015-12-10 13:49:14.803837 +0530", "lt": "2024-12-10 13:49:14.80395 +0530"} }})
        # rangeFilter.push({ "range": { "date": {"gt": "2012-12-10 04:49:00", "lt": "2015-12-10 04:49:00"} }})
        lastDate = Time.now - createdDate.to_i.days
        rangeFilter.push({ "range": { "date": {"gt": lastDate, "lt": Time.now} }})
      end

      #  main query params by which elastics search result will calculate
      params = {
          "query": {
              "bool": {
                  "should": shouldFilter,
                  "filter": rangeFilter
              }
          }
      }
  
      ## search the results
      self.__elasticsearch__.search(params)
    end
end



  # Delete the previous term index in Elasticsearch
  Job.__elasticsearch__.client.indices.delete index: Job.index_name rescue nil

  # Create the new index with the new mapping
  Job.__elasticsearch__.client.indices.create \
    index: Job.index_name,
    body: { settings: Job.settings.to_hash, mappings: Job.mappings.to_hash }

  # Index all term records from the DB to Elasticsearch
  Job.import(force: true)