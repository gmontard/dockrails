module Dockrails
  class Generate

    def initialize(app_path:)
      check_system_requirements
      @app_path = app_path
      @config = ask_configuration
    end

    def check_system_requirements
      requirement = Hash.new
      requirement["unison"] = system("which unison > /dev/null")
      requirement["docker"] = system("which docker > /dev/null")
      requirement["docker-sync"] = system("which docker-sync > /dev/null")
      requirement["docker-compose"] = system("which docker-compose > /dev/null")

      requirement.each do |k,v|
        if v == false
          say "please install \"#{k}\" in order to continue\n"
        end
      end
    end

    def ask_configuration
      config = Hash.new
      config["ruby-version"] = choose("\nChoose a ruby version?", "latest", "2.4", "2.3", "2.2")
      config["db"] = choose("\nChoose a DB Engine?", :pgsql, :mysql)
      config["db_name"] = ask "\nChoose a database name"
      config["db_user"] = ask "\nChoose a database username"
      config["db_password"] = ask "\nChoose a database password"
      config["redis"] = agree("\nDo you need a Redis DB?")
      config["sidekiq"] = agree("\nDo you need a SideKiq Container") if config["redis"]

      user_agree = agree "\nSummary:
    - Ruby version: #{config["ruby-version"]}
    - DB Engine: #{config["db"]}
    - DB Name: #{config["db_name"]}
    - DB Username: #{config["db_user"]}
    - DB Password: #{config["db_password"]}
    - Redis? #{config["redis"]}
    - Job Container? #{config["sidekiq"] ||= "false"}\n
  Is this correct?"

      unless user_agree
        ask_configuration
      end

      return(config)
    end

    def create_folders
      system("rm -rf data")
      system("mkdir -p data/sql")
      system("mkdir -p data/redis") if @config["redis"]
    end

    def create_dockerfile
      File.open("Dockerfile", 'w') do |f|
        f.write("FROM ruby:#{@config["ruby-version"]}
  RUN apt-get update && apt-get install -y \
  build-essential \
  wget \
  git-core \
  libxml2 \
  libxml2-dev \
  libxslt1-dev \
  nodejs \
  imagemagick \
  libmagickcore-dev \
  libmagickwand-dev \
  libpq-dev \
  && rm -rf /var/lib/apt/lists/*

  RUN mkdir /app
  RUN mkdir -p /root/.ssh/

  WORKDIR /app

  RUN ssh-keyscan -H github.com >> ~/.ssh/known_hosts
  ENV GEM_HOME /bundle
  ENV PATH $GEM_HOME/bin:$PATH
  ENV BUNDLE_PATH /bundle
  ENV BUNDLE_BIN /bundle/
  RUN gem install bundler -v '1.10.6' \
  && bundle config --global path \"$GEM_HOME\" \
  && bundle config --global bin \"$GEM_HOME/bin\"")
      end
    end

    def create_start_script
      system("mkdir -p #{@app_path}/scripts")
      File.open("#{@app_path}/scripts/start-dev.sh", "w") do |f|
        f.write("#!/bin/bash
  bundle check || bundle install
  rm -rf tmp/pids/* && bundle exec rails server --port 3000 --binding 0.0.0.0")
      end
    end

    def create_docker_compose
      File.open("docker-compose.yml", 'w') do |f|
        f.write "version: '2'\n"
        f.write "services:\n"
        f.write " db:\n"

        case @config["db"] when :mysql
          f.write "   image: mysql\n"
          f.write "   volumes:\n"
          f.write "     - ./data/sql:/var/lib/mysql\n"
          f.write "   ports:\n"
          f.write "     - \"3306:3306\"\n"
          f.write "   environment:\n"
          f.write "     MYSQL_DATABASE: #{@config["db_name"]}\n"
          f.write "     MYSQL_USER: #{@config["db_user"]}\n"
          f.write "     MYSQL_PASSWORD: #{@config["db_password"]}\n"
          f.write "     MYSQL_ROOT_PASSWORD: #{@config["db_password"]}\n"
        when :pgsql
          f.write "   image: postgres\n"
          f.write "   volumes:\n"
          f.write "     - ./data/sql:/var/lib/postgresql/data\n"
          f.write "   ports:\n"
          f.write "     - \"5432:5432\"\n"
          f.write "   environment:\n"
          f.write "     POSTGRES_DB: #{@config["db_name"]}\n"
          f.write "     POSTGRES_USER: #{@config["db_user"]}\n"
          f.write "     POSTGRES_PASSWORD: #{@config["db_password"]}\n"
        end

        if @config["redis"]
          f.write "\n redis:\n"
          f.write "   image: redis\n"
          f.write "   volumes:\n"
          f.write "     - ./data/redis:/data\n"
          f.write "   ports:\n"
          f.write "     - \"6379:6379\"\n"
        end

        f.write "\n web:\n"
        f.write "   build: .\n"
        f.write "   command: sh scripts/start-dev.sh\n"
        f.write "   volumes:\n"
        f.write "     - #{@app_path}-web-sync:/app:rw\n"
        f.write "     - #{@app_path}-bundle-sync:/bundle:rw\n"
        f.write "     - ./keys:/root/.ssh/\n"
        f.write "   ports:\n"
        f.write "     - \"3000:3000\"\n"
        f.write "   environment:\n"
        f.write "     REDIS_URL: redis://redis:6379\n" if @config["redis"]
        f.write "     DB_USER: #{@config["db_user"]}\n"
        f.write "     DB_PASSWORD: #{@config["db_password"]}\n"
        f.write "   links:\n"
        f.write "     - db\n"
        f.write "     - redis\n" if @config["redis"]
        f.write "   tty: true\n"
        f.write "   stdin_open: true\n"

        if @config["redis"] && @config["sidekiq"]
          f.write "\n job:\n"
          f.write "   build: .\n"
          f.write "   command: bundle exec sidekiq -C config/sidekiq.yml\n"
          f.write "   volumes:\n"
          f.write "     - #{@app_path}-web-sync:/app:rw\n"
          f.write "     - #{@app_path}-bundle-sync:/bundle:rw\n"
          f.write "     - ./keys:/root/.ssh/\n"
          f.write "   environment:\n"
          f.write "     REDIS_URL: redis://redis:6379\n"
          f.write "   links:\n"
          f.write "     - db\n"
          f.write "     - redis\n"
        end

        f.write "\nvolumes:\n"
        f.write "  #{@app_path}-web-sync:\n"
        f.write "   external: true\n"
        f.write "  #{@app_path}-bundle-sync:\n"
        f.write "   external: true\n"
      end
    end

    def create_docker_sync
      File.open("docker-sync.yml", 'w') do |f|
        f.write "version: '2'\n"
        f.write "syncs:\n"
        f.write " #{@app_path}-web-sync:\n"
        f.write "   src: './#{@app_path}'\n"
        f.write "   dest: '/app'\n"
        f.write " #{@app_path}-bundle-sync:\n"
        f.write "   src: './bundle'\n"
        f.write "   dest: '/bundle'\n"
      end
    end
  end
end
