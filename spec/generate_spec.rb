require 'spec_helper'
require 'dockrails/generate'


class Dummy
  def command_line
    system("ls")
  end
end

describe Dockrails::Generate do

  before(:all) do
    #$stderr = StringIO.new
    #mock_terminal

    @app_path = "rails_app"
    @generate = Dockrails::Generate.new(app_path: @app_path)
  end

  describe ".check_system_requirements" do
    it "should test for Unison, docker, docker-compose and docker-sync binaries" do
      values = @generate.check_system_requirements.map{|k,v| k}
      expect(values).to eql ["unison", "docker", "docker-sync", "docker-compose"]
    end

    context "when all requirements are met" do
      it {
        allow(@generate).to receive(:binary_present?).with(binary: "unison") { true }
        allow(@generate).to receive(:binary_present?).with(binary: "docker") { true }
        allow(@generate).to receive(:binary_present?).with(binary: "docker-sync") { true }
        allow(@generate).to receive(:binary_present?).with(binary: "docker-compose") { true }

        expect(@generate.check_system_requirements).to be_kind_of Hash
      }
    end

    context "when NOT all requirements are met" do
      it {
        allow(@generate).to receive(:binary_present?).with(binary: "unison") { false }
        allow(@generate).to receive(:binary_present?).with(binary: "docker") { true }
        allow(@generate).to receive(:binary_present?).with(binary: "docker-sync") { true }
        allow(@generate).to receive(:binary_present?).with(binary: "docker-compose") { true }

        expect(@generate.check_system_requirements).to be_kind_of Hash
      }
    end
  end

  describe ".configure" do
  end

  context "once it's configured" do

    before(:all) do
      @app_path = "rails_app"

      @config_with_redis = {
        ruby: "latest",
        db: :pgsql,
        db_name: "rails",
        db_user: "rails",
        db_password: "rails",
        redis: true,
        sidekiq: true
      }

      @config_without_redis = {
        ruby: "latest",
        db: :pgsql,
        db_name: "rails",
        db_user: "rails",
        db_password: "rails",
        redis: false,
        sidekiq: false
      }

      @config_with_mysql = {
        ruby: "latest",
        db: :mysql,
        db_name: "rails",
        db_user: "rails",
        db_password: "rails",
        redis: false,
        sidekiq: false
      }

      @generate_with_redis = Dockrails::Generate.new(app_path: @app_path, config: @config_with_redis)
      @generate_without_redis = Dockrails::Generate.new(app_path: @app_path, config: @config_without_redis)
      @generate_with_mysql = Dockrails::Generate.new(app_path: @app_path, config: @config_with_mysql)
    end

    describe ".create_folders" do
      context "When Redis is not set" do
        it "should create the data and data/sql folders" do
          allow(FileUtils).to receive(:mkdir_p).with("data")
          allow(FileUtils).to receive(:mkdir_p).with("data/sql")
          @generate_without_redis.create_folders
        end
      end

      context "When Redis is set" do
        it "should create the data, data/sql and data/redis folders" do
          allow(FileUtils).to receive(:mkdir_p).with("data")
          allow(FileUtils).to receive(:mkdir_p).with("data/sql")
          allow(FileUtils).to receive(:mkdir_p).with("data/redis")
          @generate_with_redis.create_folders
        end
      end
    end

    describe ".create_dockerfile" do
      it "Should create a Dockerfile" do
        allow(File).to receive(:open).with("Dockerfile", 'w').once
        @generate_with_redis.create_dockerfile
      end
    end

    describe ".create_docker_compose" do
      it "Should create a docker-compose.yml file" do
        allow(File).to receive(:open).with("docker-compose.yml", 'w').once
        @generate_with_redis.create_docker_compose
      end

      context "When PGSQL is set" do
        it "Should contain the Pgsql config" do
          @generate_with_redis.create_docker_compose
          expect(File.read("docker-compose.yml")).to match /postgres/i
        end
      end

      context "When MySQL is set" do
        it "Should contain the Mysql config" do
          @generate_with_mysql.create_docker_compose
          expect(File.read("docker-compose.yml")).to match /mysql/i
        end
      end

      context "When Redis is not set" do
        it "Should not contain a Redis node" do
          @generate_without_redis.create_docker_compose
          expect(File.read("docker-compose.yml")).not_to match /redis/i
        end

        it "Should not contain a Sidekiq node" do
          @generate_without_redis.create_docker_compose
          expect(File.read("docker-compose.yml")).not_to match /sidekiq/i
        end
      end

      context "When Redis & Sidekiq are set" do
        it "Should contain a Redis node" do
          @generate_with_redis.create_docker_compose
          expect(File.read("docker-compose.yml")).to match /redis/i
        end

        it "Should contain a Sidekiq node" do
          @generate_with_redis.create_docker_compose
          expect(File.read("docker-compose.yml")).to match /sidekiq/i
        end
      end
    end

    describe ".create_docker_sync" do
      it "Should create a docker-sync.yml file" do
        allow(File).to receive(:open).with("docker-sync.yml", 'w').once
        @generate_with_redis.create_docker_sync
      end
    end

    describe ".create_start_script" do
      it "Should create a scripts folder and start-dev.sh file" do
        allow(File).to receive(:open).with("#{@app_path}/scripts/start-dev.sh", 'w').once
        allow(FileUtils).to receive(:mkdir_p).with("#{@app_path}/scripts").once
        @generate_with_redis.create_start_script
      end
    end
  end

end
