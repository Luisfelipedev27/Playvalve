namespace :redis do
  desc "Setup country whitelist in Redis"
  task setup_country_whitelist: :environment do
    countries = %w[
      US BR CA
      GB DE FR IT ES
      AU JP SG KR
    ]

    puts "Setting up country whitelist in Redis..."
    puts "Criteria: Main markets + favorable regulation + low fraud risk"

    Rails.cache.redis.with do |redis|
      redis.del('country_whitelist')

      redis.sadd('country_whitelist', countries)

      puts "Added #{countries.size} countries to whitelist:"
      puts "Americas: US, BR, CA"
      puts "Europe: GB, DE, FR, IT, ES"
      puts "Asia-Pacific: AU, JP, SG, KR"
      puts "\nCurrent whitelist: #{redis.smembers('country_whitelist').sort.join(', ')}"
    end
  end

  desc "Show current country whitelist"
  task show_country_whitelist: :environment do
    Rails.cache.redis.with do |redis|
      countries = redis.smembers('country_whitelist')

      if countries.any?
        puts "Current country whitelist (#{countries.size} countries):"
        puts countries.sort.join(', ')
      else
        puts "No countries in whitelist. Run 'rake redis:setup_country_whitelist' to set it up."
      end
    end
  end

  desc "Add country to whitelist"
  task :add_country, [:country_code] => :environment do |task, args|
    country_code = args[:country_code]&.upcase

    if country_code.blank?
      puts "Usage: rake redis:add_country[US]"
      exit 1
    end

    Rails.cache.redis.with do |redis|
      if redis.sadd('country_whitelist', country_code)
        puts "Added #{country_code} to country whitelist"
      else
        puts "#{country_code} is already in the whitelist"
      end

      puts "Current whitelist: #{redis.smembers('country_whitelist').sort.join(', ')}"
    end
  end

  desc "Remove country from whitelist"
  task :remove_country, [:country_code] => :environment do |task, args|
    country_code = args[:country_code]&.upcase

    if country_code.blank?
      puts "Usage: rake redis:remove_country[US]"
      exit 1
    end

    Rails.cache.redis.with do |redis|
      if redis.srem('country_whitelist', country_code)
        puts "Removed #{country_code} from country whitelist"
      else
        puts "#{country_code} was not in the whitelist"
      end

      puts "Current whitelist: #{redis.smembers('country_whitelist').sort.join(', ')}"
    end
  end
end
