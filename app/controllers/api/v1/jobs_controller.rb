require 'uri'
require 'net/http'
require 'time'

class Api::V1::JobsController < ApplicationController
  skip_before_action :verify_authenticity_token
  EmpTypeList = ['Intern', 'Freelance', 'Part-Time', 'Full-Time']
  CATEGORIES = ['Information Technology', 'Finance', 'Education', 'Healthcare', 'Engineering', 'Hospitality', 'Marketing', 'Automotive']
  CompaniesList = [
    {
        "name": "Tech Solutions Inc",
        "phone": "1234567890",
        "email": "info@techsolutions.com",
        "website": "www.techsolutions.com",
        "city": "New York",
        "state": "New York",
        "country": "USA",
        "primary_industry": "Information Technology",
        "founded_in": 2005,
        "logo": "assets/company/tech_solutions_inc.png",
        "social_handles": {
            "facebook": "https://www.facebook.com/TechSolutionsInc",
            "twitter": "https://twitter.com/TechSolutions",
            "instagram": "https://www.instagram.com/techsolutions",
            "linkedin": "https://www.linkedin.com/company/tech-solutions-inc",
        },
        "company_size": 500,
        "description": "Tech Solutions Inc is a pioneering Information Technology company headquartered in the bustling metropolis of New York, USA. With a rich history dating back to its establishment in 2005, the company has consistently delivered cutting-edge software development and IT consulting services. Our dedicated team of experts harnesses the latest technological advancements to create innovative solutions that empower businesses to thrive in the digital age. As industry leaders, we have forged a reputation for excellence and reliability, serving a diverse clientele with a commitment to precision and quality. Tech Solutions Inc's unwavering dedication to technology and client success makes us the go-to partner for all your IT needs.",
        latitude: 40.712776,
        longitude: -74.005974
    },
    {
        "name": "Green Energy Group",
        "phone": "9876543210",
        "email": "contact@greenenergygroup.com",
        "website": "www.greenenergygroup.com",
        "city": "Los Angeles",
        "state": "California",
        "country": "USA",
        "primary_industry": "Automotive",
        "founded_in": 2010,
        "logo": "assets/company/green_energy_group.png",
        "social_handles": {
            "facebook": "https://www.facebook.com/GreenEnergyGroup",
            "twitter": "https://twitter.com/GreenEnergy",
            "instagram": "https://www.instagram.com/greenenergygroup",
            "linkedin": "https://www.linkedin.com/company/green-energy-group",
        },
        "company_size": 200,
        "description": "Green Energy Group is a pioneering force in the realm of sustainable energy and automotive innovation. With a steadfast commitment to environmental responsibility, they've become synonymous with eco-friendly transportation solutions. Since their inception in 2010, Green Energy Group has continually pushed the boundaries of automotive technology, delivering electric and hybrid vehicles that not only reduce carbon emissions but also set new standards for performance and efficiency.",
        latitude: 34.0536909,
        longitude: -118.242766
    },
    {
        "name": "Global Logistics Ltd",
        "phone": "5555555555",
        "email": "info@globallogistics.com",
        "website": "www.globallogistics.com",
        "city": "Sydney",
        "state": "New South Wales",
        "country": "Australia",
        "primary_industry": "Engineering",
        "founded_in": 2008,
        "logo": "assets/company/global_logistics_ltd.png",
        "social_handles": {
            "facebook": "https://www.facebook.com/GlobalLogisticsLtd",
            "twitter": "https://twitter.com/GlobalLogistics",
            "instagram": "https://www.instagram.com/globallogistics",
            "linkedin": "https://www.linkedin.com/company/global-logistics-ltd",
        },
        "company_size": 300,
        "description": "Global Logistics Ltd, established in 2008 in London, UK, is a prominent player in the engineering industry. With a decade of experience, they've earned a reputation for their efficient supply chain solutions and innovative logistics services. Their commitment to excellence has enabled them to build a vast clientele across international borders. They continuously adapt to the evolving demands of the global market, offering sustainable and technology-driven logistics solutions. Global Logistics Ltd is dedicated to streamlining operations, reducing environmental impact, and delivering quality service.",
        latitude: -33.8698439,
        longitude: 151.2082848

    },
    {
        "name": "Food Innovations Co",
        "phone": "7777777777",
        "email": "contact@foodinnovations.com",
        "website": "www.foodinnovations.com",
        "city": "Paris",
        "state": "null",
        "country": "France",
        "primary_industry": "Hospitality",
        "founded_in": 2015,
        "logo": "assets/company/food_innovations_co.png",
        "social_handles": {
            "facebook": "https://www.facebook.com/FoodInnovationsCo",
            "twitter": "https://twitter.com/FoodInnovations",
            "instagram": "https://www.instagram.com/foodinnovations",
            "linkedin": "https://www.linkedin.com/company/food-innovations-co",
        },
        "company_size": 150,
        "description": "Based in Paris, France, Food Innovations Co was founded in 2015 and has swiftly risen in the hospitality sector. They're known for their culinary creativity and commitment to gastronomic excellence. With a diverse menu featuring innovative dishes, they cater to food enthusiasts worldwide. Food Innovations Co prioritizes sustainability, sourcing fresh, locally-produced ingredients to reduce their ecological footprint. Their dedication to providing unique dining experiences has made them a sought-after name in the culinary world. Whether it's gourmet dining or casual eats, Food Innovations Co is synonymous with culinary innovation and impeccable taste.",
        latitude: 48.8588897,
        longitude: 2.320041
    },
    {
        "name": "Tech Producers Ltd",
        "phone": "9999999999",
        "email": "info@techproducers.com",
        "website": "www.techproducers.com",
        "city": "London",
        "state": "null",
        "country": "United Kingdom",
        "primary_industry": "Information Technology",
        "founded_in": 2007,
        "logo": "assets/company/tech_producers_ltd.png",
        "social_handles": {
            "facebook": "https://www.facebook.com/TechProducersLtd",
            "twitter": "https://twitter.com/TechProducers",
            "instagram": "https://www.instagram.com/techproducers",
            "linkedin": "https://www.linkedin.com/company/tech-producers-ltd",
        },
        "company_size": 400,
        "description": "Tech Producers Ltd, established in 2007 and headquartered in San Francisco, USA, is a trailblazer in the information technology sector. They specialize in producing cutting-edge software solutions, offering a wide range of IT services to diverse industries. With a team of tech visionaries, they continuously push the boundaries of innovation. Tech Producers Ltd focuses on creating scalable, reliable, and secure technology products that empower businesses globally. Their commitment to excellence has earned them a strong reputation for delivering top-tier IT solutions, making them a preferred choice for businesses seeking digital transformation.",
        latitude: 51.5073359,
        longitude: -0.12765
    },
    {
        "name": "GreenTech Innovations",
        "phone": "1111111111",
        "email": "contact@greentechinnovations.com",
        "website": "www.greentechinnovations.com",
        "city": "San Jose",
        "state": "California",
        "country": "USA",
        "primary_industry": "Healthcare",
        "founded_in": 2012,
        "logo": "assets/company/greentech_innovations.png",
        "social_handles": {
            "facebook": "https://www.facebook.com/GreenTechInnovations",
            "twitter": "https://twitter.com/GreenTechInnovations",
            "instagram": "https://www.instagram.com/greentechinnovations",
            "linkedin": "https://www.linkedin.com/company/greentech-innovations",
        },
        "company_size": 250,
        "description": "GreenTech Innovations, founded in 2012 and based in Berlin, Germany, is at the forefront of the healthcare industry. They specialize in developing sustainable healthcare solutions that prioritize patient well-being and environmental responsibility. Their innovative medical technologies and eco-conscious practices are revolutionizing the healthcare landscape. GreenTech Innovations' commitment to improving healthcare while reducing its ecological footprint makes them a leader in the field. With a global presence, they are dedicated to shaping a healthier and more sustainable future for all.",
        latitude: 37.3361663,
        longitude: -121.890591
    },
    {
        "name": "Ocean Logistics Inc",
        "phone": "4444444444",
        "email": "info@oceanlogistics.com",
        "website": "www.oceanlogistics.com",
        "city": "Singapore",
        "state": "null",
        "country": "Singapore",
        "primary_industry": "Marketing",
        "founded_in": 2010,
        "logo": "assets/company/ocean_logistics_inc.png",
        "social_handles": {
            "facebook": "https://www.facebook.com/OceanLogisticsInc",
            "twitter": "https://twitter.com/OceanLogistics",
            "instagram": "https://www.instagram.com/oceanlogistics",
            "linkedin": "https://www.linkedin.com/company/ocean-logistics-inc",
        },
        "company_size": 300,
        "description": "Ocean Logistics Inc, headquartered in Miami, USA, since its inception in 2010, has made waves in the marketing industry. They offer a comprehensive suite of marketing and advertising services, helping businesses navigate the ever-changing digital landscape. Ocean Logistics Inc combines creativity with data-driven strategies to deliver impactful marketing campaigns. Their client-centric approach has resulted in long-lasting partnerships with businesses seeking to enhance their market presence. Ocean Logistics Inc is your compass in the dynamic world of marketing, guiding clients towards success in the digital age.",
        latitude: 1.357107,
        longitude: 103.8194992
    },
    {
        "name": "HealthTech Solutions",
        "phone": "7777777777",
        "email": "contact@healthtechsolutions.com",
        "website": "www.healthtechsolutions.com",
        "city": "Boston",
        "state": "Massachusetts",
        "country": "USA",
        "primary_industry": "Healthcare",
        "founded_in": 2014,
        "logo": "assets/company/healthtech_solutions.png",
        "social_handles": {
            "facebook": "https://www.facebook.com/HealthTechSolutions",
            "twitter": "https://twitter.com/HealthTech",
            "instagram": "https://www.instagram.com/healthtechsolutions",
            "linkedin": "https://www.linkedin.com/company/healthtech-solutions",
        },
        "company_size": 200,
        "description": "HealthTech Solutions is a pioneering healthcare technology company based in Toronto, Canada. With a strong commitment to improving healthcare accessibility and patient outcomes, HealthTech Solutions leverages cutting-edge technologies to develop innovative healthcare solutions. Their comprehensive suite of products and services includes telemedicine platforms, electronic health records systems, and data analytics tools. By seamlessly integrating technology into healthcare delivery, they empower healthcare providers to deliver high-quality care, streamline administrative processes, and enhance patient engagement. HealthTech Solutions is at the forefront of transforming the healthcare landscape, making healthcare more efficient, cost-effective, and patient-centered.",
        latitude: 40.712776,
        longitude: -74.005974
    },
    {
        "name": "Media Innovations Co",
        "phone": "2222222222",
        "email": "info@mediainnovations.com",
        "website": "www.mediainnovations.com",
        "city": "Los Angeles",
        "state": "California",
        "country": "USA",
        "primary_industry": "Media",
        "founded_in": 2006,
        "logo": "assets/company/media_innovations_co.png",
        "social_handles": {
            "facebook": "https://www.facebook.com/MediaInnovationsCo",
            "twitter": "https://twitter.com/MediaInnovations",
            "instagram": "https://www.instagram.com/MediaInnovations",
            "linkedin": "https://www.linkedin.com/company/MediaInnovations",
        },
        "company_size": 500,
        "description": "Media Innovations Co, headquartered in Los Angeles, USA, is a dynamic player in the media industry. With a relentless pursuit of creativity and innovation, they are redefining how media is consumed and experienced. Media Innovations Co offers a diverse range of media solutions, including cutting-edge production services, digital content creation, and interactive storytelling experiences. They have earned a reputation for pushing the boundaries of creativity and delivering captivating content that resonates with audiences worldwide. From blockbuster films to immersive virtual reality experiences, Media Innovations Co continues to shape the future of media, captivating hearts and minds with their visionary storytelling.",
        latitude: 34.0536909,
        longitude: -118.242766
    },
    {
        "name": "Eco Foods Ltd",
        "phone": "8888888888",
        "email": "contact@ecofoods.com",
        "website": "www.ecofoods.com",
        "city": "Sydney",
        "state": "New South Wales",
        "country": "Australia",
        "primary_industry": "Finance",
        "founded_in": 2011,
        "logo": "assets/company/eco_foods_ltd.png",
        "social_handles": {
            "facebook": "https://www.facebook.com/ecofoods",
            "twitter": "https://twitter.com/ecofoods",
            "instagram": "https://www.instagram.com/ecofoods",
            "linkedin": "https://www.linkedin.com/company/ecofoods",
        },
        "company_size": 900,
        "description": "Eco Foods Ltd, located in Sydney, Australia, is a trailblazer in the realm of sustainable finance. Committed to fostering a greener and more equitable world, they specialize in ethical and environmentally conscious financial solutions. Eco Foods Ltd invests in projects that promote sustainability, renewable energy, and eco-friendly practices. They work closely with businesses and organizations to channel funds into initiatives that have a positive impact on the environment and society. As advocates for responsible investing, Eco Foods Ltd is dedicated to creating a financial ecosystem where profit and sustainability coexist, contributing to a brighter, more sustainable future for all.",
        latitude: -33.8698439,
        longitude: 151.2082848
    }]

  def syncjobs

    uri = URI('https://649a714dbf7c145d0238d7df.mockapi.io/jobfeeds/alljobs')
    res = Net::HTTP.get_response(uri)
    # puts res.body if res.is_a?(Net::HTTPSuccess)

    ## fetch all categories from the categories table
    categoryIDs = insertCategoryRecords()

    ## fetch all Company from the Company table
    companyIDs = insertCompanyRecords()

    data = JSON.parse( res.body )

    mainHash = {}
    data.each { |i| 

      tempHash = {}
      i.each do |key, value|

        # exluding below keys as they does not having their columns in the database
        if key == "company" || key == "company_logo" 
          next
        end

        # modifying  below column details
        tempHash["date"] = Time.parse('Dec 8 2015 10:19')
        tempHash["emp_type"] = EmpTypeList.slice(rand(4))
        tempHash["experience"] = getMinMaxValue('min_exp', 'max_exp')
        tempHash["salary"] = getMinMaxValue('min_sal', 'max_sal')
        tempHash["category_id"] = (rand() * categoryIDs.length).floor()
        tempHash["company_id"] = (rand() * companyIDs.length).floor()
        tempHash[key] = value
      end

      # saving into the database using upsert
      Job.upsert(tempHash)
    }

    # returing reponse
    render json: data
  end
  
  def index
    posts = Job.all();
    render json: posts, status:200
  end

  def show
    job = Job.find_by(reference_number: params[:id])
    if job
      render json: job, status:200
    else
      render json: {
          error: "Job Not Found."
      } 
    end
  end

  def create
    render json: { error: "Inside create Action"}
  end

  def update
    job = Job.find_by(reference_number: params[:id])

    # check post is save or not
    if job
      job.update(title: params[:title], 
      # city: params[:city], state: params[:state], category_id: params[:category_id], 
      # company_id: params[:company_id], emp_type: params[:emp_type], experience: params[:experience], salary: params[:salary],
      # cpa: params[:cpa], verified: params[:verified], description: params[:description], skills: params[:skills], qualification: params[:qualification]
      )
      render json: job, status:200
    else
      render json: { error: "Job Not Found."} 
    end
  end

  def destroy
    job = Job.find_by(reference_number: params[:id])
    if job
      job.destroy
      render json:  { error: "Job has been deleted."} 
    else
      render json: { error: "Job Not Found."} 
    end
  end


  # This api will be used to collect the companies Listing
  def companiesList

    posts = Company.all();
    render json: posts, status:200
  end

  # This api will be used to collect the companies Details
  def companiesListById
    companyDetails = Company.find_by(id: params[:id])
    

    if companyDetails
      render json: companyDetails, status:200
    else
      render json: {
          error: "Company Not Found."
      } 
    end
  end

  # This api will be used to update the companies Details
  def updateCompanyById
    companyDetails = Company.find_by(id: params[:id])

    # check post is save or not
    if companyDetails
      companyDetails.update(name: params[:name],)
      render json: companyDetails, status:200
    else
      render json: { error: "Company Not Found."} 
    end
  end

  private
  def insertCategoryRecords()
    CATEGORIES
  end

  def insertCompanyRecords()
    CompaniesList
  end

  def getMinMaxValue(a, b)
    element = {
      [a] => ((rand() * 6)).floor(),
      [b] => ((rand() * 6) + 5).floor(),
    }
  end
end
